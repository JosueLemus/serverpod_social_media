# SDD 0011 — Salas en vivo: host, invitados, moderador y oyentes

| | |
|---|---|
| Estado | **Aprobado**, 2026-10-12 |
| Qué es | El vivo pasa de "un host transmite y el resto mira" a **una sala tipo podcast**: un host, hasta 16 invitados en el escenario, un moderador opcional y oyentes que pueden pedir la palabra |
| Por qué ahora | El pedido de producto es que los vivos se vean y funcionen distinto en el home y en la sala. Hoy sólo el host transmite, los cohosts son 3 y se fijan al programar, el moderador es sólo el staff de Nexo y silenciar, expulsar y aprobar invitados son simulados en el cliente |
| Depende de | 0001 (máquina de estados del show), 0006 (vivos reales, `watch`, tokens de Agora), 0007 (moderación del chat) |

---

## 1. Lo que hay hoy (medido el 2026-10-12)

- `LiveShowRole` ya tiene `audience`, `host`, `cohost` y `moderator`, pero:
  - **`cohost`** es un invitado aceptado **al programar**, con un máximo de **3** (`LiveRules.maxGuests`). No se suma a nadie durante el vivo.
  - **`moderator`** es el **staff de Nexo** (`session.isStaff`). No hay moderador por vivo.
- `mediaToken` le da rol de publicador **sólo al host**. Ningún invitado tiene micrófono.
- El servidor sabe **ocultar** un mensaje del chat (`hideChat`, host o staff). Nada más.
- En la app, silenciar, bloquear y aprobar cohosts son **registros en el estado del cubit** (`recordModeration`, `approveGuest`): no llegan al servidor.
- La sala es video a pantalla completa con el chat encima.

## 2. Decisiones

| # | Decisión | Por qué |
|---|---|---|
| S1 | **Cuatro roles con jerarquía estricta: host (1) > moderador (0–1) > invitado (≤16) > oyente.** Una acción **sobre otra persona** exige rango **estrictamente mayor** que el de ella | Una sola regla explica todos los casos raros: el moderador no puede sacar al host, dos moderadores no se sancionan entre sí, un invitado no modera a otro |
| S2 | **El nombre en el contrato sigue siendo `cohost`**; en la app y en la copy es **"invitado"** | `LiveShowRole` se serializa por nombre: renombrarlo rompe la compatibilidad con clientes viejos a cambio de nada. El nombre del contrato vive en el mapeo del repositorio y en ningún otro lado |
| S3 | **Audio primero.** En el escenario el micrófono es lo principal; la cámara es **opcional** para cualquiera que esté arriba | Es lo que hace viable tener 17 personas transmitiendo, y lo que vuelve el formato "podcast" |
| S4 | **El escenario tiene 17 lugares: el host + 16.** Los 16 cuentan a los invitados de la agenda **y** a los que suben durante el vivo | 17 es el tope recomendado de publicadores por canal en Agora (**hay que confirmarlo en la Etapa 6**) |
| S5 | **Rol y escenario son dos ejes.** El rol dice qué autoridad tiene alguien; el escenario dice si tiene micrófono. Un moderador puede estar arriba o abajo | Mezclarlos obliga a elegir entre "moderador" e "invitado" para quien es las dos cosas |
| S6 | **Se sube al escenario de tres formas:** el host invita directo, el host o el moderador aprueban un pedido de palabra, o estaba invitado en la agenda | El pedido de palabra es la única forma en que un oyente participa por iniciativa propia |
| S7 | **Un moderador por vivo, nombrado por el host** al programar o durante el vivo, y removible por él. El **staff de Nexo cuenta como moderador** en cualquier vivo, como hoy | Dos fuentes de moderación sin conflicto: el host delega en alguien de su confianza y la plataforma sigue pudiendo actuar |
| S8 | **Los invitados no moderan.** Su participación es el micrófono, la cámara, bajarse cuando quieran y **destacar una pregunta** del chat | Repartir poder entre 16 personas vuelve el vivo caótico. Destacar preguntas es lo que más vale en un podcast |
| S9 | **La tabla de permisos (§3) es una función pura** en el servidor (`LivePermissions`) con su **espejo** en la app, y un test que falla si las dos se separan | La app sólo ofrece lo que el servidor acepta (decisión ya tomada en el `CLAUDE.md`): un botón para una acción ilegal es una petición que se rechaza después de que el usuario se comprometió |
| S10 | **Sanciones de la sala:** silenciar en el chat (5 min, 15 min, 1 h o el resto del vivo), **expulsar** (sale y no vuelve a entrar a *este* vivo) y **banear** (no entra a **ningún** vivo de este host hasta que el host lo levante; sólo el host) | Tres escalones con alcances distintos: la conversación, la sala y la relación con el host |
| S11 | **Silenciar el micrófono de un invitado es suave**: el invitado puede volver a activarlo. Si insiste, se lo baja del escenario | Como en Spaces. Un micrófono bloqueado por otro sin salida se lee como un error de la app |
| S12 | **Ocultar es reversible y borrar es definitivo para la vista**, pero **borrar no borra la fila**: queda con `deletedAt` / `deletedBy` y fuera del replay | La auditoría es append-only (decisión ya tomada): una auditoría que borra lo que audita no prueba nada |
| S13 | **Todo lo que hacen host y moderador queda en la auditoría** (`AuditService`), con actor, objetivo y vivo | Probar que la moderación queda registrada es parte de la demo |
| S14 | **La lista de oradores y la cola de pedidos viajan en eventos de `live.watch`**; la cola la ve todo el mundo en el evento, pero la app sólo la **dibuja** para host y moderador | Un solo canal por show (0006). Esconder la cola en el cliente alcanza para la demo; filtrarla por rol en el servidor queda para después |
| S15 | **Un invitado de la agenda cuenta como invitado mientras no haya rechazado** (`invited` o `accepted`). Al salir al aire sube al escenario junto al host | No existe todavía un paso de "aceptar" la invitación: todo invitado queda en `invited`, y filtrar por `accepted` dejaba a la agenda entera abajo |

## 3. La tabla de permisos

`✓` = puede. `↓` = puede, **sólo sobre alguien de rango menor** (S1).

| Acción (`LiveAction`) | Host | Mod | Invitado | Oyente |
|---|:-:|:-:|:-:|:-:|
| `speak` — hablar y prender la cámara (requiere estar en el escenario) | ✓ | ✓ | ✓ | |
| `raiseHand` — pedir la palabra | | ✓ | | ✓ |
| `leaveStage` — bajarse | | ✓ | ✓ | |
| `approveRequest` — aprobar un pedido de palabra | ↓ | ↓ | | |
| `inviteToStage` — subir a alguien directo | ↓ | | | |
| `removeFromStage` — bajar a alguien | ↓ | | | |
| `muteMic` — silenciar el micrófono de otro | ↓ | ↓ | | |
| `assignModerator` — nombrar o quitar al moderador | ↓ | | | |
| `hideChat` / `deleteChat` — ocultar o borrar un mensaje ajeno | ↓ | ↓ | | |
| `pinChat` — fijar un mensaje | ✓ | ✓ | | |
| `highlightQuestion` — destacar una pregunta | ✓ | ✓ | ✓ | |
| `muteChat` — silenciar en el chat | ↓ | ↓ | | |
| `kick` — expulsar de este vivo | ↓ | ↓ | | |
| `ban` — banear de los vivos del host | ↓ | | | |
| `chat` / `react` — escribir y reaccionar | ✓ | ✓ | ✓ | ✓ |
| `end` — terminar el vivo | ✓ | | | |

El staff de Nexo además puede terminar cualquier vivo **por moderación** (0006); eso no pasa por esta tabla.

## 4. Servidor

### 4.1 Modelos nuevos (Etapas 2 y 3)

| Modelo | Campos |
|---|---|
| `LiveParticipant` (tabla, `serverOnly`) | `showId` (relación, cascade), `userId`, `role` (`cohost`, `moderator`), `onStage`, `handRaisedAt?`, `micMuted`, `cameraOn`, `updatedAt`. Único por `showId, userId` |
| `LiveSanction` (tabla, `serverOnly`) | `showId`, `targetId`, `kind` (`chatMute`, `kick`), `until?`, `actorId`, `createdAt` |
| `LiveHostBan` (tabla, `serverOnly`) | `hostId`, `userId`, `actorId`, `createdAt`. Único por `hostId, userId` |
| `LiveChatMessage` (+) | `deletedAt?`, `deletedBy?` |
| `LiveShow` (+) | `pinnedMessageId?`, `highlightedMessageId?`, `moderatorId?` |
| `LiveStageView` | `speakers: List<LiveSpeakerView>`, `hands: List<ProfileView>` |
| `LiveSpeakerView` | `profile`, `role`, `micMuted`, `cameraOn` |
| `LiveEventKind` (+) | `stage`, `roleChanged`, `sanction`, `chatDeleted`, `pinned`, `highlighted` |

`LiveShowGuest` (los invitados de la agenda) sigue: al salir al aire, cada invitado aceptado pasa a ser un `LiveParticipant` con `role: cohost`.

### 4.2 Endpoint `live` (+)

| Método | Acción de la tabla | Errores |
|---|---|---|
| `raiseHand(showId)` / `lowerHand(showId)` | `raiseHand` | `conflict` (no al aire, escenario lleno) |
| `approveRequest(showId, userId)` / `denyRequest` | `approveRequest` | `forbidden`, `conflict` (escenario lleno) |
| `inviteToStage(showId, userId)` | `inviteToStage` | `forbidden`, `conflict` |
| `removeFromStage(showId, userId)` / `leaveStage(showId)` | `removeFromStage` / `leaveStage` | `forbidden` |
| `setMicMuted(showId, userId, muted)` | propio: `speak`; ajeno: `muteMic` | `forbidden` |
| `setCamera(showId, on)` | `speak` | `forbidden` |
| `assignModerator(showId, userId?)` | `assignModerator` (`null` lo quita) | `forbidden` |
| `muteChat(showId, userId, duration)` | `muteChat` | `forbidden` |
| `kick(showId, userId)` / `ban(showId, userId)` / `unban(userId)` | `kick` / `ban` | `forbidden` |
| `deleteChat(messageId)` / `pinChat` / `highlightQuestion` | la acción del mismo nombre | `forbidden`, `notFound` |
| `stage(showId) → LiveStageView` | — | `notFound` |

Y cambia lo que ya existe:

- **`mediaToken`**: publica el host **y todo el que esté en el escenario**. Cuando alguien sube o baja, el evento `stage` le avisa a la app que pida un token nuevo.
- **`sendChat`**: rechaza a un silenciado (`forbidden`, motivo `chatMuted`).
- **`watch`**: rechaza a un expulsado o baneado (`forbidden`, motivo `kicked` / `banned`).
- **`hideChat`**: pasa a usar la tabla (el moderador del vivo también puede).

## 5. App

- **Dominio:** `LivePermissions` (espejo de §3), `LiveRole` con su etiqueta ("Host", "Moderador", "Invitado", "Oyente") en una extensión de presentación.
- **La sala (Etapa 4):**
  - **Escenario arriba**: el host destacado y una grilla de hasta 16 invitados. Un anillo con el color de en vivo del tema late cuando alguien habla. Insignia de rol y micrófono apagado.
  - **"Escuchando" debajo**: avatares y total.
  - **Barra según el rol**: el oyente pide la palabra; el invitado tiene micrófono, cámara y bajarse; host y moderador además ven la cola de pedidos.
  - **Chat** en una hoja inferior en el teléfono y en un panel lateral en escritorio.
  - **Pulsación larga sobre una persona** abre una hoja con sus acciones, **filtradas por la tabla**.
- **El home (Etapa 5):** tarjeta tipo "sala" (título, host y oradores apilados con "+N", oyentes, onda de audio, CTA **Escuchar**) y una fila "Salas en vivo".
- **El mock** (`MockPlatform`) aplica las mismas reglas que el servidor, como con todo lo demás.

## 6. Tests

- **Servidor:** la tabla completa como función pura; cada endpoint nuevo con sus permisos y el caso de rango; escenario lleno; `mediaToken` de un invitado; chat silenciado; expulsado y baneado en `watch`; auditoría de cada acción.
- **App:** la tabla espejo y el **test de contrato** contra el archivo del servidor; cubit de la sala por rol; la hoja de acciones sólo muestra lo permitido; la sala y la tarjeta del home sin desborde a 320.

## 7. Etapas y línea de corte

| Etapa | Qué | Se ve en la demo |
|---|---|---|
| 0 | Este documento | — |
| 1 | Reglas puras (servidor + app + test de contrato), invitados de 3 a 16, rol `cohost` en el mock | Programar un show con hasta 16 invitados |
| 2 | Escenario en el servidor: participantes, pedir la palabra, subir y bajar, `mediaToken` para el escenario | El oyente pide la palabra y el host lo sube |
| 3 | Moderación real: silenciar, expulsar, banear, borrar, fijar, destacar, nombrar moderador | Todo lo de la tabla, auditado |
| 4 | La sala tipo podcast | El cambio visible grande |
| 5 | El vivo en el home | La tarjeta nueva |
| 6 | Audio y video reales con 17 publicadores (Agora: cambio de rol, renovación de token, indicador de quién habla) | Riesgoso: no bloquea la demo |
| 7 | Replay como podcast (opcional) | — |

**Corte del hackathon: Etapas 0 a 5**, con el audio simulado.

## 8. Avance

- **Etapas 0 y 1** — hechas.
- **Etapa 2** — hecha en servidor, mock y capa de datos de la app:
  - `LiveParticipant` y la migración `live-stage`; `LiveStageService` con los
    nueve métodos; `mediaToken` publica para todo el escenario; `watch` manda
    `stage` y `roleChanged`.
  - En la app: `LiveStage`, los dos eventos, el repositorio (Serverpod y mock,
    con las mismas reglas) y el cubit (`raiseHand`, `approveRequest`,
    `toggleMyMic`…).
  - **Pendiente para la Etapa 6:** la app no pide una credencial de video
    nueva al subir o bajar del escenario (`LiveMediaSync` todavía sólo mira
    si es host).

- **Etapa 3** — hecha en servidor, mock y capa de datos de la app:
  - Tablas `live_sanction` y `live_host_ban`, columnas para borrar, fijar y
    destacar (migración `live-moderation`, sólo agrega), y
    `LiveModerationService` con los once métodos.
  - El chat rechaza a un silenciado (`muted`); `watch`, `mediaToken`, el chat
    y el escenario rechazan a un expulsado o baneado (`forbidden`).
  - El snapshot trae el mensaje fijado, la pregunta destacada y el silencio
    propio; hay eventos para cada sanción, borrado, restauración, fijado y
    destacado.
  - En la app: dominio, repositorios (Serverpod y mock), cubit, y la hoja de
    moderación del chat que ya existía ahora silencia y expulsa de verdad.

- **Etapa 4** — hecha (SDD 0011, 2026-10-12):
  - La sala tipo podcast reemplazó al video a pantalla completa con chat
    encima. El host va destacado arriba y la grilla de hasta 16 invitados
    debajo (4 columnas en teléfono, 5 en tablet, 6 en escritorio); cada tile
    muestra avatar, nombre, insignia de rol y el pin de "micrófono apagado" o
    "cámara prendida".
  - Barra inferior **por rol**, decidida con `LiveAction` y el escenario:
    oyente pide la palabra (y la baja); invitado/moderador en escenario
    tienen micrófono, cámara y "bajarme"; host y moderador suman la pastilla
    "Pedidos · N" que abre la cola; host suma "Terminar el vivo". Sin manos
    reales no se dibujan oyentes inventados — sólo el total.
  - **Hoja de persona** (`live_person_sheet.dart`) con pulsación larga sobre
    un tile, un pedido o un comentario: lista exactamente
    `LivePermissions.on(myRole, suRol)`, **devuelve** una decisión tipada y
    el cubit la aplica. Los chips de duración del silencio en chat arman la
    decisión; "Aplicar" la confirma. Banear pide confirmación por su
    permanencia; una `confirmation` cuyo `Navigator.of(context).pop(...)`
    cierra el diálogo y recién después pasa la decisión al cubit.
  - **Avisos en pantalla**: silenciado reemplaza el compositor por una banda
    ámbar con el motivo; expulsado/baneado reemplazan la sala por un
    `AppEmptyView` con la mascota `shield` (no se insiste con reconectar);
    subir/bajar del escenario tira un snackbar una sola vez por cambio de
    rol.
  - **La sala es inmersiva de verdad**: la ruta `/explore/live/:liveId` ahora
    se empuja con `parentNavigatorKey: rootNavigatorKey`, así que la barra de
    navegación se tapa y la franja clara del shell no aparece sobre el video
    en temas claros. `openLive` pasó a `context.push`.
  - **El `_GuestRequests` del Studio** lee `stage.hands` y llama a
    `approveRequest` / `denyRequest` con el `userId` real. Se borró el campo
    `pendingGuests` del cubit, con sus métodos `approveGuest` / `rejectGuest`
    (que además tenían el bug de que "rechazar" dejaba la auditoría diciendo
    "aprobado"). La hoja de moderación del chat del Studio sigue por el
    `moderation_sheet` legacy; la sala podcast usa la hoja de persona.
  - **Semilla del mock** (`storageKey = mock_platform_v2`): `live-1` arranca
    con el host, tres invitados en el escenario (Ana con cámara, Marcos
    silenciado, Lucía moderadora) y dos manos levantadas (Luz y Sofía).
    Cuatro cuentas demo nuevas (`guestAna`, `guestMarcos`, `guestLuz`,
    `listenerSofia`) para que la demo tenga quién hablar y quién levante la
    mano.

- **Etapa 5** — hecha (SDD 0011, 2026-10-12):
  - **Tarjeta de sala** (`LiveRoomCard`): fondo oscuro, insignia "EN VIVO"
    pulsante, título, pila de avatares con el host adelante (foil holo) y
    hasta cuatro invitados; "+N" cuando hay más; "N escuchando" con cifras
    tabulares; CTA "Escuchar" (o "Volver a tu sala" si es propia). La onda
    de audio está aislada en `RepaintBoundary` y respeta "reducir
    movimiento".
  - Reemplaza a `FeaturedLiveCard` + `LiveCard` en los dos lugares donde se
    listan salas al aire: feed destacado, filtro "En vivo" del feed y
    sección "Salas en vivo" de Explorar. `LiveCard` queda para los
    programados y replays. `FeaturedLiveCard` sigue en el repo (no se
    importa desde ningún lado) para no romper el share test; se borra
    cuando se elimine ese test.
  - **No inventamos oradores**: `LiveRoomSpeakers.fromSession` sale de
    `cohostIds` (los que la agenda del show declaró). `fromStage` existe
    para el día que se pida el escenario real desde la pantalla, pero por
    ahora ninguna lista lo pide — un GET por fila costaría una petición por
    tarjeta.

- **Pendiente para la Etapa 6** (riesgoso, no bloquea la demo):
  - La app no pide una credencial de video nueva al subir o bajar del
    escenario (`LiveMediaSync` sólo mira el rol inicial). Hay que renovar el
    token cuando el `LiveRoleChanged` llega como `isMine`.
  - **Indicador real de "quién habla"**: `_StageTile` ya está preparado para
    pintar un anillo pulsante con `AppColors.secondary`, pero sin fuente de
    niveles de audio queda en false. Agora emite ese evento; hay que
    engancharlo al estado del cubit.
  - La tarjeta destacada todavía no pide `repository.stage(id)` para
    mostrar los oradores de verdad (sigue leyendo `cohostIds` de la
    agenda). El cambio es un cubit nuevo que pida el stage de la sala
    destacada al armar la lista.

## 9. Riesgos

- **El límite de 17 publicadores de Agora** es lo que dimensiona el escenario. Si resulta menor, baja `LiveRules.maxStage` y nada más cambia.
- **El cambio de rol de Agora en caliente** (subscriber → publisher) necesita un token nuevo. Si la renovación falla, el invitado queda arriba sin micrófono: la app tiene que decirlo, no fallar en silencio.
- **La cola de pedidos se publica a todos** (S14). Si molesta, el servidor la filtra por rol antes de publicarla.

## 10. Fuera de alcance

Varios moderadores por vivo, co-host con poderes de host, salas privadas por
invitación, grabación por pista, subtítulos y traducción, y monetización por
pedir la palabra.
