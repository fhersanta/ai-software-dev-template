#!/usr/bin/env bash
# Hook SessionStart. Solo actúa en sesiones cloud de Claude Code
# (contenedor efímero): instala las herramientas que no viajan en el repo.
# Nunca debe hacer fallar el arranque: cada paso es de mejor esfuerzo.
set -uo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0
export DO_NOT_TRACK=1
LOG="${TMPDIR:-/tmp}/session-start.log"

step() { # descripción comando...
  local name="$1"; shift
  if "$@" >>"$LOG" 2>&1; then echo "ok: $name"; else echo "omitido: $name (ver $LOG)"; fi
}

# Headroom: se instala el CLI, pero NO se envuelve a Claude. Activarlo es
# manual (ver docs/SETUP.md) porque enruta todo el tráfico por un proxy local.
if command -v uv >/dev/null && ! command -v headroom >/dev/null; then
  step "headroom" uv tool install --python 3.13 headroom-ai==0.45.0
fi

# Plugin de seguridad de Anthropic. Queda activo a partir de la siguiente
# sesión o tras /reload-plugins.
if command -v claude >/dev/null; then
  step "marketplace oficial" claude plugin marketplace add anthropics/claude-plugins-official
  step "security-guidance" claude plugin install security-guidance@claude-plugins-official --scope project
fi

# Dependencias del proyecto, si el proyecto define su propio script.
if [ -x scripts/install-deps.sh ]; then
  step "dependencias del proyecto" scripts/install-deps.sh
fi
exit 0
