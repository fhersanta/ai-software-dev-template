#!/usr/bin/env bash
# Aplica este setup de ingeniería a otro repositorio sin pisar lo que ya tiene.
# Nunca sobrescribe un archivo existente: lo deja y avisa, para fusionarlo a mano
# (en especial .claude/settings.json, CLAUDE.md y los workflows).
#
# Uso: scripts/apply-template.sh /ruta/al/otro/repo
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:?Uso: apply-template.sh /ruta/al/repo-destino}"
[ -d "$DEST/.git" ] || { echo "No es un repo git: $DEST" >&2; exit 1; }

pending=()
copy_new() {
  if [ -e "$DEST/$1" ]; then
    cmp -s "$SRC/$1" "$DEST/$1" || pending+=("$1")
  else
    mkdir -p "$(dirname "$DEST/$1")"; cp -p "$SRC/$1" "$DEST/$1"; echo "copiado: $1"
  fi
}

cd "$SRC"
# Los scripts de mantenimiento de la plantilla no viajan al proyecto.
while IFS= read -r f; do copy_new "$f"; done < <(
  find .claude scripts docs/templates docs/work docs/incidents .github/workflows -type f \
    ! -name apply-template.sh ! -name vendor-skills.sh | sed 's|^\./||' | sort)
for f in .mcp.json CLAUDE.md REVIEW.md .gitignore docs/SDLC.md docs/SETUP.md; do copy_new "$f"; done

# Patrones de secretos en un .gitignore que ya existía.
for p in '.env' '.env.*' '!.env.example' '*.pem' '*.key' 'secrets/' '.claude/settings.local.json'; do
  grep -qxF -- "$p" "$DEST/.gitignore" || { echo "$p" >> "$DEST/.gitignore"; echo "añadido a .gitignore: $p"; }
done

chmod +x "$DEST"/scripts/*.sh "$DEST"/scripts/hooks/*.sh
if [ "${#pending[@]}" -gt 0 ]; then
  echo; echo "Ya existían y difieren; fusiónalos a mano:"; printf '  %s\n' "${pending[@]}"
fi
echo "Falta en el destino: scripts/install-deps.sh y el comando de verificación en CLAUDE.md."
echo "Abre una sesión nueva para cargar skills y hooks."
