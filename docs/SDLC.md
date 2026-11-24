# Proceso de desarrollo (AI-native SDLC)

Adaptación del [AI-native SDLC playbook](https://claude.com/blog/the-ai-native-sdlc-playbook) de Anthropic a un equipo de una persona más agentes.

## Idea central

Generar código ya es rápido; planear, revisar y desplegar siguen a velocidad humana. Por eso cada etapa deja un artefacto en git que la siguiente lee, y el humano aprueba en puertas definidas en lugar de revisar línea por línea.

`intent.md` → `spec.md` → `plan.md` → diff y tests → PR con review → registro de incidente

## Capas de control

| Capa | Dónde | Naturaleza |
|---|---|---|
| Contexto | `CLAUDE.md` | Siempre cargado; corto |
| Guía | `.claude/skills/` | Consultiva: el agente puede no seguirla |
| Cumplimiento | hooks en `.claude/settings.json` | Determinista: se ejecuta siempre |
| CI | `.github/workflows/` | Puerta antes de fusionar |

Lo que deba cumplirse siempre va en un hook o en CI, no en un skill.

## Etapas

| Etapa | Agente | Humano (puerta) | Artefacto |
|---|---|---|---|
| 1. Intención | Entrevista y redacta | Aprueba el problema y el resultado esperado | `docs/work/<tarea>/intent.md` |
| 2. Diseño | Redacta la spec, marca conflictos y riesgos; diseños grandes pasan por `/egm-review` | Decide go o no-go | `spec.md` |
| 3. Plan | Lee sin editar y escribe el plan: archivos, orden, riesgos, tests | Acepta el plan; hasta entonces no se edita código | `plan.md` |
| 4. Construcción | Implementa con TDD en una rama | Supervisa; interviene por riesgo | Diff y tests |
| 5. Verificación | Ejecuta el comando de verificación; subagentes `verifier` y `security-reviewer` | Lee el veredicto | Salida de verificación en el PR |
| 6. Entrega | Abre PR en borrador, atiende comentarios de review | Aprueba y fusiona. El agente nunca aprueba su propio PR | PR |
| 7. Mantenimiento | Diagnostica incidentes en solo lectura y propone un nuevo `intent.md` | Decide arreglar, programar o descartar | `docs/incidents/<fecha>.md` |

Atajo permitido: un cambio trivial (typo, una línea, renombre) va directo a la etapa 4 con su PR.

## Reglas

- Bugs: primero un test que falla y reproduce el bug; después el arreglo. No se editan tests para hacerlos pasar.
- Un comando único de verificación por proyecto, que sale distinto de cero si algo falla. Está en `CLAUDE.md`.
- Si el agente repite un error, se añade la corrección a `CLAUDE.md` en una línea.
- Cada incidente en producción añade un test o un eval de regresión.
- Modo automático solo para trabajo rutinario, bien testeado y de bajo impacto.
- Producción: el agente prepara; un humano autoriza.

## Evals (proyectos con comportamiento de modelo)

Un conjunto de 20 a 50 casos reales con criterio de aceptación comprobable, ejecutado en CI y cada vez que cambien prompts, `CLAUDE.md`, skills o hooks.

## Métricas a observar

- Tiempo de `intent.md` a PR fusionado.
- Proporción de PR fusionados sin retrabajo.
- Errores repetidos que `CLAUDE.md` debía evitar.
- CI en verde al primer intento.
- Regresiones detectadas en CI frente a producción.
- Tokens por tarea (`npx ccusage@latest`, `/usage`).

## Lecturas

- [How Anthropic secures its AI-native SDLC](https://claude.com/blog/how-anthropic-secures-its-ai-native-software-development-lifecycle)
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)
- [Claude Code: best practices](https://code.claude.com/docs/en/best-practices) y [costos](https://code.claude.com/docs/en/costs)
