# Setup de ingeniería para Claude Code

Entorno reutilizable para desarrollar con Claude Code en la nube (claude.ai/code) aplicando ingeniería de software: proceso, seguridad, revisión y control del consumo de tokens. Montado y probado el 2026-11-24 con Claude Code 2.1.331.

## Cómo aplicarlo a otro proyecto

```bash
git clone https://github.com/fhersanta/ai-software-dev-template
```

```bash
ai-software-dev-template/scripts/apply-template.sh /ruta/al/otro/repo
```

Después, en el repo destino: completar la sección "Comandos del proyecto" de `CLAUDE.md`, hacer commit y abrir una sesión nueva. Los skills y hooks se cargan al iniciar la sesión, no a mitad de una.

## Por qué los skills van copiados en el repo

Las sesiones cloud no cargan los marketplaces de plugins declarados en el `settings.json` del repo, ni nada de `~/.claude`. Lo que sí viaja en el clon:

- `CLAUDE.md`
- `.claude/skills/`, `.claude/agents/`, `.claude/commands/`, `.claude/rules/`
- hooks y permisos de `.claude/settings.json`
- `.mcp.json`

Esto aplica a sesiones con un único repositorio. Por eso cada skill de terceros se copia desde un commit fijado con `scripts/vendor-skills.sh`. Los commits están en `.claude/vendor/PINS.txt` y las licencias en `.claude/vendor/licenses/`.

## Qué se instala

| Herramienta | Origen (licencia) | Qué aporta | Cómo queda instalada | Cómo se usa |
|---|---|---|---|---|
| superpowers | [obra/superpowers](https://github.com/obra/superpowers) (MIT) | Flujo brainstorm, plan, TDD, depuración sistemática, revisión | 15 skills copiados | Automático por descripción, o por nombre: `brainstorming`, `writing-plans`, `test-driven-development` |
| ponytail | [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) (MIT) | Menos código: la solución más simple que funcione | 6 skills copiados | `/ponytail`, `/ponytail-review`, `/ponytail-audit`, `/ponytail-debt` |
| caveman | [JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman) (Apache-2.0) | Respuestas telegráficas para gastar menos tokens de salida | 5 skills copiados | `/caveman`, `/ultracave`; se apaga con "stop caveman" |
| EGM (Elephant-Goldfish Model) | [google/elephant-goldfish-model](https://github.com/google/elephant-goldfish-model) (Apache-2.0) | Diseño con revisores sin contexto previo que detectan huecos y supuestos | 8 skills copiados, personas y estándares en `.claude/vendor/egm/` | `/egm-brainstorm`, `/egm-draft`, `/egm-review <documento>` |
| LiveKit agent-skills | [livekit/agent-skills](https://github.com/livekit/agent-skills) (MIT) | Construir, probar, depurar y operar agentes de voz | 7 skills copiados | Automático al trabajar con LiveKit |
| LiveKit Docs MCP | `https://docs.livekit.io/mcp` | Documentación actual de LiveKit | `.mcp.json` | El agente lo consulta |
| Context7 | [upstash/context7](https://github.com/upstash/context7) (MIT) | Documentación al día de librerías | `.mcp.json` | El agente lo consulta |
| ccusage | [ryoppippi/ccusage](https://github.com/ryoppippi/ccusage) (MIT) | Reporte de tokens y costo | Sin instalar; se ejecuta con npx | `npx ccusage@latest` |
| Headroom | [headroomlabs-ai/headroom](https://github.com/headroomlabs-ai/headroom) (Apache-2.0) | Proxy que comprime lo que lee el modelo | CLI instalado por el hook de inicio; el proxy queda apagado | Ver "Headroom" abajo |
| security-guidance | Plugin oficial de Anthropic | Revisión de seguridad automática mientras se escribe | El hook de inicio lo instala a nivel proyecto | Automático desde la siguiente sesión |
| `/security-review` | Nativo de Claude Code | Pasada de seguridad sobre la rama | Ya incluido | Antes de cada PR |
| Revisión de seguridad en PR | [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review) (MIT) | Comentarios de seguridad en cada PR | `.github/workflows/security-review.yml` | Requiere el secreto `CLAUDE_API_KEY` en el repo |
| gitleaks | [gitleaks](https://github.com/gitleaks/gitleaks) (MIT) | Detecta secretos en commits | `.github/workflows/secrets-scan.yml` | Automático en CI |

Además, propios de esta plantilla:

- Hook `scripts/hooks/protect-secrets.sh`: bloquea escribir `.env`, llaves y contenido con forma de credencial.
- Subagentes `researcher` (Haiku), `verifier` y `security-reviewer` (Sonnet) para delegar con modelos más baratos.
- `docs/SDLC.md`, plantillas `intent.md`, `spec.md`, `plan.md` y `REVIEW.md`.

## Decisiones y límites conocidos

**Costo fijo en contexto.** Las descripciones de los 41 skills suman unos 3,600 tokens por sesión (medido sobre los encabezados). El cuerpo de cada skill solo se carga al usarlo.

**Hooks de terceros no copiados.** Se leyeron antes de instalar y se dejaron fuera a propósito:

- superpowers: su hook inyecta el skill `using-superpowers` completo en cada sesión. Se sustituye por la sección "Skills" de `CLAUDE.md`, más barata.
- ponytail: tres hooks Node que se ejecutan en cada inicio, cada subagente y cada mensaje, y lanzan un proceso en segundo plano. Ponytail se activa a mano con `/ponytail`.
- caveman: solo se copian los skills de voz. Quedan fuera su proxy, su motor, su MCP y su telemetría.

**Referencias con prefijo.** Dentro de los textos de superpowers los skills se nombran `superpowers:nombre`. Copiados al repo se llaman solo `nombre`.

**EGM.** Sus skills tienen la invocación automática desactivada: se llaman por comando. Cada revisor es un subagente nuevo, así que una revisión completa consume bastantes tokens; úsalo en diseños que lo ameriten. El propio proyecto indica que el soporte en nube es parcial.

**Headroom.** Funciona envolviendo el arranque de Claude (`headroom wrap claude`). En la nube la plataforma arranca Claude, así que no hay forma de envolver la sesión en curso: aquí Headroom no reduce tokens. El CLI queda instalado (versión 0.45.0 probada) para usarlo en una máquina propia:

```bash
headroom wrap claude
```

**Plugin security-guidance.** Se comprobó que `claude plugin marketplace add anthropics/claude-plugins-official` y `claude plugin install security-guidance@claude-plugins-official --scope project` funcionan en una sesión cloud. Como el hook corre al iniciar, el plugin queda activo en la sesión siguiente del mismo contenedor o tras `/reload-plugins`. Sus revisiones usan Opus por defecto y suman consumo; se ajusta con `SECURITY_REVIEW_MODEL`.

**gitleaks local.** La descarga del binario está bloqueada por la red de la sesión cloud. Corre solo en CI; en la sesión protege el hook de secretos.

**Telemetría.** `DO_NOT_TRACK=1` está definido en `.claude/settings.json` y en el hook de inicio.

**Red.** Para los MCP hay que permitir `docs.livekit.io` y `mcp.context7.com` en el entorno cloud si usa una lista de hosts restringida.

## Cómo medir si ahorra

1. `npx ccusage@latest` para ver tokens y costo por sesión y por día.
2. `/usage` dentro de Claude Code para ver el reparto por skill, subagente y plugin.
3. Comparar la misma tarea con y sin `/caveman` o `/ponytail`. Las cifras de ahorro que publican sus autores no están verificadas por terceros.

## Actualizar un skill de terceros

1. Cambiar el commit en `scripts/vendor-skills.sh`.
2. Leer en el upstream el diff de `skills/`, `hooks/` y cualquier script nuevo.
3. Ejecutar `scripts/vendor-skills.sh` y revisar `git diff`.

## Opcionales no instalados

| Herramienta | Para qué | Por qué no está por defecto |
|---|---|---|
| [Trail of Bits skills](https://github.com/trailofbits/skills): `differential-review`, `insecure-defaults`, `supply-chain-risk-auditor` | Auditoría de seguridad a fondo | Licencia CC-BY-SA: copiarla obliga a compartir igual |
| Plugin Claude Security | Escaneo multiagente con parches | Consumo alto de tokens |
| Semgrep | Análisis estático | Requiere cuenta e inicio de sesión |
| Plugins LSP | Menos lecturas de archivos en lenguajes tipados | Depende del lenguaje del proyecto |
| [Cloudflare skills](https://github.com/cloudflare/skills) | Workers, Durable Objects, wrangler | Solo si el proyecto usa Cloudflare |

## Verificación realizada

| Comprobación | Resultado |
|---|---|
| `scripts/vendor-skills.sh` copia 41 skills desde commits fijados | Correcto |
| Hook de secretos bloquea `.env` y una clave con forma `sk-ant-…`; permite código normal y `.env.example` | Correcto |
| Instalación de Headroom con uv | Correcto, unos 5 segundos |
| Instalación del plugin security-guidance por línea de comandos | Correcto |
| `mcp.context7.com` y `docs.livekit.io` responden desde la sesión | Responden; el uso desde el agente falta probarlo en una sesión nueva |
| Skills, hooks y MCP cargados en una sesión nueva sobre el repo | Pendiente: requiere abrir una sesión nueva |
| Workflows de CI | Pendiente: corren al abrir el primer PR; el de revisión requiere `CLAUDE_API_KEY` |

El detalle de la investigación está en `docs/research/engineering-setup.md`.
