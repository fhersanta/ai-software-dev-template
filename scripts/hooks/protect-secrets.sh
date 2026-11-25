#!/usr/bin/env bash
# Hook PreToolUse (Write|Edit|MultiEdit|NotebookEdit|Bash): bloquea escrituras en
# archivos de secretos y contenido que parece una credencial. Sale con 2 para
# que Claude Code rechace la llamada y muestre el motivo al modelo.
set -euo pipefail

command -v jq >/dev/null || { echo "Bloqueado: el hook de secretos necesita jq y no está instalado." >&2; exit 2; }

input="$(cat)"
path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')"
command_text="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"
content="$(printf '%s' "$input" | jq -r '
  (.tool_input.content // "") + (.tool_input.new_string // "") + (.tool_input.new_source // "")
  + ((.tool_input.edits // []) | map(.new_string // "") | join("\n"))
  + (.tool_input.command // "")')"
base="$(basename "$path")"

secret_file='(^|[/[:space:]"'"'"'=])(\.env(\.[A-Za-z0-9_-]+)?|[^[:space:]/]*\.(pem|key|p12|pfx)|id_rsa|id_ed25519|credentials\.json|service-?[Aa]ccount[^[:space:]/]*\.json)($|[[:space:]"'"'"';|&)])'

case "$base" in
  .env.example|.env.sample|.env.template) ;;
  .env|.env.*|*.pem|*.key|*.p12|*.pfx|id_rsa|id_ed25519|credentials.json|service-account*.json|serviceAccount*.json)
    echo "Bloqueado: '$path' es un archivo de secretos. Usa el gestor de secretos o variables del entorno." >&2
    exit 2 ;;
esac

# Bash: ni leer ni escribir archivos de secretos (las plantillas .env.example sí).
if [ -n "$command_text" ]; then
  stripped="$(printf '%s' "$command_text" | sed -E 's/\.env\.(example|sample|template)//g')"
  if printf '%s' "$stripped" | grep -Eq "$secret_file"; then
    echo "Bloqueado: el comando toca un archivo de secretos." >&2
    exit 2
  fi
fi

if printf '%s' "$content" | grep -Eq \
  -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
  -e 'AKIA[0-9A-Z]{16}' \
  -e 'sk-(ant|or|proj)-[A-Za-z0-9_-]{20,}' \
  -e 'sk-[A-Za-z0-9]{32,}' \
  -e 'gh[pousr]_[A-Za-z0-9]{36,}' \
  -e 'AIza[0-9A-Za-z_-]{35}' \
  -e 'xox[baprs]-[A-Za-z0-9-]{10,}' \
  -e '"private_key"[[:space:]]*:[[:space:]]*"-----BEGIN'; then
  echo "Bloqueado: el contenido parece incluir una credencial. Léela de una variable de entorno." >&2
  exit 2
fi
exit 0
