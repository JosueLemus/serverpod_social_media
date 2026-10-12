#!/usr/bin/env bash
# Crea (o reutiliza) la infraestructura de Nexo en AWS: una sola VM con todo
# adentro. Ver docs/sdd/0009-deploy-del-backend.md.
#
#   BUDGET_EMAIL=vos@ejemplo.com tool/aws/provision.sh
#
# Es idempotente: identifica cada recurso por la etiqueta Name=nexo, así que
# correrlo dos veces no crea dos máquinas.
#
# Variables opcionales:
#   AWS_REGION      us-east-1 por defecto
#   INSTANCE_TYPE   t4g.micro por defecto (ARM, 1 GB). t4g.small si falta RAM
#   BUDGET_EMAIL    a quién avisa la alerta de 10 USD/mes (se crea una sola vez)
#   KEY_PATH        clave SSH; por defecto ~/.ssh/nexo-aws.pem
set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
NAME="nexo"
INSTANCE_TYPE="${INSTANCE_TYPE:-t4g.micro}"
KEY_NAME="nexo-aws"
KEY_PATH="${KEY_PATH:-$HOME/.ssh/nexo-aws.pem}"
DISK_GB=10
BUDGET_USD=10

say() { printf '\n\033[1;34m▸ %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
aws_() { aws --region "$REGION" --output text "$@"; }

command -v aws >/dev/null || fail "Falta la CLI de AWS (brew install awscli)."
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)" \
  || fail "La CLI de AWS no tiene credenciales (aws configure)."
say "Cuenta $ACCOUNT, región $REGION"

# --- Presupuesto --------------------------------------------------------------
# Antes que cualquier recurso: si algo queda prendido, que avise.
if aws budgets describe-budget --account-id "$ACCOUNT" --budget-name "$NAME" \
  >/dev/null 2>&1; then
  say "La alerta de presupuesto ya existe"
elif [[ -n "${BUDGET_EMAIL:-}" ]]; then
  say "Creando la alerta de presupuesto ($BUDGET_USD USD/mes → $BUDGET_EMAIL)"
  aws budgets create-budget --account-id "$ACCOUNT" \
    --budget "{\"BudgetName\":\"$NAME\",\"BudgetLimit\":{\"Amount\":\"$BUDGET_USD\",\"Unit\":\"USD\"},\"TimeUnit\":\"MONTHLY\",\"BudgetType\":\"COST\"}" \
    --notifications-with-subscribers "[
      {\"Notification\":{\"NotificationType\":\"ACTUAL\",\"ComparisonOperator\":\"GREATER_THAN\",\"Threshold\":80,\"ThresholdType\":\"PERCENTAGE\"},
       \"Subscribers\":[{\"SubscriptionType\":\"EMAIL\",\"Address\":\"$BUDGET_EMAIL\"}]},
      {\"Notification\":{\"NotificationType\":\"FORECASTED\",\"ComparisonOperator\":\"GREATER_THAN\",\"Threshold\":100,\"ThresholdType\":\"PERCENTAGE\"},
       \"Subscribers\":[{\"SubscriptionType\":\"EMAIL\",\"Address\":\"$BUDGET_EMAIL\"}]}]"
else
  fail "Falta BUDGET_EMAIL: la alerta de presupuesto va antes que la máquina."
fi

# --- Clave SSH ----------------------------------------------------------------
if aws_ ec2 describe-key-pairs --key-names "$KEY_NAME" >/dev/null 2>&1; then
  [[ -f "$KEY_PATH" ]] || fail "La clave $KEY_NAME existe en AWS pero no en $KEY_PATH."
  say "Clave SSH $KEY_NAME ya existe"
else
  say "Creando la clave SSH en $KEY_PATH"
  mkdir -p "$(dirname "$KEY_PATH")"
  ( umask 077; aws_ ec2 create-key-pair --key-name "$KEY_NAME" --key-type ed25519 \
      --tag-specifications "ResourceType=key-pair,Tags=[{Key=Name,Value=$NAME}]" \
      --query KeyMaterial > "$KEY_PATH" )
  chmod 400 "$KEY_PATH"
fi

# --- Red ----------------------------------------------------------------------
VPC_ID="$(aws_ ec2 describe-vpcs --filters Name=is-default,Values=true --query 'Vpcs[0].VpcId')"
[[ "$VPC_ID" != "None" ]] || fail "La región no tiene VPC por defecto."
MY_IP="$(curl -fsS https://checkip.amazonaws.com | tr -d '[:space:]')"

SG_ID="$(aws_ ec2 describe-security-groups \
  --filters Name=group-name,Values="$NAME" Name=vpc-id,Values="$VPC_ID" \
  --query 'SecurityGroups[0].GroupId')"
if [[ "$SG_ID" == "None" ]]; then
  say "Creando el security group (80 y 443 abiertos; 22 sólo desde $MY_IP)"
  SG_ID="$(aws_ ec2 create-security-group --group-name "$NAME" --vpc-id "$VPC_ID" \
    --description "Nexo: HTTPS publico, SSH solo desde quien despliega" \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=$NAME}]" \
    --query GroupId)"
  aws_ ec2 authorize-security-group-ingress --group-id "$SG_ID" --ip-permissions \
    "IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}],Ipv6Ranges=[{CidrIpv6=::/0}]" \
    "IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges=[{CidrIp=0.0.0.0/0}],Ipv6Ranges=[{CidrIpv6=::/0}]" \
    >/dev/null
fi
# El SSH sigue a la IP de quien despliega: si cambió, se agrega la nueva.
aws_ ec2 authorize-security-group-ingress --group-id "$SG_ID" \
  --protocol tcp --port 22 --cidr "$MY_IP/32" >/dev/null 2>&1 || true

# --- Máquina ------------------------------------------------------------------
INSTANCE_ID="$(aws_ ec2 describe-instances \
  --filters Name=tag:Name,Values="$NAME" Name=instance-state-name,Values=pending,running,stopping,stopped \
  --query 'Reservations[0].Instances[0].InstanceId')"
if [[ "$INSTANCE_ID" == "None" ]]; then
  AMI="$(aws_ ssm get-parameter \
    --name /aws/service/canonical/ubuntu/server/24.04/stable/current/arm64/hvm/ebs-gp3/ami-id \
    --query Parameter.Value)"
  say "Creando la máquina ($INSTANCE_TYPE, Ubuntu 24.04 ARM, $DISK_GB GB)"
  USER_DATA="$(cat <<'CLOUD'
#!/bin/bash
set -eux
# 2 GB de swap: 1 GB de RAM no alcanza para un pico con Postgres y el server.
fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
sysctl -w vm.swappiness=10 && echo 'vm.swappiness=10' > /etc/sysctl.d/99-nexo.conf
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin unattended-upgrades
usermod -aG docker ubuntu
mkdir -p /opt/nexo/web /opt/nexo/backups && chown -R ubuntu:ubuntu /opt/nexo
touch /var/lib/cloud/instance/nexo-ready
CLOUD
)"
  INSTANCE_ID="$(aws_ ec2 run-instances --image-id "$AMI" --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" --security-group-ids "$SG_ID" \
    --block-device-mappings "DeviceName=/dev/sda1,Ebs={VolumeSize=$DISK_GB,VolumeType=gp3,DeleteOnTermination=true}" \
    --metadata-options HttpTokens=required,HttpEndpoint=enabled \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$NAME}]" "ResourceType=volume,Tags=[{Key=Name,Value=$NAME}]" \
    --user-data "$USER_DATA" --query 'Instances[0].InstanceId')"
else
  say "La máquina ya existe ($INSTANCE_ID)"
  aws_ ec2 start-instances --instance-ids "$INSTANCE_ID" >/dev/null 2>&1 || true
fi
aws_ ec2 wait instance-running --instance-ids "$INSTANCE_ID"

# --- IP fija ------------------------------------------------------------------
# Una Elastic IP: sslip.io deriva el dominio de la IP, y una IP que cambia al
# reiniciar dejaría el APK y el certificado apuntando a ningún lado.
ALLOC_ID="$(aws_ ec2 describe-addresses --filters Name=tag:Name,Values="$NAME" \
  --query 'Addresses[0].AllocationId')"
if [[ "$ALLOC_ID" == "None" ]]; then
  say "Reservando la IP fija"
  ALLOC_ID="$(aws_ ec2 allocate-address --domain vpc \
    --tag-specifications "ResourceType=elastic-ip,Tags=[{Key=Name,Value=$NAME}]" \
    --query AllocationId)"
fi
aws_ ec2 associate-address --instance-id "$INSTANCE_ID" --allocation-id "$ALLOC_ID" \
  --allow-reassociation >/dev/null
IP="$(aws_ ec2 describe-addresses --allocation-ids "$ALLOC_ID" --query 'Addresses[0].PublicIp')"
HOST="${IP//./-}.sslip.io"

# --- Esperar a que Docker esté instalado --------------------------------------
say "Esperando a que la máquina termine de instalar Docker"
for _ in $(seq 1 60); do
  if ssh -i "$KEY_PATH" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 \
    "ubuntu@$IP" 'test -f /var/lib/cloud/instance/nexo-ready' 2>/dev/null; then
    break
  fi
  sleep 10
done
ssh -i "$KEY_PATH" "ubuntu@$IP" 'docker --version && docker compose version && free -h | head -2' \
  || fail "La máquina no terminó de prepararse (mirá /var/log/cloud-init-output.log)."

say "Listo"
echo "  Máquina:  $INSTANCE_ID ($INSTANCE_TYPE)"
echo "  IP fija:  $IP"
echo "  Host:     $HOST  (API: api.$HOST)"
echo "  SSH:      ssh -i $KEY_PATH ubuntu@$IP"
echo "  Deploy:   tool/aws/deploy.sh $IP --web"
