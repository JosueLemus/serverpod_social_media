# SDD 0008 — Seguir, perfil y notificaciones contra Serverpod

| | |
|---|---|
| Estado | **Servidor hecho** (M2, M1 y M5), 2026-10-11. Falta la app |
| Qué es | El **cómo** de M2, M1 y M5 del SDD 0004 §5, sobre el código que existe hoy (después del SDD 0006) |
| Depende de | SDD 0004 (D6, D10, D11, D13), SDD 0006 (módulo `live`, `watch` como patrón de streaming), M3 (`content`, `social`) |
| Orden | M2 → M1 → M5, **una migración por módulo y en ese orden**. Las migraciones de Serverpod son secuenciales: dos generadas en paralelo se pisan |
| Entrega | 14/10/2026 23:59 |

---

## 1. Dónde estamos

| Pieza | Hoy |
|---|---|
| Seguir | No existe en el servidor. La app lo simula con `MockSocialStore` y "A quién seguir" es una lista fija |
| Feed | `posts.feed` cronológico. La visibilidad `followers` sólo la ve el autor, porque no había grafo (SDD 0002) |
| Avatar | `ProfileView.avatarUrl` existe y sale de la imagen de `UserProfile` de Serverpod; nadie la escribe |
| Editar perfil | `profiles.update` (username, nombre, bio) y `becomeCreator` existen; ninguna pantalla los llama |
| Notificaciones | No existen en el servidor. La pestaña Actividad dibuja una lista fija |
| Future Calls | El repo no usa ninguna |

---

## 2. Decisiones

| # | Decisión | Por qué |
|---|---|---|
| S1 | **Seguir vive en `social`** (tabla `follow`), con contadores desnormalizados `followerCount`/`followingCount` en `account_profile` | Contar seguidores en cada perfil es un `COUNT` por vista. Es el mismo trade-off que `likeCount` en `post` |
| S2 | **`follow`/`unfollow` son idempotentes** y bloquean las dos filas de `account_profile` en **orden fijo** (por `authUserId` como texto) | Dos toques seguidos no suman dos. El orden fijo evita el deadlock de A sigue a B mientras B sigue a A |
| S3 | **No se puede seguir a uno mismo** (`invalidInput`); quien sigue tiene que estar activo (`accountSuspended`); el seguido tiene que existir (`notFound`) | La regla vive en el servidor, no en un botón escondido |
| S4 | `ProfileView` **suma** `followerCount`, `followingCount` y `viewerFollows`, todos con default | Agregar con default no rompe a la app ni a sus tests, que construyen `ProfileView` |
| S5 | **La visibilidad `followers` se abre**: la ven el autor, el staff y quien lo sigue. `members` sigue cerrada hasta billing | Con el grafo, negar ya no es lo único seguro. Una sola regla en `PostService` (`loadVisible` y el filtro de consulta) |
| S6 | **`feed.home` arma el feed por secciones en el servidor** (D6): `liveNow`, `following`, `suggestedAccounts` y `discover`. La primera página trae todas; las siguientes, `following` hasta agotarse y después `discover` | Determinístico: se puede testear y explicar en el video |
| S7 | **`discover`** son posts públicos de cuentas que no seguís y que no son tuyas, que comparten alguna etiqueta con lo que likeaste en los últimos 30 días. Si no likeaste nada, los más recientes. Orden por recencia con keyset; el filtro de etiquetas se aplica en Dart sobre lotes acotados | `tags` es una lista en JSON: la superposición no se expresa en el ORM. A la escala de la demo, filtrar lotes de 50 alcanza y mantiene el cursor estable |
| S8 | **El avatar se sube igual que un adjunto de post**: `requestAvatarUpload` devuelve un `MediaUploadTicket` con clave `avatars/<userId>/<uuid>.<ext>` y `setAvatar(key)` lo confirma. Se guarda la clave en `account_profile.avatarKey` | El mismo patrón probado de `posts`. La clave, no la URL: la URL la arma el storage y cambia de servidor a servidor |
| S9 | **Los autores muestran su avatar**: `PostView`, `PostCommentView`, `LiveShowView` y `LiveChatMessageView` suman `…AvatarUrl` nullable, resuelto por lote (`avatarsOf`) | Una consulta por página, como `profilesOf` |
| S10 | **Las notificaciones viven en un módulo `notifications`**. Tabla `user_notification` (no `notification`: `Notification` choca con la clase de Flutter) | D10: sólo dentro de la app y en tiempo real |
| S11 | **Una notificación se crea en la misma transacción que la acción que la origina y se publica después del commit**. Nadie se notifica a sí mismo | Si la acción se revierte, la notificación tampoco existe. Mismo principio que los vivos (SDD 0006) |
| S12 | **`liveStarted` avisa a los seguidores del host** cuando el vivo sale al aire, tanto por `start` como por `goLive` | Es lo que hace cualquier red social, y es el aviso que justifica seguir a alguien |
| S13 | **Un like repetido no notifica dos veces**: si ya hay un `postLiked` sin leer del mismo actor para el mismo post, no se crea otro | Dar y quitar like en un loop no debe llenar la bandeja de alguien |
| S14 | **Tiempo real por `notifications.watch()`**, canal `notifications:<userId>`. Igual que `live.watch`: suscribirse antes de cualquier `await` | El badge de Actividad cambia sin recargar. `user:<id>` queda para las sanciones de M6 |
| S15 | **Future Calls** (API tipada de 4.0.3) para tres cosas, con identificador por show: recordatorio 15 min antes (`show:<id>:reminder`), cancelación si a los 30 min del inicio no arrancó (`show:<id>:expire`) y publicación automática del replay 1 min después de terminar si `recordReplay` (`show:<id>:replay`) | D11 y la sección M5 del 0004. Cada llamada vuelve a verificar el estado: si el show ya cambió, no hace nada |
| S16 | **La programación pasa por una interfaz `ShowScheduler`** (`FutureCallShowScheduler` en el servidor; un fake que registra en los tests) | Los tests verifican qué se programó y cuándo sin esperar el reloj, y llaman a las Future Calls directo |
| S17 | **No hay códigos de error nuevos** | `invalidInput`, `notFound`, `conflict`, `forbidden` y `accountSuspended` alcanzan. Un código nuevo obliga a tocar el `switch` de la app |

---

## 3. Contrato

### 3.1 M2 — `social` (seguir) y `feed`

Modelos nuevos:

```yaml
class: Follow
table: follow
serverOnly: true
fields:
  followerId: UuidValue
  followeeId: UuidValue
  createdAt: DateTime, default=now
indexes:
  follow_pair_idx:
    fields: followerId, followeeId
    unique: true
  follow_followee_idx:
    fields: followeeId, createdAt
  follow_follower_idx:
    fields: followerId, createdAt
```

| Modelo | Campos |
|---|---|
| `AccountProfile` (suma) | `followerCount: int, default=0`, `followingCount: int, default=0` |
| `ProfileView` (suma) | `followerCount: int, default=0`, `followingCount: int, default=0`, `viewerFollows: bool, default=false` |
| `FollowState` | `userId`, `viewerFollows`, `followerCount` |
| `FollowPage` | `items: List<ProfileView>`, `nextCursor: PageCursor?` |
| `FeedSectionKind` (enum) | `liveNow, following, suggestedAccounts, discover` |
| `FeedItemKind` (enum) | `imagePost, videoPost, textPost, scheduledShow, liveShow, recordedShow` |
| `FeedItem` | `kind`, `post: PostView?`, `liveShow: LiveShowView?` |
| `FeedSection` | `kind`, `items: List<FeedItem>`, `accounts: List<ProfileView>` (sólo `suggestedAccounts`) |
| `HomeFeedCursor` | `followingAfter: PageCursor?`, `followingDone: bool`, `discoverAfter: PageCursor?`, `discoverDone: bool` |
| `HomeFeedPage` | `sections: List<FeedSection>`, `nextCursor: HomeFeedCursor?` |

`textPost` se suma a los kinds del 0004 porque hoy existen posts sin
adjuntos.

| Endpoint | Quién | Errores |
|---|---|---|
| `follows.follow(UuidValue userId) → FollowState` | Sesión activa | `unauthenticated`, `accountSuspended`, `invalidInput` (a sí mismo), `notFound` |
| `follows.unfollow(UuidValue userId) → FollowState` | Sesión | `unauthenticated`, `notFound` |
| `follows.followers(UuidValue userId, {PageCursor? after, int? limit}) → FollowPage` | Público | `notFound` |
| `follows.following(UuidValue userId, {PageCursor? after, int? limit}) → FollowPage` | Público | `notFound` |
| `follows.suggestions({int? limit}) → List<ProfileView>` | Público. Con sesión: creadores verificados y activos que no seguís, sin vos, por seguidores. Sin sesión: los creadores verificados más seguidos. Hasta 20, por defecto 10 | — |
| `feed.home({HomeFeedCursor? cursor}) → HomeFeedPage` | Público. Sin sesión, `following` va vacía | — |

Las secciones de la primera página son:

| Sección | Contenido |
|---|---|
| `liveNow` | Shows al aire, los de cuentas que seguís primero. Hasta 10 |
| `following` | Posts visibles de cuentas que seguís. 20 por página |
| `suggestedAccounts` | `suggestions(limit: 10)` |
| `discover` | S7. 20 por página |

Una sección vacía no se envía. `ProfileView` de `profiles.me`,
`profiles.byUsername` y `profiles.update` trae los contadores y
`viewerFollows` calculado para quien pregunta.

### 3.2 M1 — perfil y avatar (`identity`)

| Modelo | Campos |
|---|---|
| `AccountProfile` (suma) | `avatarKey: String?` |
| `PostView`, `PostCommentView` (suman) | `authorAvatarUrl: String?` |
| `LiveShowView` (suma) | `hostAvatarUrl: String?` |
| `LiveChatMessageView` (suma) | `authorAvatarUrl: String?` |

| Endpoint | Quién | Errores |
|---|---|---|
| `profiles.requestAvatarUpload(String contentType, int sizeBytes) → MediaUploadTicket` | Sesión. JPEG, PNG o WebP, hasta 5 MB | `invalidInput` |
| `profiles.setAvatar(String? key) → AccountView` | Sesión. `null` quita el avatar. La clave tiene que ser suya, armada por el servidor y ya subida | `invalidInput`, `forbidden` |
| `profiles.update(ProfileEdit) → AccountView` | Ya existe: username, nombre visible y bio | `invalidInput`, `conflict` |
| `profiles.becomeCreator() → AccountView` | Ya existe | — |

`avatarUrl` sale de `avatarKey` (URL pública del storage). Si no hay, cae a
la imagen de `UserProfile`.

### 3.3 M5 — `notifications`

```yaml
class: UserNotification
table: user_notification
serverOnly: true
fields:
  userId: UuidValue
  kind: NotificationKind
  actorId: UuidValue?
  postId: int?
  showId: int?
  readAt: DateTime?
  createdAt: DateTime, default=now
indexes:
  user_notification_feed_idx:
    fields: userId, createdAt
  user_notification_unread_idx:
    fields: userId, readAt
```

| Modelo | Campos |
|---|---|
| `NotificationKind` (enum, `byName`) | `newFollower, postLiked, postCommented, liveStarted, showStartingSoon, reportResolved` |
| `NotificationView` | `id`, `kind`, `actorId?`, `actorUsername?`, `actorName?`, `actorAvatarUrl?`, `postId?`, `postExcerpt?`, `showId?`, `showTitle?`, `isRead`, `createdAt` |
| `NotificationPage` | `items: List<NotificationView>`, `nextCursor: PageCursor?` |

| Endpoint | Quién |
|---|---|
| `notifications.list({PageCursor? after, int? limit}) → NotificationPage` | Sesión. De la más nueva a la más vieja |
| `notifications.unreadCount() → int` | Sesión |
| `notifications.markRead(List<int> ids) → int` | Sesión. Sólo las propias; devuelve las no leídas que quedan |
| `notifications.markAllRead() → int` | Sesión. Devuelve 0 |
| **`notifications.watch() → Stream<NotificationView>`** | Sesión. Cada notificación nueva, en el momento |

Quién genera qué:

| Acción | Notificación | A quién |
|---|---|---|
| `follows.follow` | `newFollower` | Al seguido |
| `likes.like` | `postLiked` (S13) | Al autor del post |
| `comments.create` | `postCommented` | Al autor del post |
| `live.start` / `live.goLive` | `liveStarted` | A los seguidores del host |
| Future Call `reminder` | `showStartingSoon` | A los seguidores del host y a los invitados |

**Future Calls** (`LiveShowFutureCall`, métodos con `Session` y `int showId`):

| Método | Se programa | Se cancela | Hace |
|---|---|---|---|
| `remind` | Al programar, en `startsAt − 15 min` (si es futuro) | Al iniciar o cancelar | Si sigue `scheduled`, notifica `showStartingSoon` |
| `expire` | Al programar, en `startsAt + 30 min` | Al iniciar o cancelar | Si sigue `scheduled`, lo pasa a `cancelled` (auditado como sistema) |
| `publishReplay` | Al terminar, si `recordReplay`, a +1 min | Al publicar a mano | Si sigue `recorded`, lo pasa a `published` |

---

## 4. App (para los agentes de app)

| Pieza | Cambio |
|---|---|
| Seguir | `FollowRepository` (dominio) con implementación Serverpod. Botón Seguir/Siguiendo en el perfil ajeno, con los contadores reales. "A quién seguir" sale de `suggestions` |
| Feed | `FeedItem` sellado en el dominio. El feed dibuja por sección; la fila de cuentas sugeridas es horizontal. "Siguiendo" usa la sección `following` |
| Perfil | Pantalla "Editar perfil" (username, nombre, bio, avatar con `image_picker` y `FileUploader`) y botón "Ser creador". `UserAvatar` suma `imageUrl` opcional |
| Actividad | `NotificationRepository` con `list`, `markRead`, `markAllRead`, `unreadCount` y `watch`. El badge de la barra se actualiza en vivo. Tocar una notificación lleva al post, al perfil o al vivo |
| Mock | `MockSocialStore` y las listas fijas salen del runtime con `AUTH_SOURCE=serverpod`; quedan para `AUTH_SOURCE=mock` y los tests (D15) |

---

## 5. Tests

**Backend:**

- **`follow_test`:**
  - Seguir dos veces deja un solo registro y `followerCount` en 1.
  - `unfollow` sin seguir no cambia nada.
  - Seguirse a uno mismo responde `invalidInput`; una cuenta suspendida, `accountSuspended`.
  - `followers` y `following` paginan.
  - `suggestions` no incluye a quien ya seguís ni a vos.
  - `viewerFollows` sale por quien pregunta.
- **`follow_concurrency_test`** (con `RollbackDatabase.disabled`): A sigue a B mientras B sigue a A, sin deadlock y con los contadores bien.
- **Visibilidad `followers`:** la ve el seguidor; el que no sigue recibe `notFound` y no la ve en el feed.
- **`feed_home_test`:**
  - Secciones y orden.
  - Un invitado no recibe `following`.
  - El cursor recorre `following` y después `discover` sin repetir.
  - `discover` prefiere las etiquetas likeadas.
- **`avatar_test`:**
  - Tipo o tamaño inválido responde `invalidInput`.
  - Una clave ajena responde `forbidden`.
  - Una clave no subida responde `invalidInput`.
  - `setAvatar(null)` quita el avatar.
  - `avatarUrl` aparece en `PostView`.
- **`notifications_test`:**
  - Cada acción de la tabla de §3.3 crea su notificación.
  - Nadie se notifica a sí mismo.
  - Un like repetido no duplica.
  - `markRead` sólo marca las propias.
  - `unreadCount` es correcto.
  - `watch` recibe en el momento.
- **`live_future_calls_test`:**
  - Programar registra `reminder` y `expire`; iniciar o cancelar los cancela; terminar con replay registra `publishReplay`.
  - Cada Future Call, invocada directo, respeta el estado actual.

**App:** cubits contra repositorios falsos (seguir, feed por secciones,
editar perfil, Actividad con stream) y los tests de arquitectura y de 320 px
de siempre.

```bash
cd services/serverpod/nexo_server
SERVERPOD_DATABASE_DATA_PATH="$HOME/.nexo-test/pgdata" SERVERPOD_PASSWORD_database=x dart test
```

---

## 6. Seed (D13)

- **Follows:** Tomás y Troll siguen a Elena; Elena sigue a Carlos; Carlos sigue a Elena.
- **Notificaciones:** dos `newFollower` y un `postLiked` para Elena.

Tiene guarda propia (si Tomás ya sigue a Elena, no hace nada), igual que
`_seedLive`.

---

## 7. Fases

| Fase | Qué | Aviso a la app |
|---|---|---|
| M2 ✅ | Migración `20261011205231471-follows`. `follows`, `feed.home`, visibilidad `followers`, contadores en `ProfileView` | "M2 servidor listo" |
| M1 ✅ | Migración `20261011205550198-avatar`. `requestAvatarUpload`, `setAvatar`, avatares de autores | "M1 servidor listo" |
| M5 ✅ | Migración `20261011205900478-notifications`. Módulo, `watch`, Future Calls, notificaciones desde `follows`, `likes`, `comments` y `live` | "M5 servidor listo" |

Notas de la implementación:
- `discover` decide su modo en cada pedido: filtra por etiquetas sólo si entre
  los 300 posts candidatos más recientes alguno comparte etiqueta con lo
  likeado; si no, va por recencia. Así nunca queda vacía por un filtro que no
  encuentra nada.
- `notifications.watch` no es `async*`: valida la sesión y abre el canal
  sincrónicamente, y un invitado recibe el `NexoException` como error del
  stream (seguido del cierre de la conexión).
- `FutureCallShowScheduler` registra y sigue si no puede programar: la acción
  que lo originó ya quedó hecha y auditada.

Fuera de este SDD: `reportResolved` se emite cuando M6 resuelva reportes
contra el servidor; push (D10); más de una instancia (R1 del 0004).
