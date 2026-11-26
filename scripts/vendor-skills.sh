#!/usr/bin/env bash
# Copia skills de terceros a .claude/skills/ desde commits fijados.
# Las sesiones cloud de Claude Code no cargan marketplaces declarados en el
# repo, así que los skills se versionan aquí. Para actualizar: cambia el SHA,
# revisa el diff de hooks y skills del upstream, y vuelve a ejecutar.
#
# Uso: scripts/vendor-skills.sh
#
# El archivo también se puede cargar con `source` (las pruebas de
# tests/ lo hacen): solo define funciones; no descarga ni copia nada
# hasta que se ejecuta directamente.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS="${SKILLS:-$ROOT/.claude/skills}"
VENDOR="${VENDOR:-$ROOT/.claude/vendor}"
TMP=""

# nombre | repo | commit fijado
PINS="
superpowers|obra/superpowers|22f0b463e7a5e579904dd6211a520321035526f7
ponytail|DietrichGebert/ponytail|ebd8654c2c627f721eb8f9c0d1bd4090a29f9e10
caveman|JuliusBrussee/caveman|47c61be2d10a354f0c5cbe2b90959d24c06b16c6
egm|google/elephant-goldfish-model|ef27af6b1d76901d09bb346eea62ce377546052f
livekit|livekit/agent-skills|378fb2b6998c5a9a4dc135dfbf65af05d0d6c8ac
"

fetch() { # nombre repo sha
  git init -q "$TMP/$1"
  git -C "$TMP/$1" remote add origin "https://github.com/$2"
  git -C "$TMP/$1" fetch -q --depth 1 origin "$3"
  git -C "$TMP/$1" checkout -q FETCH_HEAD
}

copy_skills() { # nombre skill...
  local name="$1"; shift
  for s in "$@"; do
    # Se comprueba el origen ANTES de borrar: si falta, el destino se conserva.
    if [ ! -d "$TMP/$name/skills/$s" ]; then
      echo "vendor-skills: falta el skill '$s' en '$name'" >&2
      return 1
    fi
    rm -rf "${SKILLS:?}/$s"
    cp -R "$TMP/$name/skills/$s" "$SKILLS/$s"
  done
}

keep_license() { # nombre archivo...
  local name="$1"; shift
  mkdir -p "$VENDOR/licenses/$name"
  for f in "$@"; do
    # Los archivos son opcionales: que falte uno no es un error (ni siquiera el último).
    if [ -f "$TMP/$name/$f" ]; then cp "$TMP/$name/$f" "$VENDOR/licenses/$name/"; fi
  done
}

# Reescribe la raíz del plugin EGM en los skills egm-* y en .claude/vendor/egm.
# - SKILL.md: Claude Code sustituye ${CLAUDE_PROJECT_DIR} en el contenido del
#   skill (documentado), así la ruta no depende del directorio de trabajo.
# - Demás archivos (soporte del skill y .claude/vendor/egm): la sustitución no está
#   documentada para ellos, así que la ruta queda relativa a la raíz del proyecto
#   (límite conocido: ver docs/SETUP.md).
rewrite_egm_paths() {
  local f reemplazo
  while IFS= read -r -d '' f; do
    if [ "$(basename "$f")" = "SKILL.md" ]; then
      # shellcheck disable=SC2016  # literal: lo sustituye Claude Code, no el shell
      reemplazo='${CLAUDE_PROJECT_DIR}/.claude/vendor/egm'
    else
      reemplazo='.claude/vendor/egm'
    fi
    sed -i "s|\\\${CLAUDE_PLUGIN_ROOT}|${reemplazo}|g" "$f"
  done < <(grep -rlZ 'CLAUDE_PLUGIN_ROOT' "$SKILLS"/egm-* "$VENDOR/egm" 2>/dev/null || true)
}

main() {
  set -euo pipefail
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  mkdir -p "$SKILLS" "$VENDOR"
  echo "$PINS" | while IFS='|' read -r name repo sha; do
    [ -n "$name" ] || continue
    echo "Descargando $repo@${sha:0:7}"
    fetch "$name" "$repo" "$sha"
  done

  # superpowers: los 15 skills. No se copia su hook SessionStart (inyecta el
  # skill using-superpowers completo en cada sesión); CLAUDE.md lo sustituye.
  copy_skills superpowers brainstorming diagnosing-superpowers \
    dispatching-parallel-agents executing-plans finishing-a-development-branch \
    receiving-code-review requesting-code-review subagent-driven-development \
    systematic-debugging test-driven-development using-git-worktrees \
    using-superpowers verification-before-completion writing-plans writing-skills
  keep_license superpowers LICENSE

  # ponytail: solo skills. Sus hooks Node (SessionStart, SubagentStart,
  # UserPromptSubmit) no se copian: se activa a mano con /ponytail.
  copy_skills ponytail ponytail ponytail-audit ponytail-debt ponytail-gain \
    ponytail-help ponytail-review
  keep_license ponytail LICENSE

  # caveman: solo los skills de voz, sin proxy, motor, MCP ni telemetría.
  copy_skills caveman caveman ultracave caveman-commit caveman-review caveman-help
  keep_license caveman LICENSE LICENSE-MIT NOTICE

  # EGM: los skills leen personas y estándares desde la raíz del plugin.
  # Se copian a .claude/vendor/egm y se reescriben las rutas.
  copy_skills egm egm-bootstrap egm-brainstorm egm-draft egm-drift-report \
    egm-lite egm-resolve egm-review egm-review-loop
  rm -rf "$VENDOR/egm"
  mkdir -p "$VENDOR/egm"
  cp -R "$TMP/egm/agents" "$TMP/egm/resources" "$VENDOR/egm/"
  mkdir -p "$VENDOR/egm/docs"
  cp "$TMP/egm/docs/claude.md" "$TMP/egm/docs/harnesses.md" "$VENDOR/egm/docs/" 2>/dev/null || true
  rewrite_egm_paths
  keep_license egm LICENSE

  # LiveKit: los 7 skills. El MCP de documentación va en .mcp.json.
  copy_skills livekit building-livekit-agents debugging-livekit-agents \
    operating-livekit-agents reading-livekit-docs running-livekit-simulations \
    testing-livekit-agents writing-livekit-scenarios
  keep_license livekit LICENSE

  echo "$PINS" | sed '/^$/d' > "$VENDOR/PINS.txt"
  echo "Listo: $(find "$SKILLS" -name SKILL.md | wc -l) skills en .claude/skills"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  main "$@"
fi
