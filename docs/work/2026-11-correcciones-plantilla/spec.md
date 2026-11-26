# Spec: correcciones pendientes de la plantilla

**Aprobado por:** el usuario de la sesión, mismo mensaje que `intent.md`.

## Comportamiento
- `scripts/session-start.sh` instala `headroom-ai==0.45.0` (última versión en PyPI al 2026-11-26, la que ya documenta `docs/SETUP.md`). Una prueba exige versión exacta y que coincida con `docs/SETUP.md`.
- `scripts/vendor-skills.sh` define funciones y solo corre `main` cuando se ejecuta directamente; con `source` no descarga nada.
- `copy_skills`: reemplaza por completo el destino; copia los archivos internos; no toca skills no pedidos; si el skill no existe en el origen, falla **sin borrar** el destino existente.
- `keep_license`: copia lo que exista; que falte un archivo (también el último) no es un error.
- `rewrite_egm_paths`: en los `SKILL.md` de `egm-*` usa `${CLAUDE_PROJECT_DIR}/.claude/vendor/egm` (sustitución documentada en el contenido del skill); en los demás archivos, `.claude/vendor/egm` relativo a la raíz (la sustitución en archivos de soporte no está documentada). No toca skills que no son `egm-*`.

## Criterios de aceptación
- `tests/verify.sh` sale con 0: pruebas de `tests/` y shellcheck sin hallazgos.
- Cada prueba falla al romper la conducta que protege (comprobado por mutación).
- `scripts/vendor-skills.sh` ejecutado de verdad (con descarga) termina con 41 skills y solo cambian los 8 `SKILL.md` de `egm-*`.

## Sin verificar
- Que `${CLAUDE_PROJECT_DIR}` se sustituya en una sesión real con los skills `egm-*` (solo documentación).
- Cómo resuelve el modelo las rutas relativas de los archivos de soporte al iniciar la sesión en un subdirectorio.
