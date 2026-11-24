#!/usr/bin/env bash
# Aplica este setup de ingeniería a otro repositorio.
# No sobrescribe CLAUDE.md, README.md ni .gitignore si ya existen.
#
# Uso: scripts/apply-template.sh /ruta/al/otro/repo
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:?Uso: apply-template.sh /ruta/al/repo-destino}"
[ -d "$DEST/.git" ] || { echo "No es un repo git: $DEST" >&2; exit 1; }

copy_dir() { mkdir -p "$DEST/$1"; cp -R "$SRC/$1/." "$DEST/$1/"; echo "copiado: $1/"; }
copy_new() {
  if [ -e "$DEST/$1" ]; then echo "se conserva: $1 (ya existe)"; else
    mkdir -p "$(dirname "$DEST/$1")"; cp "$SRC/$1" "$DEST/$1"; echo "copiado: $1"; fi
}

copy_dir .claude
copy_dir scripts
copy_dir docs/templates
copy_dir .github/workflows
for f in .mcp.json CLAUDE.md REVIEW.md .gitignore docs/SDLC.md docs/SETUP.md; do copy_new "$f"; done

chmod +x "$DEST"/scripts/*.sh "$DEST"/scripts/hooks/*.sh
echo "Listo. Revisa CLAUDE.md del destino y abre una sesión nueva para cargar skills y hooks."
