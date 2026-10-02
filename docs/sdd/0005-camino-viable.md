# SDD 0005 — El camino viable: cómo construimos el SDD 0004 en 12 días

| | |
|---|---|
| Estado | **Aprobado**, 2026-10-02 |
| Qué es | El plan de ejecución del SDD 0004. El **qué** (modelos, endpoints, reglas) está en el 0004; acá está el **cómo, en qué orden y qué se corta primero** |
| Entrega | 14/10/2026 23:59, sin prórroga |
| Equipo | Una persona del equipo + Claude, un PR por módulo |

---

## 1. Lo que se decidió (2026-10-02)

| # | Pregunta | Respuesta | Consecuencia |
|---|---|---|---|
| V1 | ¿Dónde se ve la demo? | **Web + un teléfono** | El jurado usa la web. El teléfono hace de host del vivo con cámara real |
| V2 | ¿Video del vivo? | **Agora ya, de la forma más simple** | Ver §3 |
| V3 | ¿Deploy? | **Sin deploy: demo local** | El jurado corre el proyecto con el README. Ver §4 |
| V4 | ¿Alcance? | **Todo el SDD 0004** | Entra todo, pero en orden de valor y con líneas de corte explícitas (§5). Si el tiempo se acaba, se corta desde abajo y lo que quedó funciona completo |

### Lo que implica V3 (no desplegar)

"¿Funciona?" pesa 30% y el jurado no va a poder abrir un link. Con eso, la
**prueba de que funciona son dos cosas**: el video de la demo y que el
proyecto **arranque con un comando** en una máquina limpia. Por eso §4 deja
de ser un detalle y pasa a ser un módulo con su propio tiempo.

Si aparece una cuenta de Serverpod Cloud antes del día 10, el deploy se suma
en medio día (SDD 0004, M8). El plan no depende de eso.

---

## 2. Principio: cada día termina en algo que funciona

Con todo el alcance del 0004 en 12 días, el riesgo no es que falte una
funcionalidad: es **llegar al 14 con todo a medias**. Por eso:

1. **Orden por valor para la demo**, no por capa. Primero lo que aparece en el video.
2. **Cada módulo se cierra entero** —backend, app, tests y retiro de su parte del mock— antes de abrir el siguiente.
3. **Líneas de corte** (§5): al cruzar cada una, lo que hay ya es una demo completa.
4. **Nada nuevo después del día 10.** Los días 11 y 12 son para probar, grabar y entregar.

---

## 3. Video con Agora: la versión más simple que funciona

| Etapa | Qué | Cuándo | Necesita |
|---|---|---|---|
| A — Prueba técnica | La app une al host (teléfono) y a la audiencia (web) en un canal de Agora en **modo de prueba**: sólo App ID, sin certificado ni token | Día 1 | **App ID** de un proyecto de Agora en modo "APP ID" (5 minutos en la consola, gratis) |
| B — Token del servidor | `live.mediaToken(showId)` emite el token AccessToken2 **sólo si el rol lo permite** (host o invitado = publicador; resto = audiencia). El certificado vive en los secretos del servidor | Con M4 | **App Certificate** del mismo proyecto, que pasa a modo "token" |

- **Por qué en dos etapas:** la etapa A responde en un día si Agora anda en web y en el teléfono, sin depender del backend. La B es la que respeta la tesis del producto ("el cliente nunca decide ser publicador") y suma al criterio de Serverpod.
- **Riesgo aceptado en la etapa A:** en modo de prueba, cualquiera con el App ID puede entrar al canal. Sirve sólo para la prueba técnica; la demo se graba con la etapa B.
- **Si la etapa A falla en web** (el SDK de Agora para Flutter web está en alfa): la audiencia en web ve el video simulado de hoy y el teléfono sigue transmitiendo. Ver el vivo desde un segundo teléfono queda como respaldo para el video de la demo. El resto del vivo —chat, espectadores, estados, permisos— no depende del video.
- **Arquitectura:** `LiveMediaEngine` en `core/media/`, con dos implementaciones: `AgoraLiveMediaEngine` y `SimulatedLiveMediaEngine` (el degradé actual). La elige `injection.dart` según `AGORA_APP_ID`. Las pantallas no saben cuál es.

---

## 4. Demo local en un comando (reemplaza al deploy)

| Qué | Cómo |
|---|---|
| Base de datos sin Docker | `development.yaml` usa `database.dataPath`, igual que los tests: Serverpod levanta un PostgreSQL embebido. El jurado no instala nada más que Flutter |
| Arranque | `tool/demo.sh`: genera, aplica migraciones, siembra los datos (D13 del 0004) y levanta el servidor y la app web |
| Datos de demo | Comando de seed idempotente: `operador` (admin), `moderador`, `elena` (creadora verificada), `tomas`, `troll`, con posts y un show programado |
| Correos de verificación | En desarrollo, Serverpod los imprime en la consola del servidor; el README lo dice. Las cuentas sembradas no necesitan verificarse |
| Teléfono como host | `flutter run -d <android>` con `--dart-define=API_BASE_URL=http://<ip-de-la-máquina>:8080/` |
| Trampa conocida | **Ruta con espacios:** el PostgreSQL embebido falla. El README pide clonar en una ruta sin espacios (`git clone` por defecto no tiene espacios) |

**Prueba de aceptación:** una persona que no conoce el código clona el repo
en otra máquina y llega a la pantalla de login con las cuentas demo,
siguiendo sólo el README.

---

## 5. Orden y líneas de corte

Las estimaciones son en días de trabajo.

| # | Días | Módulo (SDD 0004) | Qué cierra |
|---|---|---|---|
| 1 | 0,5 | Merge del PR #2 + **etapa A de Agora** | Identidad real; sabemos si Agora anda |
| 2 | 1 | **Demo local** (§4): base embebida, seed, `tool/demo.sh` | Cualquiera arranca el proyecto |
| 3 | 1,5 | **M3** Publicaciones en la app | Subir foto y video, likes, comentarios, reportes, editar y borrar, contra el servidor |
| 4 | 2,5 | **M4** Vivos + **etapa B de Agora** | Programar, iniciar con gate de verificación, chat y espectadores en tiempo real, token del servidor, terminar |
| 5 | 1,5 | **M6** Sanciones y consola | Suspender con expulsión en el acto, verificar, auditoría legible, decisiones de moderación |
| | | **— LÍNEA DE CORTE 1 (día 7) —** | **El recorrido completo de la demo funciona contra Serverpod** |
| 6 | 1 | **M7** Retiro del mock + `AUTH_SOURCE=serverpod` | Una sola fuente de verdad |
| 7 | 1 | **M5** Future Calls + notificaciones | Aviso 15 minutos antes, show sin host cancelado, replay publicado solo, bandeja en vivo |
| | | **— LÍNEA DE CORTE 2 (día 9) —** | **Demo completa, sin mock, con las piezas de stack que suman a la nota** |
| 8 | 1,5 | **M2** Seguir y feed por secciones | El feed que planeó el equipo |
| 9 | 0,5 | **M1** Avatar y editar perfil | |
| | | **— LÍNEA DE CORTE 3 (día 11) —** | **Todo el SDD 0004** |
| 10 | 1 | Prueba en una máquina limpia, README, video, descripción, post en redes | Entrega |

**Suma: 12 días exactos, sin colchón.** Es lo que significa elegir "todo el
SDD 0004". Por eso las líneas de corte no son opcionales: si el día 9 se
llega sin cruzar la línea 2, M2 y M1 salen del alcance y se cuentan en el
pitch. **La entrega (fila 10) no se corta nunca.**

---

## 6. Lo que necesitamos de una persona del equipo

| Qué | Para qué | Cuándo |
|---|---|---|
| **App ID de Agora** (proyecto en modo "APP ID", sin certificado) | Etapa A | **Hoy** |
| **App Certificate** del mismo proyecto | Etapa B | Día 4 |
| **Autorizar el Android conectado** (aceptar la depuración USB) | El teléfono como host | Hoy |
| Levantar el servidor con `serverpod start` cuando se pida | Las reglas del repo dicen que lo levanta una persona | Desde el día 2 |
| Revisar y mergear cada PR | El equipo ve lo que entra | Cada módulo |

---

## 7. Qué se mide al final de cada día

- `flutter analyze` sin issues y `flutter test` en verde (app).
- `dart analyze` sin issues y `dart test` en verde (backend, desde una ruta sin espacios).
- **El recorrido de la demo hasta donde llegue el módulo**, probado a mano en web y en el teléfono.
- Un PR abierto con lo que se hizo y cómo probarlo.
