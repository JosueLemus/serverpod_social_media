#!/usr/bin/env bash
# Backup diario de la base de la demo, con 7 días de retención (SDD 0009).
# `tool/aws/deploy.sh` lo instala en el cron del usuario:
#   15 4 * * * /opt/nexo/backup.sh >> /opt/nexo/backups/backup.log 2>&1
# Restaurar:
#   docker compose exec -T postgres pg_restore -U postgres -d nexo --clean \
#     < backups/nexo-AAAA-MM-DD.dump
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p backups
stamp="$(date +%Y-%m-%d)"

# El formato custom ya viene comprimido. Se escribe aparte y se renombra al
# final: un dump cortado a la mitad nunca queda con el nombre del día.
docker compose exec -T postgres pg_dump -U postgres -d nexo --format=custom \
  > "backups/nexo-$stamp.dump.tmp"
mv "backups/nexo-$stamp.dump.tmp" "backups/nexo-$stamp.dump"

find backups -name 'nexo-*.dump' -mtime +7 -delete
echo "$(date -Iseconds) backup listo: backups/nexo-$stamp.dump"
