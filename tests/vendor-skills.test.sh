#!/usr/bin/env bash
# shellcheck disable=SC2016  # los ${...} entre comillas simples son literales a propósito
# Pruebas de scripts/vendor-skills.sh. Solo usan directorios temporales locales:
# no descargan nada de GitHub ni llaman a main().
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=tests/lib.sh
. "$ROOT/tests/lib.sh"
# shellcheck source=scripts/vendor-skills.sh
. "$ROOT/scripts/vendor-skills.sh"

echo "vendor-skills.sh"

W=""
trap '[ -n "$W" ] && rm -rf "$W"' EXIT

# Entorno aislado: TMP hace de "descargas", SKILLS y VENDOR de destino.
nuevo_entorno() {
  W="$(mktemp -d)" || exit 1
  TMP="$W/descargas"; SKILLS="$W/skills"; VENDOR="$W/vendor"
  mkdir -p "$TMP/up/skills/alfa/sub" "$TMP/up/skills/beta" "$SKILLS" "$VENDOR"
  echo "nuevo" > "$TMP/up/skills/alfa/SKILL.md"
  echo "interno" > "$TMP/up/skills/alfa/sub/f.txt"
  echo "beta" > "$TMP/up/skills/beta/SKILL.md"
}

# Cargar el archivo no ejecuta main: no crea TMP ni descarga nada.
afirma "cargar el script con source no ejecuta main (TMP vacío)" test -z "$(bash -c '. "'"$ROOT"'/scripts/vendor-skills.sh"; echo "$TMP"')"

# --- copy_skills -------------------------------------------------------------
nuevo_entorno
mkdir -p "$SKILLS/alfa"; echo "viejo" > "$SKILLS/alfa/viejo.txt"; echo "no tocar" > "$SKILLS/otro.txt"
copy_skills up alfa
afirma "copy_skills copia el SKILL.md" grep -q nuevo "$SKILLS/alfa/SKILL.md"
afirma "copy_skills copia los archivos internos del skill" test -f "$SKILLS/alfa/sub/f.txt"
niega  "copy_skills reemplaza por completo el destino (no queda lo viejo)" test -e "$SKILLS/alfa/viejo.txt"
afirma "copy_skills no toca archivos ajenos al skill" test -f "$SKILLS/otro.txt"
niega  "copy_skills no copia skills que no se pidieron" test -e "$SKILLS/beta"
rm -rf "$W"

nuevo_entorno
mkdir -p "$SKILLS/alfa"; echo "viejo" > "$SKILLS/alfa/viejo.txt"
copy_skills up alfa beta
afirma "copy_skills acepta varios skills" test -f "$SKILLS/beta/SKILL.md"
rm -rf "$W"

# Si el skill no existe en el origen, falla y NO borra el destino que ya había.
nuevo_entorno
mkdir -p "$SKILLS/fantasma"; echo "conservar" > "$SKILLS/fantasma/SKILL.md"
niega  "copy_skills falla si el skill no existe en el origen" copy_skills up fantasma
afirma "copy_skills conserva el destino si el origen no existe" grep -q conservar "$SKILLS/fantasma/SKILL.md"
rm -rf "$W"

# --- keep_license ------------------------------------------------------------
nuevo_entorno
echo "mit" > "$TMP/up/LICENSE"
afirma "keep_license copia la licencia" bash -c '. "'"$ROOT"'/scripts/vendor-skills.sh"; TMP="'"$TMP"'"; VENDOR="'"$VENDOR"'"; keep_license up LICENSE'
afirma "la licencia queda en vendor/licenses/<nombre>" test -f "$VENDOR/licenses/up/LICENSE"
# Un archivo opcional ausente al final no debe hacer fallar a quien llama (set -e).
afirma "keep_license no falla si el último archivo no existe" bash -c 'set -e; . "'"$ROOT"'/scripts/vendor-skills.sh"; TMP="'"$TMP"'"; VENDOR="'"$VENDOR"'"; keep_license up LICENSE NOTICE'
rm -rf "$W"

# --- rewrite_egm_paths -------------------------------------------------------
nuevo_entorno
mkdir -p "$SKILLS/egm-review/references" "$SKILLS/otro-skill" "$VENDOR/egm/docs"
printf 'Lee ${CLAUDE_PLUGIN_ROOT}/docs/claude.md\n' > "$SKILLS/egm-review/SKILL.md"
printf 'Ver ${CLAUDE_PLUGIN_ROOT}/resources/x.md\n' > "$SKILLS/egm-review/references/r.md"
printf 'Persona ${CLAUDE_PLUGIN_ROOT}/agents/y.md\n' > "$VENDOR/egm/docs/claude.md"
printf 'Intacto ${CLAUDE_PLUGIN_ROOT}\n' > "$SKILLS/otro-skill/SKILL.md"
rewrite_egm_paths
afirma "SKILL.md usa la raíz del proyecto (no depende del directorio de trabajo)" grep -qF 'Lee ${CLAUDE_PROJECT_DIR}/.claude/vendor/egm/docs/claude.md' "$SKILLS/egm-review/SKILL.md"
afirma "archivos de soporte del skill usan la ruta relativa a la raíz" grep -qF 'Ver .claude/vendor/egm/resources/x.md' "$SKILLS/egm-review/references/r.md"
afirma "archivos de vendor/egm usan la ruta relativa a la raíz" grep -qF 'Persona .claude/vendor/egm/agents/y.md' "$VENDOR/egm/docs/claude.md"
niega  "no queda ninguna CLAUDE_PLUGIN_ROOT en egm-* ni en vendor/egm" grep -rq CLAUDE_PLUGIN_ROOT "$SKILLS/egm-review" "$VENDOR/egm"
afirma "no toca skills que no son egm-*" grep -qF 'Intacto ${CLAUDE_PLUGIN_ROOT}' "$SKILLS/otro-skill/SKILL.md"
rm -rf "$W"

# --- hallazgos de la revisión de seguridad ----------------------------------
# Las variables de entorno genéricas SKILLS/VENDOR no deben redirigir los destinos
# (un SKILLS exportado en el shell del usuario haría que rm -rf borrara fuera del repo).
destino="$(SKILLS=/tmp/ajeno VENDOR=/tmp/ajeno2 bash -c '. "'"$ROOT"'/scripts/vendor-skills.sh"; echo "$SKILLS|$VENDOR"')"
afirma "el entorno no redirige SKILLS (rm -rf)" test "${destino%%|*}" = "$ROOT/.claude/skills"
afirma "el entorno no redirige VENDOR" test "${destino##*|}" = "$ROOT/.claude/vendor"

# copy_skills se niega a operar con un destino vacío o la raíz del sistema. Cada caso
# corre en un subshell con TMP propio. El skill de prueba lleva un nombre único para que,
# si la guarda fallara, no choque con nada del sistema real.
nuevo_entorno
nombre="vendor-skills-prueba-$$"
mkdir -p "$TMP/up/skills/$nombre"; echo x > "$TMP/up/skills/$nombre/SKILL.md"
niega "copy_skills se niega si SKILLS es /" bash -c '. "'"$ROOT"'/scripts/vendor-skills.sh"; TMP="'"$TMP"'"; SKILLS=/; copy_skills up '"$nombre"
niega "copy_skills se niega si SKILLS está vacío" bash -c '. "'"$ROOT"'/scripts/vendor-skills.sh"; TMP="'"$TMP"'"; SKILLS=; copy_skills up '"$nombre"
niega "no se creó nada en la raíz del sistema" test -e "/$nombre"
rm -rf "$W"

# rewrite_egm_paths falla en voz alta si queda alguna forma sin reescribir.
nuevo_entorno
mkdir -p "$SKILLS/egm-review"
printf 'Forma sin llaves: $CLAUDE_PLUGIN_ROOT/docs\n' > "$SKILLS/egm-review/SKILL.md"
niega "rewrite_egm_paths falla si queda una forma no reescrita de CLAUDE_PLUGIN_ROOT" rewrite_egm_paths
rm -rf "$W"

resumen
