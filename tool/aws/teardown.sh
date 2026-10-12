#!/usr/bin/env bash
# Apaga y borra la infraestructura de Nexo en AWS, para que deje de cobrarse.
# Una Elastic IP sin máquina también se cobra, así que se libera.
#
#   tool/aws/teardown.sh            # pide confirmación
#   tool/aws/teardown.sh --yes
#
# No borra la alerta de presupuesto ni la clave SSH local.
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
NAME="nexo"
aws_() { aws --region "$REGION" --output text "$@"; }
say() { printf '\n\033[1;34m▸ %s\033[0m\n' "$*"; }

if [[ "${1:-}" != "--yes" ]]; then
  read -r -p "Esto borra la máquina de Nexo, su disco y la base de datos. ¿Seguro? (escribí 'borrar'): " answer
  [[ "$answer" == "borrar" ]] || { echo "Cancelado."; exit 1; }
fi

INSTANCE_ID="$(aws_ ec2 describe-instances \
  --filters Name=tag:Name,Values="$NAME" Name=instance-state-name,Values=pending,running,stopping,stopped \
  --query 'Reservations[0].Instances[0].InstanceId')"
if [[ "$INSTANCE_ID" != "None" ]]; then
  say "Terminando la máquina $INSTANCE_ID"
  aws_ ec2 terminate-instances --instance-ids "$INSTANCE_ID" >/dev/null
  aws_ ec2 wait instance-terminated --instance-ids "$INSTANCE_ID"
fi

ALLOC_ID="$(aws_ ec2 describe-addresses --filters Name=tag:Name,Values="$NAME" \
  --query 'Addresses[0].AllocationId')"
if [[ "$ALLOC_ID" != "None" ]]; then
  say "Liberando la IP fija"
  aws_ ec2 release-address --allocation-id "$ALLOC_ID"
fi

SG_ID="$(aws_ ec2 describe-security-groups --filters Name=group-name,Values="$NAME" \
  --query 'SecurityGroups[0].GroupId')"
if [[ "$SG_ID" != "None" ]]; then
  say "Borrando el security group"
  aws_ ec2 delete-security-group --group-id "$SG_ID"
fi

aws_ ec2 delete-key-pair --key-name nexo-aws >/dev/null 2>&1 || true
say "Listo: no queda nada de Nexo corriendo en $REGION"
