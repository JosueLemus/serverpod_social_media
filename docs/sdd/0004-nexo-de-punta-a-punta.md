# SDD 0004 — Nexo de punta a punta: de mock a producto real

| | |
|---|---|
| Estado | **Aprobado para construir**, 2026-10-02. Decisiones de Q1 a Q5 cerradas (§12) |
| Fecha | 2026-10-02 |
| Plazo | Entrega de la hackathon: **14/10/2026 23:59**, sin prórroga (12 días) |
| Depende de | SDD 0001 (consola), 0002 (`content`), 0003 (`social` y `moderation`), PR #2 (`identity`) |
| Alcance | Todo lo que falta para que el recorrido de la demo funcione contra Serverpod, sin mocks, desplegado y abierto al jurado |

---

## 1. Objetivo

Que **cada pantalla del recorrido de la demo hable con Serverpod**, que el
servidor sea quien decide permisos y estados, y que el jurado lo pueda abrir
desde un link.

El recorrido:
1. Un creador publica una foto o un video.
2. Programa un show e inicia el vivo.
3. Un espectador comenta y otro lo reporta.
4. Un moderador oculta el comentario y lo ve desaparecer para todos.
5. El vivo termina y queda como replay.

Las bases de la hackathon lo piden con esas palabras: *"una app full-stack
funcional con backend Serverpod"*. "¿Funciona?" (30%) y "Uso del stack de
Serverpod" (25%) suman el 55% de la nota.

### No-objetivos

- **Cobro real.** Las membresías siguen simuladas y la pantalla lo dice.
- **IA**, gamificación, mensajes directos y cursos.
- **Video de calidad producción.** El vivo usa Agora (D9) sin grabación de
  video en la nube: el replay es la ficha del vivo con su chat.
- **Ranking por aprendizaje automático.** El feed es determinístico (D6).

---

## 2. Auditoría: dónde estamos (2026-10-02)

### Backend (`services/serverpod`, `main` + PR #2)

| Módulo | Estado | Notas |
|---|---|---|
| Auth (email, registro con código, recuperar contraseña, JWT) | ✅ Real | `EmailIdp`, `JwtRefresh` |
| `identity` (perfil, username único, creador, verificación, estado) | ✅ En PR #2 | `profiles.me/update/becomeCreator/byUsername` |
| `content` (posts con foto o video) | ✅ Real | Subida directa a Cloud Storage, borrado lógico, límites del servidor |
| `social` (likes, comentarios) | ✅ Real | Contadores con lock, permisos de autor o staff |
| `moderation` (reportar, cola, resolver) | ✅ Real | Auditado, sin duplicados (PR #2) |
| Seguir creadores | ❌ | No hay grafo de seguidores |
| Feed (seguidos, sugeridos, intereses) | ❌ | Sólo cronológico |
| Vivos (programar, estados, chat, espectadores, replay) | ❌ | Sólo la interfaz `LiveMediaGateway` |
| Notificaciones | ❌ | |
| Consola de operador (sanciones, verificar, auditoría legible) | ❌ | Los scopes existen, los endpoints no |
| Tiempo real (Streaming Methods) | ❌ | No se usa |
| Tareas programadas (Future Calls) | ❌ | Comentadas en la configuración |
| Deploy | ❌ | Las configuraciones de staging y producción tienen `examplepod.com`; no hay configuración de Serverpod Cloud |
| Tests | ✅ 89 | Integración contra PostgreSQL embebido |

### App (`apps/nexo_social`)

| Feature | Fuente hoy | Notas |
|---|---|---|
| Login y registro | Real con `AUTH_SOURCE=serverpod`; **mock por defecto** | El default no puede cambiar hasta que vivos, moderación y consola tengan backend |
| Feed y publicaciones | ❌ Mock (`MockSocialStore`) | No hay selector de imagen ni video, el botón de comentar no hace nada, el like es local |
| Vivos, studio, programar show | ❌ Mock (`MockPlatform`) | El studio carga siempre `live-2`; el video es un degradé |
| Moderación y consola | ❌ Mock (`MockPlatform`) | |
| Perfil, explorar, actividad, suscripciones | ❌ Mock | Contenido de Elena fijo |
| Tests | ✅ 211 | |

**El mayor riesgo:** la app tiene dos fuentes de sesión, `MockPlatform` y
Serverpod, y las pantallas de vivos, moderación y consola sólo conocen la
primera. Mientras eso exista, prender el login real rompe esas pantallas.
Por eso cada módulo de este SDD termina **retirando su parte del mock**.

---

## 3. Benchmark: qué necesita una plataforma "de verdad"

Lo que tiene cualquier plataforma de vivos o creadores (Twitch, YouTube Live,
TikTok LIVE, Patreon, Kick, Substack) que es **infraestructura, no feature**.
Es lo que hace que algo funcione y no sólo se vea.

| Capacidad | Cómo lo resuelven ellos | Nexo hoy | Para la hackathon |
|---|---|---|---|
| Identidad con perfil público | Username único, avatar, verificado | ✅ PR #2 (falta avatar) | Sumar avatar (M1) |
| Subir fotos y videos | Subida directa al storage, transcodificación a HLS, miniaturas | Backend ✅; la app no sube | Subida directa y reproducción del MP4 original. **Sin transcodificar** (D7) |
| Grafo social | Seguir y dejar de seguir, contadores | ❌ | M2 |
| Feed | Ranking por afinidad y recencia, con secciones | ❌ | Secciones determinísticas en el servidor (D6) |
| Chat en vivo | WebSocket con fan-out entre servidores (pub/sub) | ❌ | Streaming Methods (M4); ver R1 sobre instancias |
| Presencia y espectadores | Conteo en tiempo real | ❌ | M4 |
| Video en vivo | WebRTC o RTMP→HLS con un proveedor (Agora, LiveKit, Mux, IVS) | ❌ | D9 |
| Vivos programados con aviso | Calendario y notificación antes de empezar | Sólo la pantalla | Future Call 15 min antes (M5) |
| Replay | La grabación se publica sola | ❌ | Estado `recorded` → `published` con Future Call (M5). Sin video real, el replay es la ficha del vivo con su chat |
| Notificaciones | Push + bandeja dentro de la app | ❌ | Bandeja dentro de la app en tiempo real (M5); push queda fuera (D10) |
| Moderación | Reportes, cola, acciones, AutoMod | ✅ Backend | Conectar en la app (M3, M6) |
| Sanciones de cuenta | Suspender o banear con efecto inmediato | ❌ | M6, con expulsión en tiempo real |
| Auditoría | Registro interno (Discord lo muestra) | ✅ Se escribe; no se lee | Endpoint de lectura con DTO propio (M6) |
| Límite de frecuencia | Por cuenta y por IP | ❌ (`rateLimited` existe pero no se usa) | Límite simple en comentar, reportar y chatear (M4) |
| Observabilidad | Métricas y logs | Insights de Serverpod, sin configurar | Activarlo en Cloud (M8) |
| Deploy | Varios entornos, CI/CD | Hay CI de tests; no hay deploy | Serverpod Cloud (M8) |

### ¿Hace falta una VM o algo más?

**No hace falta una VM.** Serverpod Cloud da servidor, PostgreSQL, buckets
de storage, pub/sub y caché, secretos y el envío de los emails de
verificación. Lo único externo posible es **el video en vivo** (D9).
Opcionalmente, Firebase para push, que queda fuera del alcance (D10).

---

## 4. Decisiones

| # | Decisión | Por qué |
|---|---|---|
| D1 | **Un módulo de backend nuevo por dominio**: `social` suma seguidores, `live` es nuevo, `notifications` es nuevo, `identity` suma sanciones | Respeta la convención `modules/<módulo>/{models,services,endpoints}` del AGENTS.md |
| D2 | **Cada módulo retira su parte de `MockPlatform`** en la misma entrega | Dos fuentes de verdad para lo mismo son el bug de la auditoría. `MockPlatform` queda sólo para los tests de widgets |
| D3 | `AUTH_SOURCE` pasa a `serverpod` por defecto **cuando M3, M4 y M6 estén conectados** | Antes, prenderlo rompe esas pantallas |
| D4 | Toda escritura de una cuenta suspendida o baneada responde `forbidden` con código `accountSuspended` | La regla del SDD 0001: la sanción la aplica el servidor, no la pantalla |
| D5 | Iniciar un vivo exige ser **host, creador, verificado y activo** | El gate del SDD 0001, ahora en el servidor |
| D6 | **Feed por secciones, armado en el servidor**: vivos ahora → seguidos → cuentas sugeridas → descubrir (por etiquetas en común) | Es el plan del equipo. Determinístico: se puede testear y explicar en el video |
| D7 | Video de posts: **MP4/MOV/WebM tal cual, hasta 50 MB, sin transcodificar** | Transcodificar exige otro servicio. Los límites ya están en `MediaPolicy` |
| D8 | El chat del vivo viaja por **Streaming Methods**; los mensajes también se guardan en la base | Tiempo real para quien está mirando; persistencia para moderar, auditar y armar el replay |
| D9 | **Video en vivo con Agora**, detrás de `LiveMediaGateway`. El token lo emite **sólo el servidor**, después de validar el rol: host = publicador; invitado aprobado = publicador; audiencia = suscriptor. **Primero una prueba técnica** (§7, paso 2): si en dos días Agora no anda en el destino de la demo, el video queda simulado detrás de la misma interfaz y nada más cambia | Q1. El SDK de Agora para Flutter web está en **alfa** (sólo probado en web de escritorio, con APIs faltantes) y hoy web es la única plataforma que compila en esta máquina. La prueba técnica acota ese riesgo antes de construir encima |
| D10 | Notificaciones **sólo dentro de la app**, en tiempo real. Push queda fuera | FCM exige configurar Firebase por plataforma y no suma al criterio de Serverpod |
| D11 | Un show programado **no arranca solo**: arranca el host. Un Future Call avisa 15 minutos antes y otro lo cancela si pasó 30 minutos sin empezar | Arrancar solo un vivo sin el host al aire es una sala vacía |
| D12 | **Una sola instancia en Serverpod Cloud** para la demo, o pub/sub activo (ver R1) | Sin Redis, `postMessage` sólo llega a la misma instancia |
| D14 | **Ser creador es autoservicio; verificar es del operador** | Q3. Como en el PR #2: sin verificación no se inicia un vivo (D5) |
| D15 | **El modo mock se retira del runtime** en M7; queda sólo para tests | Q5. Una sola fuente de verdad. Es lo que mide "¿Funciona?" |
| D13 | Datos semilla con un **comando de seed idempotente** en el servidor (cuentas demo con sus scopes, creadora verificada, posts, un show) | El jurado entra con cuentas listas; nadie concede el scope `admin` a mano |

---

## 5. Módulos a construir

Cada módulo trae backend, app, tests y el retiro de su parte del mock.

### M1 — Avatar y perfil en la app (identity, completa el PR #2)
- **Backend:** `profiles.requestAvatarUpload` / `setAvatar`, con el mismo patrón de subida directa que `posts`.
- **App:** pantalla "Editar perfil" (username, nombre, bio, avatar) y botón "Ser creador". El perfil propio y el ajeno leen de `profiles`.

### M2 — Seguir y feed (social)
- **Modelo:** `Follow` (tabla `follow`), con `followerId`, `followeeId`, `createdAt`, índice único `(followerId, followeeId)` e índice por `followeeId`. Contadores `followerCount` y `followingCount` desnormalizados en `account_profile`, actualizados con lock como los likes.
- **Endpoints:**
  - `follows.follow(userId)` / `unfollow(userId)`: idempotentes.
  - `follows.followers(userId, {after})` / `following(userId, {after})`.
  - `follows.suggestions({limit})`: creadores verificados que no seguís, ordenados por cantidad de seguidores.
- **Feed nuevo:** `feed.home({cursor})` devuelve `HomeFeedPage { sections: List<FeedSection> }`:
  - `FeedSection.kind`: `liveNow`, `following`, `suggestedAccounts` o `discover`.
  - `FeedItem` con `kind`: `imagePost`, `videoPost`, `scheduledShow`, `liveShow` o `recordedShow`, y el payload que corresponda (`PostView` o `LiveShowView`).
  - La primera página trae todas las secciones; las siguientes, sólo `following` y luego `discover`, con cursor.
  - `discover` = posts públicos de no seguidos que comparten etiquetas con lo que likeaste en los últimos 30 días; si no hay, los más recientes.
- **Visibilidad `followers`:** se abre (el SDD 0002 la dejó cerrada hasta que existiera el grafo).
- **App:**
  - `FeedItem` sellado en el dominio.
  - El feed dibuja por sección; la fila de cuentas sugeridas es horizontal.
  - Botón Seguir en el perfil.
  - Retira `MockSocialStore` del runtime.

### M3 — Publicaciones en la app (content, social y moderation en el cliente)
- **App:**
  - Repositorios `Serverpod…` para posts, likes, comentarios y reportes.
  - `image_picker` para foto y video, con subida usando `FileUploader(ticket.uploadDescription)`.
  - `video_player` en la tarjeta.
  - Hoja de comentarios: listar, comentar y borrar (autor del comentario, autor del post o staff, según `canDelete`).
  - Lista de quién dio like.
  - Menú "…": editar, eliminar o reportar, según `canEdit` y `canDelete`.
- **Errores:** `NexoErrorCode` → `Failure` en un mapper único de `core/errors`.

### M4 — Vivos (módulo `live`, nuevo)
- **Modelos:**
  - `LiveShow` (tabla `live_show`): hostId, title, description, startsAt, durationMinutes, access (`public`/`members`), allowQuestions, recordReplay, status, startedAt, endedAt, endedBy, viewerPeak.
  - `LiveShowGuest`: showId, userId, estado de la invitación.
  - `LiveChatMessage` (tabla `live_chat_message`): showId, authorId, body, createdAt, hiddenAt, hiddenBy.
  - DTOs `LiveShowView`, `LiveChatEvent` (mensaje nuevo, mensaje oculto, espectadores, cambio de estado, expulsión).
- **Máquina de estados en el servidor:** la del SDD 0001 (`draft → scheduled → live → ending → recorded → published`, más `cancelled`, `failed` y `removed`). Una transición ilegal responde `conflict`.
- **Endpoints `live`:**
  - `schedule(LiveShowDraft)`: reemplaza `MockShowScheduleRepository`.
  - `start(showId)`: D5.
  - `end(showId)`, `get(showId)`, `upcoming()` y `byHost()`.
  - `chatHistory(showId, {after})` y `sendChat(showId, body)`: valida que la cuenta no esté silenciada ni suspendida, con un límite de 1 mensaje por segundo por cuenta.
  - `hideChat(messageId)`: host o staff, auditado.
  - **`watch(showId) → Stream<LiveChatEvent>`** (Streaming Method): al conectarse suma un espectador y al cerrar resta uno. Recibe por `session.messages.createStream('live:$showId')`.
- **Video (D9):**
  - `live.mediaToken(showId)` devuelve `{appId, channel, uid, token, role, expiresAt}`. El servidor decide el rol; el cliente nunca pide ser publicador.
  - `AgoraLiveMediaGateway` arma el token AccessToken2 (007) con el App ID y el App Certificate guardados en los secretos de Serverpod. **El certificado nunca sale del servidor.**
  - Generación del token: el paquete `agora_token_generator` si pasa la revisión de la prueba técnica; si no, una implementación propia del algoritmo (HMAC-SHA256 + empaquetado), con tests contra los vectores de ejemplo de Agora.
  - `FakeLiveMediaGateway` para tests y como respaldo si la prueba técnica falla.
  - **App:** `agora_rtc_engine`. El host publica cámara y micrófono; la audiencia sólo se suscribe. Al terminar el vivo, la app sale del canal y el servidor deja de emitir tokens para ese show.
- **App:**
  - `LiveRepository` sobre Serverpod.
  - La sala y el studio leen el stream.
  - Programar show llama a `live.schedule`.
  - Retira de `MockPlatform` los vivos y el chat.

### M5 — Tareas programadas y notificaciones (`live` + `notifications`)
- **Future Calls:**
  - `ShowReminderCall` (15 min antes): crea notificaciones para los seguidores del host.
  - `ShowNoShowCall` (+30 min): `scheduled → cancelled` si no arrancó.
  - `ReplayPublishCall` (al terminar, si `recordReplay`): `recorded → published`.
  - Los tres se cancelan por identificador (`show:<id>:reminder`) si el show cambia de hora o se cancela.
- **Modelo:** `Notification` (tabla `notification`): userId, kind (`showStartingSoon`, `newFollower`, `postLiked`, `postCommented`, `reportResolved`), payload, readAt, createdAt.
- **Endpoints:**
  - `notifications.list({after})`, `markRead(ids)`, `markAllRead()`.
  - **`notifications.watch() → Stream<NotificationView>`**.
- **App:** la pestaña Actividad lee de acá; el badge se actualiza en vivo.

### M6 — Sanciones, verificación y consola (identity + moderation)
- **Endpoints `admin`, todos con scope `admin`:**
  - `searchAccounts`, `account(userId)`.
  - `suspend` / `ban` / `restore`.
  - `setVerification` (otorgar o revocar, con motivo).
  - `forceEndShow`.
  - `audit({filter, after}) → AuditEntryView` (el DTO del SDD 0001 §4.6).
- **Todo en una transacción con `AuditService.record`.**
- **Suspender en el acto:**
  - Cambia `account_profile.status`.
  - Revoca todas las sesiones de la cuenta con `revokeAllTokens` del token manager de `serverpod_auth_core` (adaptador JWT).
  - Publica `accountSanctioned` en el canal `user:<id>`.
  - La app escucha ese canal con `notifications.watch` y cierra la sesión.
- **Guard `requireActiveAccount`** en toda escritura: posts, comentarios, likes, reportes, chat, follows y shows.
- **Moderación:** `resolve` suma las decisiones `muteAuthor(duración)` y `suspendAuthor` (D10 del SDD 0003, que quedaba pendiente de `identity`).
- **App:** consola y moderación sobre Serverpod; retira `MockPlatform` del runtime.

### M7 — Corte del mock
- `AUTH_SOURCE` pasa a `serverpod` por defecto (D3).
- `DATA_SOURCE` deja de existir, porque ya no hay feed por Dio.
- `MockPlatform`, `MockSocialStore` y los repositorios `Mock…` salen del runtime y quedan en `test/`.
- El selector de cuentas demo pasa a ser un **atajo de login real** con las cuentas sembradas (D13), visible sólo en builds de demo.

### M8 — Deploy y entrega
- **Serverpod Cloud:**
  - Proyecto con base de datos y bucket; secretos (`passwords`) en el administrador de claves.
  - Configuración de producción real.
  - **Una instancia** (D12).
  - Future Calls habilitadas.
- **Web:** el build de Flutter web servido por el web server de Serverpod en el mismo dominio, sin CORS.
- **Seed (D13):** cuentas `operador`, `moderador`, `elena` (creadora verificada), `tomas` y `troll`, con posts y un show programado.
- **README** probado en una máquina limpia; video de menos de 2 minutos; descripción; post en redes.

---

## 6. Contrato nuevo (resumen)

| Endpoint | Método | Quién |
|---|---|---|
| `profiles` | `requestAvatarUpload`, `setAvatar` | Sesión |
| `follows` | `follow`, `unfollow`, `followers`, `following`, `suggestions` | Sesión / público |
| `feed` | `home({cursor})` | Público (invitado sin `following`) |
| `live` | `schedule`, `start`, `end`, `get`, `upcoming`, `byHost`, `chatHistory`, `sendChat`, `hideChat`, `mediaToken` | Según el rol |
| `live` | **`watch(showId)`** (stream) | Quien puede ver el show |
| `notifications` | `list`, `markRead`, `markAllRead`, **`watch()`** (stream) | Sesión |
| `admin` | `searchAccounts`, `account`, `suspend`, `ban`, `restore`, `setVerification`, `forceEndShow`, `audit` | Scope `admin` |
| `moderation` | `resolve` suma `muteAuthor` y `suspendAuthor` | Staff |

Códigos de error nuevos en `NexoErrorCode`: `accountSuspended`,
`creatorNotVerified` y `muted`. La app ya tiene los `Failure` equivalentes.

---

## 7. Plan (12 días, del 3 al 14 de octubre)

Lo construimos en orden, **un módulo por PR**, para que el resto del equipo
revise. Cada paso deja la app funcionando y algo entregable.

| Paso | Días | Qué | Por qué en este orden |
|---|---|---|---|
| 1 | 3/10 | Mergear PR #2. **M8 temprano**: proyecto en Serverpod Cloud, primer deploy, seed | Tener un link desde el primer día. Si el deploy da problemas, aparecen ahora y no el 13 |
| 2 | 3–4/10 | **Prueba técnica de Agora** (D9): un canal con un publicador y un espectador en el destino de la demo, token emitido por el servidor | Es el mayor riesgo. Se decide en dos días si sigue o queda simulado |
| 3 | 4–5/10 | **M3**: publicaciones en la app (subir foto y video, likes, comentarios, reportes, editar y borrar) | El backend ya existe: es lo que más funcionalidad real suma por día |
| 4 | 6–7/10 | **M4**: módulo `live` (programar, máquina de estados, `watch` con chat y espectadores, token de Agora) + la app | El corazón de la demo |
| 5 | 8/10 | **M6**: consola, sanciones con expulsión en el acto, verificación, guard de cuenta activa | Cierra el recorrido de moderación |
| 6 | 9/10 | **M2**: seguir y `feed.home` por secciones | El feed que planeó el equipo |
| 7 | 10/10 | **M5**: Future Calls (aviso, show sin host, replay) y notificaciones en vivo | Piezas del stack que suman a la nota |
| 8 | 11/10 | **M7**: corte del mock, `AUTH_SOURCE=serverpod`. **M1**: avatar y editar perfil | Con todo conectado, el mock ya no hace falta |
| 9 | 12/10 | Prueba en una máquina limpia, README, arreglos | |
| 10 | 13/10 | Video de menos de 2 minutos, descripción, post en redes | |
| — | 14/10 | Colchón y entrega antes de las 23:59 | |

**Corte mínimo** si el tiempo no alcanza: pasos 1, 3, 4 (sin Future Calls) y
5. Con eso, el recorrido completo funciona contra Serverpod y desplegado.

### Lo que necesito de vos (sólo vos puedes hacerlo)

| Qué | Para qué | Cuándo |
|---|---|---|
| **Cuenta de Serverpod Cloud** y `scloud login` en esta máquina | El deploy | Paso 1 |
| **Proyecto en Agora** con App ID y App Certificate (consola de Agora, plan gratuito) | El token del vivo | Paso 2 |
| **Un segundo dispositivo para la demo**: autorizar el Android conectado (aceptar la depuración USB) o instalar Xcode | Agora en web es alfa; un teléfono real es el respaldo para el vivo | Paso 2 |
| Levantar el servidor local con `serverpod start` cuando lo pida | Las reglas del repo dicen que el servidor lo levanta una persona | Desde el paso 3 |

## 8. Testing

- **Backend:** integración con `withServerpod` por endpoint, siguiendo el estilo de `test/integration/`.
  - Por cada endpoint de `admin`: llamarlo **sin** scope espera `forbidden`.
  - Concurrencia (en archivo propio con `RollbackDatabase.disabled`): follows, likes y espectadores.
  - Streaming: un test que se suscribe a `watch` y recibe el mensaje que otro manda.
  - Future Calls: se invoca el método directamente con la sesión de test.
- **App:**
  - Tests de cubits contra repositorios falsos.
  - Los tests de arquitectura existentes siguen valiendo.
  - Uno nuevo falla si una pantalla del runtime importa `MockPlatform` después de M7.
- **Aceptación:** el guion del SDD 0001 §8, corrido contra el deploy.

---

## 9. Riesgos

| # | Riesgo | Mitigación |
|---|---|---|
| R1 | **El chat no llega a todos si hay más de una instancia**: sin Redis, `postMessage` es local | D12: una instancia, o activar el pub/sub de Serverpod Cloud y usar `MessageScope.global` |
| R2 | **Los tests de integración del backend no corren en rutas con espacios** (PostgreSQL embebido) | Documentado en `CLAUDE.md`: clonar en una ruta sin espacios. El CI corre en Linux sin ese problema |
| R3 | **Agora en Flutter web está en alfa** y el token depende de un paquete chico de la comunidad | Prueba técnica en el paso 2, con dos días de tope; respaldo en un teléfono real; si falla, `FakeLiveMediaGateway` y el resto del vivo sigue igual |
| R4 | Revocar el JWT no es instantáneo (el token de acceso vive hasta expirar) | Guard de cuenta activa en cada escritura + aviso por el stream (M6) |
| R5 | Videos de 50 MB en redes lentas | Límite ya en `MediaPolicy`; mostrar el progreso de la subida |
| R6 | Retirar el mock rompe tests de widgets existentes | El mock se muda a `test/`, no se borra; los tests lo inyectan por GetIt |
| R7 | Archivos subidos y nunca publicados | Future Call recurrente diaria que borra claves huérfanas de más de 24 h (P1) |

---

## 10. Qué suma a la nota

| Criterio | Qué lo sube en este SDD |
|---|---|
| ¿Funciona? (30%) | M3, M4, M6, M7, M8: el recorrido entero contra el servidor, desde un link |
| Uso del stack de Serverpod (25%) | ORM con relaciones y transacciones, auth con scopes, **Streaming Methods** (M4, M5), **Future Calls** únicas y recurrentes (M5, R7), **Cloud Storage** (M1, M3), web server (M8), **Serverpod Cloud** (M8), Insights |
| Calidad técnica (25%) | Arquitectura limpia, tests de integración y concurrencia, estado del vivo autoritativo en el servidor |
| Utilidad (20%) | Moderación verificable y sanciones con efecto inmediato: el diferenciador del benchmark |

---

## 11. Fuera de alcance, para el pitch

- Cobro real.
- Push notifications.
- Transcodificación a HLS y miniaturas.
- Ranking por aprendizaje automático.
- Apelaciones.
- Mensajes directos.
- Gamificación.
- Grabación del video en la nube (el replay es la ficha del vivo con su chat).

---

## 12. Decisiones cerradas (2026-10-02)

| Pregunta | Respuesta | Dónde impacta |
|---|---|---|
| Q1 — Video en vivo | **Agora**, con prueba técnica primero | D9, M4, paso 2 |
| Q2 — Equipo | **Lo construimos vos y Claude**, un PR por módulo; el resto revisa | §7 |
| Q3 — Ser creador | **Autoservicio**; el operador verifica | D14 |
| Q4 — Feed "descubrir" | No se preguntó; queda la recomendación: **etiquetas en común con lo que likeaste**, o lo más reciente si no hay | D6 |
| Q5 — Modo mock | **Se retira del runtime** en M7 | D15 |
