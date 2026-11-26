#!/usr/bin/env bash
# Verificación de la plantilla: pruebas de tests/ y shellcheck (si está
# instalado). Sale distinto de 0 si algo falla.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
estado=0

bash tests/run.sh || estado=1

if command -v shellcheck >/dev/null; then
  shellcheck scripts/*.sh tests/*.sh scripts/hooks/*.sh || estado=1
  [ "$estado" -eq 0 ] && echo "shellcheck: sin hallazgos"
else
  echo "shellcheck: no instalado, se omite (instálalo para correr el análisis estático)"
fi
exit "$estado"
