#!/usr/bin/env bash
# Utilidades mínimas para las pruebas de scripts/. Sin dependencias externas.
FALLOS=0
PRUEBAS=0

ok()   { PRUEBAS=$((PRUEBAS + 1)); echo "  ok: $1"; }
fallo() { PRUEBAS=$((PRUEBAS + 1)); FALLOS=$((FALLOS + 1)); echo "  FALLO: $1" >&2; }

# afirma "descripción" comando...   (pasa si el comando sale con 0)
afirma() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else fallo "$desc"; fi
}

# niega "descripción" comando...    (pasa si el comando sale distinto de 0)
niega() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then fallo "$desc"; else ok "$desc"; fi
}

resumen() {
  echo "$PRUEBAS pruebas, $FALLOS fallos"
  [ "$FALLOS" -eq 0 ]
}
