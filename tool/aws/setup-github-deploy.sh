#!/usr/bin/env bash
# Conecta GitHub Actions con la VM de AWS para el deploy automático de main
# (.github/workflows/deploy.yml). Se corre una vez, desde la máquina que tiene
# las credenciales de AWS y la clave SSH, después de provision.sh y del primer
# deploy.sh. Es idempotente.
#
#   tool/aws/setup-github-deploy.sh
#
# Qué hace:
# - En AWS: el rol `nexo-github-deploy`, asumible sólo por los workflows de
#   la rama main de este repo (OIDC). Su único permiso es abrir y cerrar
#   reglas de entrada del security group de Nexo. GitHub no guarda ninguna
#   clave de AWS.
# - En GitHub: las variables (región, rol, IP, security group) y los
#   secretos (clave SSH, huella del servidor, secretos del servidor, Agora y,
#   si están en el entorno, SMTP). Ningún valor se imprime.
#
# Los secretos del servidor salen del /opt/nexo/.env de la VM: desde acá,
# GitHub Secrets es la fuente de verdad y cada deploy los vuelve a escribir.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGION="${AWS_REGION:-us-east-1}"
NAME="nexo"
ROLE="nexo-github-deploy"
KEY_PATH="${KEY_PATH:-$HOME/.ssh/nexo-aws.pem}"
PASSWORDS="$ROOT/services/serverpod/nexo_server/config/passwords.yaml"

say() { printf '\n\033[1;34m▸ %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
aws_() { aws --region "$REGION" --output text "$@"; }

for tool in aws gh ssh ssh-keyscan; do
  command -v "$tool" >/dev/null || fail "Falta $tool."
done
REPO="$(cd "$ROOT" && gh repo view --json nameWithOwner --jq .nameWithOwner)"
ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
say "Repo $REPO, cuenta de AWS $ACCOUNT"

SG_ID="$(aws_ ec2 describe-security-groups --filters Name=group-name,Values="$NAME" \
  --query 'SecurityGroups[0].GroupId')"
IP="$(aws_ ec2 describe-addresses --filters Name=tag:Name,Values="$NAME" \
  --query 'Addresses[0].PublicIp')"
[[ "$SG_ID" != "None" && "$IP" != "None" ]] || fail "No hay VM de Nexo: corré provision.sh primero."

# --- Rol de AWS para GitHub (OIDC) --------------------------------------------
OIDC="arn:aws:iam::$ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
if ! aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC" >/dev/null 2>&1; then
  say "Registrando GitHub como proveedor OIDC en la cuenta"
  aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com >/dev/null
fi

trust="$(cat <<JSON
{"Version":"2012-10-17","Statement":[{"Effect":"Allow",
 "Principal":{"Federated":"$OIDC"},"Action":"sts:AssumeRoleWithWebIdentity",
 "Condition":{"StringEquals":{"token.actions.githubusercontent.com:aud":"sts.amazonaws.com",
   "token.actions.githubusercontent.com:sub":"repo:$REPO:ref:refs/heads/main"}}}]}
JSON
)"
policy="$(cat <<JSON
{"Version":"2012-10-17","Statement":[
 {"Effect":"Allow","Action":["ec2:AuthorizeSecurityGroupIngress","ec2:RevokeSecurityGroupIngress"],
  "Resource":"arn:aws:ec2:$REGION:$ACCOUNT:security-group/$SG_ID"},
 {"Effect":"Allow","Action":"ec2:DescribeSecurityGroups","Resource":"*"}]}
JSON
)"
if aws iam get-role --role-name "$ROLE" >/dev/null 2>&1; then
  say "Actualizando el rol $ROLE"
  aws iam update-assume-role-policy --role-name "$ROLE" --policy-document "$trust"
else
  say "Creando el rol $ROLE (sólo main de $REPO; sólo el SSH del security group)"
  aws iam create-role --role-name "$ROLE" --assume-role-policy-document "$trust" \
    --description "GitHub Actions de $REPO: abrir y cerrar el SSH de Nexo durante el deploy" \
    --max-session-duration 3600 >/dev/null
fi
aws iam put-role-policy --role-name "$ROLE" --policy-name nexo-deploy-ssh --policy-document "$policy"
ROLE_ARN="$(aws iam get-role --role-name "$ROLE" --query Role.Arn --output text)"

# --- Variables (no secretas) --------------------------------------------------
say "Variables de GitHub"
gh variable set AWS_REGION --repo "$REPO" --body "$REGION"
gh variable set AWS_DEPLOY_ROLE_ARN --repo "$REPO" --body "$ROLE_ARN"
gh variable set NEXO_VM_IP --repo "$REPO" --body "$IP"
gh variable set NEXO_SG_ID --repo "$REPO" --body "$SG_ID"

# --- Secretos -----------------------------------------------------------------
# Todos por stdin: ni en la línea de comandos (se ve en `ps`) ni en pantalla.
secret() { gh secret set "$1" --repo "$REPO" >/dev/null && echo "  $1"; }

say "Secretos de GitHub"
[[ -f "$KEY_PATH" ]] || fail "No existe la clave SSH $KEY_PATH."
secret NEXO_SSH_PRIVATE_KEY < "$KEY_PATH"

# La huella se toma de la conexión y se compara con la que ya se aceptó al
# provisionar: si no coinciden, alguien se metió en el medio.
scanned="$(ssh-keyscan -t ed25519 "$IP" 2>/dev/null | grep -v '^#')"
# known_hosts puede guardar varias claves del mismo host (ed25519, rsa,
# ecdsa): se compara la del mismo tipo que se escaneó.
known="$(ssh-keygen -F "$IP" 2>/dev/null | awk '$2 == "ssh-ed25519" {print $3; exit}')"
[[ -n "$scanned" ]] || fail "No se pudo leer la huella SSH de $IP."
[[ "$(awk '{print $3}' <<<"$scanned")" == "$known" ]] \
  || fail "La huella SSH de $IP no coincide con la de ~/.ssh/known_hosts."
printf '%s\n' "$scanned" | secret NEXO_SSH_KNOWN_HOSTS

# Los secretos del servidor, tal cual están en la VM: la base ya fue creada
# con esa contraseña, y unos nuevos la dejarían inaccesible.
env_value() { awk -F= -v key="$1" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' <<<"$vm_env"; }
vm_env="$(ssh -i "$KEY_PATH" -o ConnectTimeout=15 "ubuntu@$IP" 'cat /opt/nexo/.env')"
for pair in NEXO_DB_PASSWORD:SERVERPOD_PASSWORD_database \
  NEXO_SERVICE_SECRET:SERVERPOD_PASSWORD_serviceSecret \
  NEXO_JWT_PRIVATE_KEY:SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey \
  NEXO_JWT_REFRESH_PEPPER:SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper \
  NEXO_EMAIL_PEPPER:SERVERPOD_PASSWORD_emailSecretHashPepper; do
  value="$(env_value "${pair#*:}")"
  [[ -n "$value" ]] || fail "La VM no tiene ${pair#*:} en /opt/nexo/.env."
  printf '%s' "$value" | secret "${pair%%:*}"
done
unset vm_env value

yaml_value() {
  [[ -f "$PASSWORDS" ]] || return 0
  awk -v key="$1" '$1 == key":" { v = $2; gsub(/^["'\'']|["'\'']$/, "", v); print v; exit }' "$PASSWORDS"
}
agora_id="${AGORA_APP_ID:-$(yaml_value agoraAppId)}"
agora_cert="${AGORA_APP_CERTIFICATE:-$(yaml_value agoraAppCertificate)}"
[[ -n "$agora_id" ]] && printf '%s' "$agora_id" | secret AGORA_APP_ID
[[ -n "$agora_cert" ]] && printf '%s' "$agora_cert" | secret AGORA_APP_CERTIFICATE
unset agora_id agora_cert

for name in SMTP_HOST SMTP_PORT SMTP_USER SMTP_PASSWORD SMTP_FROM; do
  [[ -n "${!name:-}" ]] && printf '%s' "${!name}" | secret "$name"
done
[[ -n "${SMTP_HOST:-}" ]] || echo "  (sin SMTP: los códigos de verificación siguen yendo al log)"

say "Listo: cada push a main de $REPO se verifica y se despliega en $IP"
