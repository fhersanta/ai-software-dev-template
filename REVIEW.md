# Criterios de revisión de PR

Tres pasadas, en este orden: errores de comportamiento, seguridad, cumplimiento contra `spec.md` y `plan.md`.

## Severidad

- **Bloquea:** bug que cambia el comportamiento, fallo de seguridad con escenario concreto, criterio de aceptación sin cumplir, test ausente para lógica nueva, secreto en el diff.
- **Importante:** manejo de errores faltante en un borde del sistema, dependencia sin fijar, código muerto añadido.
- **Menor:** nombres, estilo, comentarios. Máximo tres por PR; el resto se omite.

## No revisar

Código copiado de terceros (`.claude/skills/`, `.claude/vendor/`), archivos generados y lockfiles.

## Reglas

- Cada hallazgo lleva `archivo:línea`, el escenario que falla y la corrección propuesta.
- El agente que escribió el cambio no lo aprueba. Aprueba un humano.
