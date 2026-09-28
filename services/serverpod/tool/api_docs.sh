#!/usr/bin/env bash
# Genera la documentación de la API (nexo_client) y la sirve en localhost:
#   /map/  mapa por módulo y endpoint, estilo Swagger (tool/api_map.dart)
#   /      referencia Dart completa (dart doc)
# Uso: ./tool/api_docs.sh [puerto]   (por defecto 8000)
set -euo pipefail

port="${1:-8000}"
workspace_dir="$(cd "$(dirname "$0")/.." && pwd)"
client_dir="$workspace_dir/nexo_client"

cd "$client_dir"
dart doc

cd "$workspace_dir"
dart run tool/api_map.dart

echo "Mapa de la API:  http://localhost:$port/map/"
echo "Referencia Dart: http://localhost:$port/"
echo "(Ctrl+C para detener)"
cd "$client_dir/doc/api"
python3 -m http.server "$port"
