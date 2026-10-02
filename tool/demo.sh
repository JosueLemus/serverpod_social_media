#!/usr/bin/env bash
# Demo local de Nexo Social en un comando: servidor Serverpod con datos de
# demo + la app. No necesita Docker: la base es un PostgreSQL embebido que
# levanta Serverpod.
#
#   tool/demo.sh                 # servidor + app en Chrome
#   tool/demo.sh -d <device-id>  # la app en otro dispositivo (un teléfono)
#   tool/demo.sh --server-only   # sólo el servidor (para correr la app aparte)
#
# Variables opcionales:
#   AGORA_APP_ID   video real en los vivos (sin ella, el video es simulado)
#   API_HOST       IP de esta máquina, para que un teléfono llegue al servidor
#
# Cuentas: elena@nexo.demo, operador@nexo.demo, moderador@nexo.demo,
# tomas@nexo.demo, troll@nexo.demo, carlos@nexo.demo. Contraseña:
# nexo-demo-2026 (o el botón "Elegir cuenta de demo" en la app).
set -euo pipefail

SERVERPOD_VERSION="4.0.3"
DEMO_PASSWORD="nexo-demo-2026"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER="$ROOT/services/serverpod/nexo_server"
APP="$ROOT/apps/nexo_social"

device="chrome"
server_only=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--device) device="$2"; shift 2 ;;
    --server-only) server_only=true; shift ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) echo "Opción desconocida: $1 (ver --help)" >&2; exit 1 ;;
  esac
done

say() { printf '\n\033[1;34m▸ %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# --- Herramientas -------------------------------------------------------------
command -v flutter >/dev/null || fail "Falta Flutter (3.47.5 o superior): https://docs.flutter.dev/get-started/install"
command -v dart >/dev/null || fail "Falta dart (viene con Flutter)."

dart_install_bin="$HOME/Library/Application Support/Dart/install/bin"
[[ -d "$dart_install_bin" ]] || dart_install_bin="${XDG_STATE_HOME:-$HOME/.local/state}/Dart/install/bin"
export PATH="$dart_install_bin:$PATH"
if ! serverpod version 2>/dev/null | grep -q "$SERVERPOD_VERSION"; then
  say "Instalando el CLI de Serverpod $SERVERPOD_VERSION"
  dart install "serverpod_cli@$SERVERPOD_VERSION"
fi

# --- Secretos de desarrollo ---------------------------------------------------
# config/passwords.yaml no se versiona. Si falta, se genera con valores al
# azar: sirven sólo para esta máquina.
passwords="$SERVER/config/passwords.yaml"
if [[ ! -f "$passwords" ]]; then
  say "Generando config/passwords.yaml"
  rand() { LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$1"; }
  cat >"$passwords" <<YAML
# Generado por tool/demo.sh. Sólo desarrollo local; no se versiona.
development:
  database: '$(rand 32)'
  serviceSecret: '$(rand 48)'
  jwtHmacSha512PrivateKey: '$(rand 64)'
  jwtRefreshTokenHashPepper: '$(rand 48)'
  emailSecretHashPepper: '$(rand 48)'
YAML
fi

# --- Base de datos ------------------------------------------------------------
# El PostgreSQL embebido falla si su carpeta de datos queda en una ruta con
# espacios. En ese caso se guarda fuera del repo.
if [[ "$SERVER" == *" "* ]]; then
  export SERVERPOD_DATABASE_DATA_PATH="$HOME/.nexo/dev-pgdata"
  say "El repo está en una ruta con espacios: la base va a $SERVERPOD_DATABASE_DATA_PATH"
fi

# --- Dependencias -------------------------------------------------------------
say "Instalando dependencias"
(cd "$ROOT/services/serverpod" && flutter pub get >/dev/null)
(cd "$APP" && flutter pub get >/dev/null)

# --- Servidor -----------------------------------------------------------------
say "Levantando el servidor (migraciones + datos de demo)"
server_log="$(mktemp -t nexo-server.XXXX)"
(cd "$SERVER" && NEXO_DEMO_SEED=1 dart run bin/main.dart --apply-migrations) \
  >"$server_log" 2>&1 &
server_pid=$!
cleanup() { kill "$server_pid" 2>/dev/null || true; }
trap cleanup EXIT INT TERM

for _ in $(seq 1 120); do
  if grep -qE "Demo: " "$server_log"; then break; fi
  if ! kill -0 "$server_pid" 2>/dev/null; then
    cat "$server_log" >&2
    fail "El servidor no arrancó (log arriba)."
  fi
  sleep 1
done
grep -E "Demo: " "$server_log" || { cat "$server_log" >&2; fail "El servidor no terminó de arrancar en 2 minutos."; }
echo "  Log del servidor: $server_log"
echo "  Los códigos de verificación de registros nuevos aparecen en ese log."

if $server_only; then
  say "Servidor listo en http://localhost:8080 (Ctrl+C para cortar)"
  wait "$server_pid"
  exit 0
fi

# --- App ----------------------------------------------------------------------
api_url="http://${API_HOST:-localhost}:8080/"
say "Abriendo la app en $device (servidor: $api_url)"
(cd "$APP" && flutter run -d "$device" \
  --dart-define=AUTH_SOURCE=serverpod \
  --dart-define=API_BASE_URL="$api_url" \
  --dart-define=DEMO_PASSWORD="$DEMO_PASSWORD" \
  ${AGORA_APP_ID:+--dart-define=AGORA_APP_ID=$AGORA_APP_ID})
