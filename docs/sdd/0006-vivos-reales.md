# SDD 0006 — Vivos reales: el módulo `live` contra Serverpod

| | |
|---|---|
| Estado | **Propuesto**, 2026-10-11 |
| Qué es | El **cómo** de M4 (SDD 0004 §5). El 0004 dice qué modelos y endpoints hacen falta; acá están las firmas, el protocolo en tiempo real, los cambios de la app y el orden |
| Depende de | SDD 0004 (D5, D8, D9, D12, D14), SDD 0005 (§3 video, §5 orden), M3 ya mergeado (`e1b3ccb`) |
| Entrega | 14/10/2026 23:59. Quedan tres días: la Fase 1 (§7) es lo que entra sí o sí |

---

## 1. El problema, medido (2026-10-11)

Con `AUTH_SOURCE=serverpod` (lo que levanta `tool/demo.sh`), el login, el feed
y los posts son reales, pero **los vivos siguen en `MockPlatform`**:

| Síntoma | Causa |
|---|---|
| "Tu cuenta no tiene permiso para hacer esto." al iniciar un vivo, **con cualquier cuenta, también Elena** | `MockPlatform.bindSession` sólo lo llama `MockAuthRepository`. Con login de Serverpod el mock no tiene actor, y `_requireActor()` lanza `ForbiddenFailure('unauthenticated')` |
| El operador abre el Studio y ve un vivo que no es suyo | `creator_studio_page.dart:30` carga siempre `live-2` (de Elena) |
| Dos dispositivos no ven el mismo vivo | Cada proceso tiene su `MockPlatform` en memoria. Sólo dos pestañas del mismo navegador lo comparten, por `localStorage` |
| "En vivo 0" en el feed aunque haya vivos | El contador cuenta `post.isLive`, y `ServerpodPostRepository` nunca lo asigna |
| La tarjeta destacada dice siempre `@elena_ux` | `feed_page.dart:194`, literal |
| Espectadores, reloj, subs y donaciones del Studio no cambian nunca | Semilla fija o constantes en `LiveRoomCubit.load` |
| "Rechazar" una solicitud para unirse la aprueba | Los dos botones llaman a `approveGuest` |

En el servidor no hay módulo `live`: sólo la interfaz `LiveMediaGateway`, sin
implementaciones. El repo no usa todavía ni Streaming Methods ni
`session.messages`.

---

## 2. Objetivo y prueba de aceptación

**Que el estado de un vivo lo tenga el servidor, y que todos los dispositivos
lo vean cambiar en el acto.**

Prueba de aceptación, con el servidor de `tool/demo.sh`, un teléfono y la web
(o dos teléfonos):

1. **Teléfono A**: entra Elena. El Studio muestra **su** show programado. Toca **Iniciar vivo**.
2. **Web**: Tomás, en el feed. En **menos de 2 segundos**, sin recargar, aparece el vivo de Elena en "En vivo ahora", la tarjeta destacada dice `@elena_ux` y el filtro dice "En vivo 1".
3. Tomás entra a la sala. En el Studio de Elena, **Espectadores pasa de 0 a 1**. Tomás sale y vuelve a 0.
4. Tomás comenta y el comentario aparece en todas las salas abiertas.
5. **Teléfono B** o una segunda pestaña: entra Lucía, la moderadora. Mantiene apretado el comentario y lo oculta: **desaparece para todos**, y queda en la auditoría.
6. Elena toca **Finalizar**. Tomás ve que el vivo terminó y el show pasa a "Replays".
7. El operador abre el Studio: no tiene show propio y ve el estado vacío, no el vivo de Elena. Si intenta iniciar uno ajeno por API, recibe `forbidden`.

---

## 3. Decisiones

| # | Decisión | Por qué |
|---|---|---|
| L1 | **Un módulo `live` nuevo** en `modules/live/{models,services,endpoints}`, con el patrón de `content`: tablas `serverOnly`, DTO `…View` y endpoint delgado | Convención del AGENTS.md y D1 del 0004 |
| L2 | **La máquina de estados vive en `LiveRules`**, con la misma tabla que hoy aplica el mock (§4.2). Una transición ilegal responde `conflict` | La tabla del mock ya es la del SDD 0001 y está testeada; se porta, no se reinventa |
| L3 | **Endpoints por intención** (`start`, `end`, `publish`, `cancel`), no un `transition(to)` genérico. Los cuatro van a un único `LiveService.transition` | Cada uno tiene su regla de permisos. La app conserva su `transition(id, status)` y el repositorio traduce |
| L4 | **El gate de inicio (D5)**: host, creador, verificado y cuenta activa. Un host tiene **un solo vivo al aire a la vez**, con un advisory lock por host | La regla del SDD 0001, ahora en el servidor. Sin el lock, dos toques rápidos abren dos vivos |
| L5 | **Tiempo real con dos Streaming Methods**: `watch(showId)` por show y `watchIndex()` para "quién está en vivo". Se publica en `live:<id>` y `live:index` | D8. `watchIndex` es lo que hace que el otro dispositivo se entere sin recargar |
| L6 | **Al conectarse a `watch`, primero se suscribe al canal y después se envía la foto inicial** (show, rol, espectadores y últimos 50 mensajes) | En el orden inverso, un mensaje que llega entre leer la historia y suscribirse se pierde |
| L7 | **Ningún dato propio de quien mira viaja en un mensaje compartido.** `LiveShowView` no lleva el rol; el rol va sólo en la foto inicial, que se calcula en la sesión de cada espectador | `postMessage` lo arma la sesión que emite: un `myRole` ahí le daría a toda la audiencia el rol del host |
| L8 | **Espectadores en memoria del proceso** (`LivePresence`): una entrada por conexión de `watch`, sin contar al host. Cada alta o baja publica `viewers`. `viewerPeak` se guarda al terminar | D12: una sola instancia. Un contador en la base pide una escritura por entrada y salida, y se desincroniza si el proceso muere |
| L9 | **La baja se registra en un `WillCloseListener`** y en el `finally`, de forma idempotente | En 4.0.3, cancelar el stream cierra la sesión; el listener corre antes de que se retiren los canales, y el `finally` cubre la cancelación normal |
| L10 | **El chat se guarda** (`live_chat_message`) y después se publica. Ocultar pone `hiddenAt`/`hiddenBy`, audita y publica `chatHidden`; nunca borra | D8 y la regla append-only de la moderación |
| L11 | **Límite de 1 mensaje por segundo por cuenta**, en memoria. Responde `rateLimited` | 0004 §M4. Es la primera vez que se usa ese código |
| L12 | **Códigos nuevos en `NexoErrorCode`**: `creatorNotVerified`, `accountSuspended` y `muted`. `failureFromServer` los traduce a los `Failure` que la app ya tiene | 0004 §6. Sin ellos, el gate se ve como "no tenés permiso" y la pantalla no puede explicar el rechazo |
| L13 | **Nada se siembra "al aire".** El seed crea un show programado de Elena y otro de Carlos, más un replay de Elena | Un vivo al aire sin nadie transmitiendo es exactamente el mock que se reemplaza. "En vivo ahora" arranca vacío y se llena cuando alguien inicia |
| L14 | **El Studio abre el show propio**: el que está al aire o, si no, el próximo programado. Sin ninguno, muestra un estado vacío con "Programar vivo" | Arregla el `live-2` fijo |
| L15 | **El mock queda para `AUTH_SOURCE=mock` y para los tests.** `injection.dart` elige `ServerpodLiveRepository` igual que con los posts | D2 y D15: el corte del runtime es M7. Hoy hay tests de widgets que dependen del mock |
| L16 | **El video no cambia en la Fase 1**: simulado, o Agora en modo de prueba si se pasa `AGORA_APP_ID` (etapa A, ya mergeada). El canal pasa a ser `nexo_live_<id del servidor>` | El token del servidor (etapa B) necesita el App Certificate (§7, Fase 2) |

---

## 4. Servidor

### 4.1 Modelos (`modules/live/models/`)

```yaml
class: LiveShow
table: live_show
serverOnly: true
fields:
  hostId: UuidValue
  title: String
  description: String, default=''
  startsAt: DateTime
  durationMinutes: int, default=60
  access: LiveShowAccess            # public | members
  allowQuestions: bool, default=true
  recordReplay: bool, default=true
  status: LiveShowStatus
  startedAt: DateTime?
  endedAt: DateTime?
  endedBy: UuidValue?
  endedByModeration: bool, default=false
  viewerPeak: int, default=0
  createdAt: DateTime, default=now
indexes:
  live_show_status_idx:
    fields: status, startsAt
  live_show_host_idx:
    fields: hostId, startsAt
```

| Modelo | Campos | Tabla |
|---|---|---|
| `LiveShowStatus` (enum, `byName`) | `draft, scheduled, live, ending, recorded, published, cancelled, failed, removed`: los mismos nombres que `LiveStatus` de la app | — |
| `LiveShowAccess` (enum) | `public, members` | — |
| `LiveShowRole` (enum) | `audience, host, cohost, moderator` | — |
| `LiveShowGuest` | `showId` (relación a `live_show`, cascade), `userId`, `status` (`invited`), `createdAt`. Único por `showId, userId` | `live_show_guest` |
| `LiveChatMessage` | `showId` (relación, cascade), `authorId`, `body`, `createdAt`, `hiddenAt?`, `hiddenBy?`. Índice `showId, id` | `live_chat_message` |
| `LiveShowDraft` (entrada) | `title`, `description`, `startsAt`, `durationMinutes`, `access`, `allowQuestions`, `recordReplay`, `guestUsernames: List<String>` | — |
| `LiveShowView` | `id`, `hostId`, `hostUsername`, `hostName`, `title`, `description`, `startsAt`, `durationMinutes`, `access`, `allowQuestions`, `recordReplay`, `status`, `startedAt?`, `endedAt?`, `endedByModeration`, `viewerCount`, `guestIds` | — |
| `LiveChatMessageView` | `id`, `showId`, `authorId`, `authorUsername`, `authorName`, `body`, `createdAt` | — |
| `LiveEvent` | `kind: LiveEventKind` (`snapshot, status, viewers, chat, chatHidden`), `liveShow: LiveShowView?` (`show` es palabra reservada del generador), `role: LiveShowRole?`, `viewerCount: int?`, `message: LiveChatMessageView?`, `history: List<LiveChatMessageView>?`, `hiddenMessageId: int?` | — |

`LiveEvent` es plano, con `kind` y campos opcionales, en lugar de una jerarquía
sellada: `createStream<LiveEvent>` tipa el canal con una sola clase, y un
cliente viejo ignora un `kind` que no conoce.

Una migración: `serverpod create-migration --tag live`.

### 4.2 Reglas (`LiveRules`, funciones puras)

| De | A |
|---|---|
| `draft` | `scheduled`, `cancelled` |
| `scheduled` | `live`, `cancelled` |
| `live` | `ending`, `recorded`, `failed` |
| `ending` | `recorded` |
| `recorded` | `published`, `removed` |
| `published` | `removed` |
| `cancelled`, `failed`, `removed` | — (terminales) |

- **Programar:** el título tiene de 1 a 100 caracteres después del `trim`, `startsAt` es futuro y la duración va de 15 a 240 minutos.
  - Los invitados son 3 como máximo, distintos del host, y tienen que existir y estar activos.
- **Chat:** el cuerpo tiene de 1 a 280 caracteres después del `trim`, y sólo se puede escribir con el show en `live`.
- **Publicar:** exige `recordReplay`.

### 4.3 Endpoint `live`

| Método | Quién | Errores |
|---|---|---|
| `schedule(LiveShowDraft) → LiveShowView` | Creador verificado y activo | `creatorNotVerified`, `accountSuspended`, `invalidInput`, `notFound` (invitado) |
| `start(int showId) → LiveShowView` | Sólo el host. Gate L4 | `forbidden`, `creatorNotVerified`, `accountSuspended`, `conflict` (estado, u otro vivo al aire) |
| `goLive(String title) → LiveShowView` | "Transmitir ahora": crea el show y lo pone al aire en una transacción. Mismo gate y mismo lock por host que `start` | `creatorNotVerified`, `accountSuspended`, `invalidInput`, `conflict` (otro vivo al aire) |
| `mediaToken(int showId) → LiveMediaGrant` | Público. `{appId, channel, uid, token, role, expiresAt}`: publica sólo el host con el show al aire; el resto (también sin sesión) se suscribe. `uid` estable por cuenta (FNV-1a del UUID, 31 bits; 0 sin sesión). TTL 2 h. Sin App Certificate, `token` vacío (modo de prueba) | `notFound`, `conflict` (el show ya terminó) |
| `end(int showId) → LiveShowView` | Host o `admin` | `forbidden`, `conflict` |
| `publish(int showId)`, `cancel(int showId)` | Host o `admin` | `forbidden`, `conflict` |
| `get(int showId) → LiveShowView` | Público | `notFound` (también `removed`) |
| `list() → List<LiveShowView>` | Público. `live`, `ending`, `scheduled` (aunque haya pasado la hora: el host todavía puede iniciarlo, y cancelarlo es de M5), `recorded` y `published`; 50 como máximo | — |
| `mine() → List<LiveShowView>` | Sesión. Los shows propios, en cualquier estado | `unauthenticated` |
| `roleIn(int showId) → LiveShowRole` | Público (sin sesión: `audience`) | — |
| `chatHistory(int showId, {int? beforeId}) → List<LiveChatMessageView>` | Público. Sin ocultos, 50 por página | `notFound` |
| `sendChat(int showId, String body) → LiveChatMessageView` | Sesión activa | `conflict` (no está al aire), `rateLimited`, `accountSuspended`, `invalidInput` |
| `hideChat(int messageId)` | Host del show, `moderator` o `admin`. Auditado como `live.hideChat` | `forbidden`, `notFound` |
| **`watch(int showId) → Stream<LiveEvent>`** | Público | `notFound` |
| **`watchIndex() → Stream<LiveShowView>`** | Público | — |

Cada transición y cada `schedule` corren en una transacción con
`AuditService.record` (`live.schedule`, `live.start`, `live.end`, …). **Los
mensajes se publican después del commit**: si la transacción se revierte,
ningún dispositivo debe haber visto el cambio.

### 4.4 `watch`, paso a paso

```dart
Stream<LiveEvent> watch(Session session, int showId) async* {
  final events = session.messages.createStream<LiveEvent>(LiveChannels.show(showId)); // 1. suscribirse
  final show = await _service.requireVisible(session, showId);                       // 2. validar
  _presence.join(session, show);           // 3. alta (no cuenta al host) → publica `viewers`
  session.addWillCloseListener((s) => _presence.leave(s, showId));   // 4. baja garantizada (L9)
  try {
    yield await _service.snapshot(session, show);  // 5. foto: show, rol de ESTA sesión, espectadores, historia
    yield* events;                                  // 6. reenviar
  } finally {
    _presence.leave(session, showId);               // idempotente
  }
}
```

`watchIndex()` es `yield* session.messages.createStream<LiveShowView>('live:index')`.
Cada transición publica ahí el `LiveShowView` nuevo.

### 4.5 Seed

En `DemoSeed`, un `_seedLive` con su propia guarda de idempotencia (contar los
shows de Elena; la de los posts hace `return` y lo saltearía):

- Elena: "Masterclass de Diseño Mobile", programado para dentro de una hora.
- Carlos: "Flutter en vivo: tokens de diseño", programado para mañana.
- Elena: un replay `published` con tres mensajes de chat.

---

## 5. App

| Pieza | Cambio |
|---|---|
| `LiveRepository` | Suma `Future<List<LiveSession>> mine()` y `Stream<LiveRoomEvent> watch(String liveId)`. `changes()` se queda: en Serverpod lo alimenta `watchIndex` |
| `LiveRoomEvent` (dominio, nuevo, sellado) | `LiveRoomSnapshot(session, role, comments)`, `LiveSessionChanged(session)`, `LiveViewersChanged(count)`, `LiveCommentAdded(comment)`, `LiveCommentHidden(commentId)` |
| `LiveSession` | Suma `hostUsername` y `startedAt`. `copyWith` suma `viewers` y `status` |
| `ServerpodLiveRepository` (nuevo, `features/live/data/`) | Sobre `serverpod.Client`, con el patrón de `ServerpodPostRepository`: `_guard` + `failureFromServer` e ids `'${id}'` ↔ `int.parse`. `transition(id, status)` traduce: `live → start`, `recorded → end`, `published → publish`, `cancelled → cancel`; el resto es `ConflictFailure` |
| `MockLiveRepository` | `watch` emite un `LiveRoomSnapshot` al suscribirse y en cada `changes()`. `mine` filtra por el actor |
| `ServerpodShowScheduleRepository` (nuevo) | `schedule → live.schedule`, `findGuest → profiles.byUsername`. El borrador sigue en `ShowDraftLocalDataSource` |
| `failureFromServer` | `creatorNotVerified → CreatorNotVerifiedFailure`, `accountSuspended → AccountSuspendedFailure`, `muted → MutedFailure`, `rateLimited → RateLimitedFailure` (nuevo, con su copy y su `LiveRoomIssue.tooFast`) |
| `LiveRoomCubit` | `load(id)` se suscribe a `watch` y aplica eventos, en lugar de `byId + roleIn + comments + changes`. `sendComment` agrega el comentario devuelto y deduplica por id cuando llega el eco. Si el stream cae, reintenta (1 s, 2 s, 5 s) y la foto inicial resincroniza. `elapsed` sale de `startedAt` y deja de ser constante. El Studio usa `loadStudio({requested})` (con `pickStudioShow`, del SDD 0007) |
| `CreatorStudioPage` | `loadStudio()` en lugar de `load('live-2')`. Estado vacío con CTA a programar |
| `LiveListCubit`, `ExploreCubit` | Escuchan `changes()` y recargan |
| `FeedPage` | "En vivo N" y la tarjeta destacada salen de `LiveListCubit`, no de `post.isLive`. `hostUsername` sale de la sesión |
| `injection.dart` | `LiveRepository` y `ShowScheduleRepository` se eligen por `resolvedAuthSource`, igual que `PostRepository` |

### Lo que sigue simulado después de la Fase 1 (y la pantalla ya lo dice)

- El video, salvo que se pase `AGORA_APP_ID`.
- Las métricas de suscripciones y donaciones, que ya dicen "(mock)".
- Las solicitudes para unirse, el mensaje fijado y el corazón.
- El acceso `members`: hoy no hay membresías en el servidor, así que todo show es público para mirar.
- La consola del operador (`activeLives`, `forceEndLive`) y el reporte de un mensaje del chat a la cola. Son de M6 y siguen sobre el mock.

---

## 6. Tests

**Backend** (`test/integration/live/`, con `withServerpod`; ver la nota de
abajo sobre rutas con espacios):

- **`live_rules_test`** (unit): la tabla completa, permitidas y prohibidas.
- **`live_endpoint_test`:**
  - El gate:
    - Sin sesión responde `unauthenticated`.
    - Un no-host recibe `forbidden`, y el operador también.
    - Sin verificar responde `creatorNotVerified`, y suspendido `accountSuspended`.
    - Un segundo vivo al aire responde `conflict`.
  - Una transición ilegal responde `conflict`.
  - Programar con fecha pasada o con 4 invitados responde `invalidInput`.
  - `mine` sólo devuelve shows propios.
- **`live_chat_test`:**
  - Mandar con el show sin estar al aire responde `conflict`.
  - Dos mensajes en el mismo segundo: el segundo responde `rateLimited`.
  - `hideChat`: el host y el moderador sí; un espectador recibe `forbidden`. Lo oculto no sale en `chatHistory` y queda en `audit_log`.
- **`live_watch_test`** (streaming, con `flushEventQueue()`):
  - El primer evento es `snapshot`, con la historia.
  - Un mensaje que manda otra sesión llega como `chat`.
  - `hideChat` llega como `chatHidden`.
  - Cancelar la suscripción baja `viewerCount`.
  - El host no cuenta como espectador.
  - `start` llega por `watchIndex`.

**App:**
- `ServerpodLiveRepository`: mapeo de `LiveShowView` a `LiveSession` y de `transition` a endpoint.
- `LiveRoomCubit` contra un repositorio falso con `StreamController`:
  - Aplica cada evento.
  - Deduplica el eco del comentario propio.
  - Reintenta cuando el stream cae.
- El Studio elige el show propio y, sin shows, muestra el estado vacío.
- Los tests actuales de `live_room_cubit_test` y `schedule_show_cubit_test` siguen corriendo contra el mock, que implementa el contrato nuevo.

```bash
cd services/serverpod/nexo_server
SERVERPOD_DATABASE_DATA_PATH="$HOME/.nexo-test/pgdata" SERVERPOD_PASSWORD_database=x dart test
cd apps/nexo_social && flutter analyze && flutter test
```

**Aceptación:** el guion de §2, a mano, con dos dispositivos.

---

## 7. Fases y línea de corte

| Fase | Qué | Necesita |
|---|---|---|
| **1 — Núcleo** (≈1 día) | §4 completo: modelos, migración, reglas, endpoint, `watch` y `watchIndex`, presencia, chat, códigos nuevos y seed. §5 completo. Tests de §6 | Nada externo |
| **— LÍNEA DE CORTE —** | **El guion de §2 pasa con dos dispositivos contra Serverpod** | |
| 2 — Video con token (etapa B) — **hecha** | `AgoraLiveMediaGateway` + `live.mediaToken(showId)`. El token AccessToken2 lo arma `shared/gateways/agora/agora_token_builder.dart` (validado contra los vectores oficiales de `AgoraIO/Tools`). Secretos `agoraAppId` y `agoraAppCertificate`; sin certificado, `FakeLiveMediaGateway` (modo de prueba). La app lo pide en `LiveMediaCubit.join` y el rol del servidor manda sobre el de la pantalla | **App ID y App Certificate** de Agora |
| 3 — Lo que suma si sobra tiempo | Solicitudes para unirse reales (`LiveShowGuest`: pedir, aceptar, rechazar, en el stream); el chat también visible en el Studio; reportar un mensaje del chat a la cola (`ReportTargetType.liveChatMessage`) | — |

Fuera de este SDD: los Future Calls de aviso, el show sin host y la publicación
del replay (M5), las sanciones (silenciar, expulsar, `forceEnd` de la consola;
M6) y más de una instancia (R1 del 0004).

---

## 8. Riesgos

| # | Riesgo | Mitigación |
|---|---|---|
| R1 | Presencia y mensajes son locales al proceso | D12 del 0004: una instancia. La demo es local, así que se cumple sola |
| R2 | El stream se corta (red móvil, el teléfono bloquea la pantalla, `adb reverse` se cae al desenchufar) | Reintento con backoff en el cubit; la foto inicial resincroniza todo. La sala muestra "reconectando" en vez de quedarse congelada |
| R3 | Los tests de integración no corren en una ruta con espacios | `SERVERPOD_DATABASE_DATA_PATH`, **con una carpeta padre propia** (`~/.nexo-test/pgdata`): el PostgreSQL embebido guarda su pid y su estado en la carpeta padre del `dataPath`, así que `~/.nexo/test-pgdata` choca con la base de `tool/demo.sh` (`~/.nexo/dev-pgdata`) si las dos corren a la vez. El CI corre en Linux |
| R4 | Un espectador que se fue no baja del contador porque el proceso no se enteró del cierre | El `WillCloseListener` + `finally` (L9). Si el proceso muere, la presencia arranca vacía: es memoria |
| R5 | Agregar valores a `NexoErrorCode` y regenerar el cliente rompe el `switch` exhaustivo de `failureFromServer` | Es lo que se busca: el analyzer obliga a mapear los códigos nuevos |
| R6 | Cambiar `LiveRepository` rompe los dobles de los tests | El mock implementa el contrato nuevo en el mismo PR; `flutter test` en verde es condición de merge |
