#!/usr/bin/env bash
# Hook PreToolUse (Write|Edit): bloquea escrituras en archivos de secretos y
# contenido que parece una credencial. Sale con 2 para que Claude Code rechace
# la llamada y muestre el motivo al modelo.
set -euo pipefail

input="$(cat)"
path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
content="$(printf '%s' "$input" | jq -r '(.tool_input.content // "") + (.tool_input.new_string // "")')"
base="$(basename "$path")"

case "$base" in
  .env.example|.env.sample|.env.template) ;;
  .env|.env.*|*.pem|*.key|*.p12|*.pfx|id_rsa|id_ed25519|credentials.json|service-account*.json)
    echo "Bloqueado: '$path' es un archivo de secretos. Usa el gestor de secretos o variables del entorno." >&2
    exit 2 ;;
esac

if printf '%s' "$content" | grep -Eq \
  -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
  -e 'AKIA[0-9A-Z]{16}' \
  -e 'sk-(ant|or|proj)-[A-Za-z0-9_-]{20,}' \
  -e 'gh[pousr]_[A-Za-z0-9]{36,}' \
  -e 'AIza[0-9A-Za-z_-]{35}' \
  -e 'xox[baprs]-[A-Za-z0-9-]{10,}'; then
  echo "Bloqueado: el contenido parece incluir una credencial. Léela de una variable de entorno." >&2
  exit 2
fi
exit 0
