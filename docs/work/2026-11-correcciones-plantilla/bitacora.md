# Bitácora

## 2026-11-26
- Pruebas primero (rojo; viven en `tests/` y no en `scripts/`, porque `apply-template.sh` copia todo `scripts/` a los proyectos y habría pisado su `verify.sh`): `session-start.test.sh` (3 fallos por `headroom-ai` sin versión) y `vendor-skills.test.sh` (3 fallos: destino borrado si el origen no existe, `keep_license` devuelve error si falta el último archivo, `SKILL.md` con ruta relativa). Se refactorizó `vendor-skills.sh` (funciones + `main` solo si se ejecuta directamente) antes de escribir las pruebas de `copy_skills`; el refactor no cambió el comportamiento (comprobado con la ejecución real).
- Mutación: se rompió cada conducta a propósito y la prueba correspondiente falló (4 mutaciones).
- Ejecución real de `scripts/vendor-skills.sh` con descarga: 41 skills; solo cambiaron los 8 `SKILL.md` de `egm-*`.
- Documentación consultada (subagente `claude-code-guide`, solo lectura): `${CLAUDE_SKILL_DIR}` y `${CLAUDE_PROJECT_DIR}` se sustituyen en el contenido del skill; no está documentado si también en archivos de soporte, ni contra qué directorio resuelve el modelo las rutas relativas. Por eso solo los `SKILL.md` usan la variable.
- Defectos latentes encontrados al escribir las pruebas (no los había reportado CodeRabbit): `copy_skills` borraba el destino antes de comprobar el origen y `keep_license` devolvía 1 si el último archivo opcional no existía (con `set -e` abortaba el script).
