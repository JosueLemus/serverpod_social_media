#!/usr/bin/env bash
# Despliega el backend de Nexo en la VM de AWS (SDD 0009): la imagen del
# servidor, Postgres y Caddy con HTTPS de sslip.io, en /opt/nexo.
#
#   tool/aws/deploy.sh <ip>          servidor (imagen, compose, Caddy, backups)
#   tool/aws/deploy.sh <ip> --web    además, la app web de Flutter
#
# La VM la crea `tool/aws/provision.sh`: Ubuntu con Docker, el usuario en el
# grupo `docker` y /opt/nexo de su propiedad.
#
# Variables opcionales:
#   NEXO_SSH_KEY     clave privada (default ~/.ssh/nexo-aws.pem)
#   NEXO_SSH_USER    usuario SSH (default ubuntu)
#   SMTP_HOST SMTP_PORT SMTP_USER SMTP_PASSWORD SMTP_FROM SMTP_FROM_NAME
#                    email de los códigos de verificación (Gmail o Brevo).
#                    Sin ellos, el código va al log del servidor.
#
# Secretos: el primer deploy genera /opt/nexo/.env EN LA VM con valores
# aleatorios nuevos. Los de Agora salen de
# services/serverpod/nexo_server/config/passwords.yaml y viajan por la
# entrada estándar de ssh: nunca en la línea de comandos ni en un archivo
# local. Los siguientes deploys conservan los generados (rotar la contraseña
# de la base la dejaría inaccesible) y actualizan Agora y SMTP.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SERVERPOD="$ROOT/services/serverpod"
DEPLOY="$SERVERPOD/deploy/aws"
APP="$ROOT/apps/nexo_social"
PASSWORDS="$SERVERPOD/nexo_server/config/passwords.yaml"
REMOTE_DIR=/opt/nexo
DEMO_PASSWORD="nexo-demo-2026"

say() { printf '\n\033[1;34m▸ %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

target_host=""
with_web=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --web) with_web=true; shift ;;
    -h|--help) sed -n '2,25p' "$0"; exit 0 ;;
    -*) fail "Opción desconocida: $1 (ver --help)" ;;
    *) target_host="$1"; shift ;;
  esac
done
[[ -n "$target_host" ]] || fail "Falta la IP de la VM: tool/aws/deploy.sh <ip> [--web]"

# Una IP se vuelve un nombre de sslip.io (3.80.12.5 → 3-80-12-5.sslip.io);
# un nombre se usa tal cual.
if [[ "$target_host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  nexo_host="${target_host//./-}.sslip.io"
else
  nexo_host="$target_host"
fi
api_host="api.$nexo_host"

ssh_key="${NEXO_SSH_KEY:-$HOME/.ssh/nexo-aws.pem}"
ssh_user="${NEXO_SSH_USER:-ubuntu}"
[[ -f "$ssh_key" ]] || fail "No existe la clave SSH $ssh_key (NEXO_SSH_KEY)."
for tool in docker ssh scp curl; do
  command -v "$tool" >/dev/null || fail "Falta $tool."
done

ssh_opts=(-i "$ssh_key" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15)
remote() { ssh "${ssh_opts[@]}" "$ssh_user@$target_host" "$@"; }

say "Probando la conexión con $ssh_user@$target_host"
remote 'docker info >/dev/null' \
  || fail "La VM no responde por SSH o Docker no está listo (¿corrió provision.sh?)."

# --- Imagen ---------------------------------------------------------------------
# Se compila acá: Dart AOT en una VM de 1 GB se queda sin memoria. Apple
# Silicon compila linux/arm64 en nativo, igual que la t4g.
say "Construyendo la imagen del servidor (linux/arm64)"
docker build --platform linux/arm64 -f "$SERVERPOD/nexo_server/Dockerfile" \
  -t nexo-server:latest "$SERVERPOD"

say "Copiando la imagen a la VM"
docker save nexo-server:latest | gzip | remote 'gunzip | docker load'

# --- Archivos -------------------------------------------------------------------
say "Subiendo compose.yaml, Caddyfile y backup.sh a $REMOTE_DIR"
remote "mkdir -p $REMOTE_DIR/web $REMOTE_DIR/backups"
scp "${ssh_opts[@]}" "$DEPLOY/compose.yaml" "$DEPLOY/Caddyfile" \
  "$DEPLOY/backup.sh" "$ssh_user@$target_host:$REMOTE_DIR/"
remote "chmod +x $REMOTE_DIR/backup.sh"

# --- Secretos -------------------------------------------------------------------
# Lo que sale de esta máquina (Agora y SMTP) se arma con printf, que es un
# builtin: no aparece en `ps`. Llega a la VM por stdin.
yaml_value() {
  [[ -f "$PASSWORDS" ]] || return 0
  awk -v key="$1" '$1 == key":" { v = $2; gsub(/^["'\'']|["'\'']$/, "", v); print v; exit }' "$PASSWORDS"
}
local_secrets() {
  local agora_id agora_cert
  agora_id="$(yaml_value agoraAppId)"
  agora_cert="$(yaml_value agoraAppCertificate)"
  [[ -n "$agora_id" ]] && printf 'SERVERPOD_PASSWORD_agoraAppId=%s\n' "$agora_id"
  [[ -n "$agora_cert" ]] && printf 'SERVERPOD_PASSWORD_agoraAppCertificate=%s\n' "$agora_cert"
  [[ -n "${SMTP_HOST:-}" ]] && printf 'SERVERPOD_PASSWORD_smtpHost=%s\n' "$SMTP_HOST"
  [[ -n "${SMTP_PORT:-}" ]] && printf 'SERVERPOD_PASSWORD_smtpPort=%s\n' "$SMTP_PORT"
  [[ -n "${SMTP_USER:-}" ]] && printf 'SERVERPOD_PASSWORD_smtpUser=%s\n' "$SMTP_USER"
  [[ -n "${SMTP_PASSWORD:-}" ]] && printf 'SERVERPOD_PASSWORD_smtpPassword=%s\n' "$SMTP_PASSWORD"
  [[ -n "${SMTP_FROM:-}" ]] && printf 'SERVERPOD_PASSWORD_smtpFrom=%s\n' "$SMTP_FROM"
  [[ -n "${SMTP_FROM_NAME:-}" ]] && printf 'SERVERPOD_PASSWORD_smtpFromName=%s\n' "$SMTP_FROM_NAME"
  return 0
}

say "Preparando los secretos en la VM"
[[ -n "$(yaml_value agoraAppCertificate)" ]] \
  || echo "  Sin agoraAppCertificate local: el video queda en modo de prueba de Agora."
[[ -n "${SMTP_HOST:-}" ]] \
  || echo "  Sin SMTP_HOST: los códigos de verificación van al log del servidor."
local_secrets | remote "umask 077 && cat > $REMOTE_DIR/.env.incoming"

remote "NEXO_HOST='$nexo_host' API_HOST='$api_host' bash -s" <<'REMOTE'
set -euo pipefail
cd /opt/nexo
umask 077
if [[ ! -f .env ]]; then
  echo "  Primer deploy: generando secretos nuevos en /opt/nexo/.env"
  db="$(openssl rand -hex 24)"
  {
    echo "POSTGRES_PASSWORD=$db"
    echo "SERVERPOD_PASSWORD_database=$db"
    echo "SERVERPOD_PASSWORD_serviceSecret=$(openssl rand -hex 32)"
    echo "SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey=$(openssl rand -hex 64)"
    echo "SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper=$(openssl rand -hex 32)"
    echo "SERVERPOD_PASSWORD_emailSecretHashPepper=$(openssl rand -hex 32)"
  } > .env
fi
# Lo que llegó de la máquina de desarrollo y los hosts reemplazan sus claves;
# los secretos generados no se tocan.
printf 'NEXO_HOST=%s\nSERVERPOD_API_SERVER_PUBLIC_HOST=%s\n' "$NEXO_HOST" "$API_HOST" >> .env.incoming
awk -F= 'NR == FNR { incoming[$1] = $0; next }
         !($1 in incoming) { print }
         END { for (k in incoming) print incoming[k] }' .env.incoming .env > .env.next
mv .env.next .env
rm -f .env.incoming
chmod 600 .env
REMOTE

# --- Levantar -------------------------------------------------------------------
say "Levantando Postgres, el servidor y Caddy"
remote "cd $REMOTE_DIR && docker compose up -d --remove-orphans && docker image prune -f >/dev/null"

remote "(crontab -l 2>/dev/null | grep -q 'nexo/backup.sh') || \
  (crontab -l 2>/dev/null; echo '15 4 * * * $REMOTE_DIR/backup.sh >> $REMOTE_DIR/backups/backup.log 2>&1') | crontab -"

# Caddy saca el certificado la primera vez: puede tardar un par de minutos.
say "Esperando a https://$api_host/ (el primer certificado tarda un poco)"
for _ in $(seq 1 60); do
  if curl -fsS -o /dev/null "https://$api_host/"; then break; fi
  sleep 5
done
curl -fsS -o /dev/null "https://$api_host/" || {
  remote "cd $REMOTE_DIR && docker compose ps && docker compose logs --tail 40 server caddy" >&2
  fail "La API no respondió por HTTPS en 5 minutos (logs arriba)."
}
echo "  API lista: https://$api_host/"

# --- Web ------------------------------------------------------------------------
if $with_web; then
  command -v flutter >/dev/null || fail "Falta Flutter para construir la web."
  say "Construyendo la app web contra https://$api_host/"
  (cd "$APP" && flutter build web --release \
    --dart-define=AUTH_SOURCE=serverpod \
    --dart-define=API_BASE_URL="https://$api_host/" \
    --dart-define=DEMO_PASSWORD="$DEMO_PASSWORD" \
    --dart-define=SHARE_BASE_URL="https://$nexo_host")
  say "Copiando la web a $REMOTE_DIR/web"
  # Se vacía el directorio en vez de reemplazarlo: Caddy lo tiene montado, y
  # un directorio nuevo con el mismo nombre no le llega al contenedor.
  # Sin los atributos extendidos de macOS: el tar de Linux los rechaza con un
  # aviso por archivo.
  COPYFILE_DISABLE=1 tar --no-xattrs -C "$APP/build/web" -czf - . \
    | remote "find $REMOTE_DIR/web -mindepth 1 -delete && tar -xzf - -C $REMOTE_DIR/web"
  echo "  Web lista: https://$nexo_host/"
fi

say "Deploy listo"
echo "  API:  https://$api_host/"
$with_web && echo "  Web:  https://$nexo_host/"
echo "  Logs: ssh -i $ssh_key $ssh_user@$target_host 'cd $REMOTE_DIR && docker compose logs -f server'"
