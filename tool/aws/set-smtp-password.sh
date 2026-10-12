#!/usr/bin/env bash
# Activa el email de los códigos de verificación en producción: carga la
# contraseña de aplicación de Gmail en GitHub Secrets y redespliega.
#
#   tool/aws/set-smtp-password.sh
#
# La contraseña se escribe sin eco: no queda en la pantalla, en el historial
# de la terminal ni en la línea de comandos. Viaja a GitHub por stdin.
#
# Antes: verificación en 2 pasos activada en la cuenta de Google y una
# contraseña de aplicación creada en https://myaccount.google.com/apppasswords
# (16 letras; los espacios no importan).
#
# Variables opcionales:
#   SMTP_USER   la cuenta de Gmail que envía (por defecto, la que ya está
#               cargada como secreto; si no hay ninguna, la pide)
set -euo pipefail

say() { printf '\n\033[1;34m▸ %s\033[0m\n' "$*"; }
fail() { printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

command -v gh >/dev/null || fail "Falta la CLI de GitHub (brew install gh)."
REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)" \
  || fail "Corré el script desde el repo, con gh logueado (gh auth login)."

has_secret() { gh secret list --repo "$REPO" --json name --jq '.[].name' | grep -qx "$1"; }

# Gmail sólo envía como la cuenta autenticada: el remitente es el usuario.
if ! has_secret SMTP_USER || [[ -n "${SMTP_USER:-}" ]]; then
  user="${SMTP_USER:-}"
  [[ -n "$user" ]] || read -r -p "Cuenta de Gmail que envía los códigos: " user
  [[ "$user" == *@* ]] || fail "Eso no parece un email: $user"
  for name in SMTP_USER SMTP_FROM; do printf '%s' "$user" | gh secret set "$name" --repo "$REPO" >/dev/null; done
  printf '%s' smtp.gmail.com | gh secret set SMTP_HOST --repo "$REPO" >/dev/null
  printf '%s' 587 | gh secret set SMTP_PORT --repo "$REPO" >/dev/null
fi

read -r -s -p "Contraseña de aplicación de Gmail (no se ve al escribir): " password
echo
password="${password// /}"
[[ ${#password} -eq 16 ]] \
  || fail "Una contraseña de aplicación de Gmail tiene 16 letras; llegaron ${#password}."

printf '%s' "$password" | gh secret set SMTP_PASSWORD --repo "$REPO" >/dev/null
unset password
say "SMTP_PASSWORD cargado en GitHub Secrets"

say "Redesplegando producción con el email activado"
gh workflow run deploy.yml --repo "$REPO" --ref main
echo "  Seguilo con: gh run watch --repo $REPO \$(gh run list --repo $REPO --workflow deploy.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
echo "  Cuando termine, registrate con un email real en la web: el código llega por mail."
