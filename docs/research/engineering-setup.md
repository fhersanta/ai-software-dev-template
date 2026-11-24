# Investigación: entorno de ingeniería para Claude Code

Fecha: 2026-11-24. Fuentes: READMEs de GitHub, documentación oficial de Claude Code y blog de Anthropic. Lo que no se pudo abrir va marcado como no verificado. Las cifras de beneficio son de los propios autores salvo indicación contraria.

## Resolución de nombres dictados

| Dictado | Resolución | Confianza |
|---|---|---|
| superpowers | obra/superpowers (Jesse Vincent) | Alta |
| caveman | JuliusBrussee/caveman | Alta |
| ponytail | DietrichGebert/ponytail | Alta |
| "elephant golden fish" de Google | Elephant-Goldfish Model, `google/elephant-goldfish-model` | Alta |
| "headcount" | No existe un skill con ese nombre. Candidatos: Headroom, Context7, ccusage. Se instalaron los tres | Media |
| "audit security" | Conjunto: `security-guidance`, `/security-review`, Action de revisión, gitleaks | Alta |

## Cómo carga Claude Code en la nube

- No añade los marketplaces de `extraKnownMarketplaces` del repo: requieren un diálogo de confianza que la sesión no muestra.
- Sí carga del clon: `CLAUDE.md`, `.claude/skills|agents|commands|rules`, hooks y permisos de `.claude/settings.json`, `.mcp.json`. Solo en sesiones de un único repositorio.
- Nada de `~/.claude` (nivel usuario) existe en la nube.
- Hook `SessionStart`: corre en cada inicio y reanudación; límite por defecto 600 s. `CLAUDE_CODE_REMOTE=true` identifica la nube.
- `claude plugin marketplace add` y `claude plugin install --scope project` funcionan desde un script (comprobado en esta sesión).
- Un plugin puede ejecutar código con tus privilegios (hooks, MCP, `bin/`). Los permisos cubren las herramientas de Claude, no lo que el plugin ejecuta por su cuenta.

## Herramientas

### superpowers

- 15 skills: `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `dispatching-parallel-agents`, `using-git-worktrees`, `finishing-a-development-branch`, `writing-skills`, `using-superpowers`, `diagnosing-superpowers`.
- Flujo: preguntas y documento de diseño; plan en tareas de 2 a 5 minutos con rutas exactas; un subagente por tarea con revisión; TDD rojo, verde, refactor; revisión con severidades.
- Único hook: `SessionStart`, que inyecta `using-superpowers` completo. Leído: solo lee un archivo y lo imprime.

### caveman

- Skill de voz telegráfica más un proxy local y un motor opcionales.
- Niveles: `/caveman`, `/ultracave`, `/megacave` (chino clásico).
- Datos del autor: frente a pedir "responde conciso", `/caveman` ahorró 3 % más y `/ultracave` 35 % en 10 preguntas. Las reglas cuestan unos 1,160 tokens de entrada por petición.
- El CLI envía telemetría anónima salvo `DO_NOT_TRACK=1`.

### ponytail

- Hace que el agente escriba menos código: YAGNI, biblioteca estándar primero.
- Comandos: `/ponytail`, `/ponytail-review`, `/ponytail-audit`, `/ponytail-debt`, `/ponytail-gain`, `/ponytail-help`.
- Hooks Node en `SessionStart`, `SubagentStart` y `UserPromptSubmit`; uno lanza un proceso desacoplado que importa estadísticas de uso. Guarda datos en `~/.config/ponytail/`.
- Datos del autor: 53 % menos líneas y 45 % menos tokens en 39 tareas. Sin verificación externa.
- Existen copias con el mismo nombre; instalar solo desde el repo oficial.

### Elephant-Goldfish Model (EGM)

- Un "elefante" conserva el contexto y redacta el diseño; los "goldfish" lo revisan sin ver la conversación. El humano decide qué hallazgos atender.
- Skills: `egm-brainstorm`, `egm-draft`, `egm-review`, `egm-review-loop`, `egm-resolve`, `egm-lite`, `egm-bootstrap`, `egm-drift-report`. Diez personas de revisión en `agents/`.
- Requiere Claude Code 2.1.271 o posterior. No tiene hooks. "No es un producto oficialmente soportado por Google"; soporte en nube parcial.

### Headroom

- Proxy local que comprime la salida de herramientas, con originales recuperables. El proyecto declara 60 a 95 % de reducción; un análisis externo, 15 a 81 % en sesiones largas.
- Riesgos que reconoce: un proxy mal configurado afecta todas las peticiones; `headroom learn` puede escribir en `CLAUDE.md`; telemetría por defecto.
- Se activa envolviendo el arranque de Claude, lo que no es posible en una sesión cloud ya iniciada.

### Seguridad

- Plugin `security-guidance`: hooks en `SessionStart`, `UserPromptSubmit`, `PostToolUse` y `Stop`; revisión al hacer commit y push. Modelos de revisión en Opus por defecto. No bloquea escrituras: es una capa, no una garantía.
- Action `claude-code-security-review`: no resiste prompt injection; usar solo en PR de confianza.
- Trail of Bits: unos 40 skills de auditoría, licencia CC-BY-SA-4.0.
- gitleaks o trufflehog en CI para secretos.

### Otras

- LiveKit `agent-skills`: 7 skills y MCP de documentación. Instalar por un solo método; Claude Code no deduplica.
- Context7: documentación de librerías; el contenido lo aportan terceros.
- ccusage: reportes desde los logs locales; ping de telemetría desactivable.
- Cloudflare skills: 22 skills y un MCP con acceso a la API de Cloudflare.

## Eficiencia de tokens (documentación oficial de costos)

- Los skills cargan bajo demanda; `CLAUDE.md` se carga siempre. Mantenerlo por debajo de unas 200 líneas.
- `claude plugin details <nombre>` muestra el costo fijo de un plugin.
- Subagentes simples con `model: haiku`; Sonnet para la mayoría; Opus para arquitectura.
- Las CLI (`gh`) cuestan menos contexto que un MCP equivalente.
- Filtrar salidas largas con hooks o con `tail` y `grep`.
- Los equipos de agentes gastan unas 7 veces más que una sesión normal.

## AI-native SDLC playbook (Anthropic)

Fuente: <https://claude.com/blog/the-ai-native-sdlc-playbook>. Resumen aplicado en `docs/SDLC.md`.

- Tesis: el cuello de botella pasó de escribir código a planear, revisar y desplegar. Cada etapa deja un artefacto en git y el humano aprueba en puertas.
- Cadena: `intent.md` → `spec.md` → `plan.md` → diff y tests → PR con hallazgos → registro de incidente.
- Capas: `CLAUDE.md` (contexto), skills (guía consultiva), hooks (cumplimiento determinista), managed settings (controles de organización).
- Plan: el originador conversa y se produce `intent.md`.
- Design: `spec.md` aplicando políticas; el go o no-go es humano.
- Build: modo plan por defecto; `CLAUDE.md` de menos de una página; si un error se repite, se añade la corrección; hooks como guardarraíles; subagentes con herramientas acotadas.
- Test: un comando único que falle con código distinto de cero; en bugs, primero el test que falla; evals de 20 a 50 tareas reales en CI.
- Deploy: review con IA en tres pasadas (bugs, seguridad, cumplimiento); `REVIEW.md` define severidades; el agente que escribe no aprueba; producción exige autorización humana.
- Maintain: monitoreo determinista por niveles; el diagnóstico vuelve como un nuevo `intent.md`; cada incidente añade un eval de regresión.

Relacionados: [seguridad del SDLC en Anthropic](https://claude.com/blog/how-anthropic-secures-its-ai-native-software-development-lifecycle), [context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents), [building effective agents](https://www.anthropic.com/engineering/building-effective-agents).

## No verificado

- Blog de Google Open Source sobre EGM (host inaccesible).
- PDF del playbook; se usó la versión web.
- Cifras de ahorro de caveman, ponytail y Headroom.
- Configuración de Semgrep y el repo `OWASP/secure-agent-playbook`.
