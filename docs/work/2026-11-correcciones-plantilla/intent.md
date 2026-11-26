# Intención: correcciones pendientes de la plantilla

**Aprobado por:** el usuario de la sesión, por petición explícita en el chat (2026-11-26): "Puedes hacer esto: arreglos en la plantilla: pruebas de vendor-skills.sh, la ruta relativa de EGM y headroom-ai sin versión fija".

## Origen
Hallazgos de la revisión automática (CodeRabbit) sobre dos proyectos que copiaron esta plantilla tal cual y los dejaron como seguimiento aquí.

## Qué se quiere
1. `headroom-ai` se instala con versión exacta (regla de la plantilla: "dependencias nuevas: versión fijada").
2. `scripts/vendor-skills.sh` tiene pruebas pequeñas, sin red, para `copy_skills` y las funciones cercanas.
3. Las rutas de EGM que reescribe el script no dependen del directorio de trabajo donde se inicia la sesión, hasta donde la documentación lo permite.

## Fuera de alcance
Instalar o probar el plugin `egm` y sus revisores registrados (los skills `egm-*` siguen siendo experimentales).
