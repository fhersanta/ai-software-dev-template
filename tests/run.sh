#!/usr/bin/env bash
# Corre todas las pruebas de tests/*.test.sh. Sale distinto de 0 si alguna falla.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
estado=0
for t in tests/*.test.sh; do
  bash "$t" || estado=1
done
exit "$estado"
