#!/usr/bin/env bash
# Pruebas estáticas de scripts/session-start.sh.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=tests/lib.sh
. "$ROOT/tests/lib.sh"
SCRIPT="$ROOT/scripts/session-start.sh"
SETUP="$ROOT/docs/SETUP.md"

echo "session-start.sh"

# Toda instalación de headroom-ai lleva versión exacta (dependencia fijada).
sin_fijar() { grep -E 'headroom-ai' "$SCRIPT" | grep -vE 'headroom-ai==[0-9]+\.[0-9]+\.[0-9]+'; }
niega "headroom-ai nunca se instala sin versión exacta" sin_fijar
afirma "headroom-ai se instala con versión exacta" grep -qE 'uv tool install .*headroom-ai==[0-9]+\.[0-9]+\.[0-9]+' "$SCRIPT"

# La versión del script y la documentada en SETUP.md no se desacoplan.
version="$(grep -oE 'headroom-ai==[0-9]+\.[0-9]+\.[0-9]+' "$SCRIPT" | head -1 | cut -d= -f3)"
afirma "se pudo leer la versión fijada" test -n "$version"
afirma "SETUP.md menciona la misma versión de headroom ($version)" grep -q "versión $version" "$SETUP"

resumen
