# SDD 0010 — Mensajes directos

| | |
|---|---|
| Estado | **Aprobado**, 2026-10-12 |
| Qué es | Conversaciones 1 a 1 entre cuentas, en tiempo real, contra Serverpod |
| Por qué ahora | El usuario reportó "no funcionan las conversaciones": los botones Mensajes del feed y del perfil estaban apagados con "muy pronto". El SDD 0004 los había dejado fuera de alcance |
| Depende de | 0004 (D4 cuenta activa, D12 una instancia), 0006 (patrón de `watch`), 0008 (patrón de notificaciones y badge) |

---

## 1. Decisiones

| # | Decisión | Por qué |
|---|---|---|
| M1 | **Cualquier cuenta con sesión y activa le escribe a cualquier otra cuenta activa.** No a sí misma | Lo más simple que sirve para la demo. Bloquear y las "solicitudes de mensaje" quedan para el pitch |
| M2 | **Una conversación por par de cuentas.** La tabla guarda el par ordenado (`userA < userB` como texto) con índice único; `open` devuelve la que ya existe | Dos conversaciones para el mismo par parten la historia en dos |
| M3 | **`open` bloquea el par** con un advisory lock dentro de la transacción | Dos toques simultáneos en "Enviar mensaje" no crean dos filas ni fallan por el índice único |
| M4 | **Mensajes de texto**, de 1 a 1000 caracteres después del `trim`. Se guardan; se ordenan por id; la historia se pagina hacia atrás (`beforeId`) | El orden por id es el orden de llegada y no empata |
| M5 | **No leídos con un puntero por miembro** (`lastReadA`, `lastReadB`): el id del último mensaje leído. **Mandar un mensaje marca leída la conversación** para quien lo manda | Un contador por fila se desincroniza; un puntero no. Quien escribe vio lo anterior |
| M6 | **El badge cuenta conversaciones con algo sin leer**, no mensajes | Es lo que muestran las apps de mensajería: "3 chats", no "47 mensajes" |
| M7 | **Tiempo real por `messages.watch()`**, un stream por cuenta (canal `dm:<userId>`). Se suscribe antes de cualquier `await`, como `live.watch` y `notifications.watch`. Los eventos se publican **después del commit**, a los dos miembros | Si la transacción se revierte, nadie vio el mensaje |
| M8 | **El evento lleva el total de no leídos del destinatario** | El badge se actualiza sin otra consulta |
| M9 | **Un mensaje por segundo por cuenta**, en memoria (`rateLimited`), y **guard de cuenta activa** (`accountSuspended`) en `open` y `send`. A una cuenta suspendida no se le escribe (`forbidden`: `accountSuspended` en la app quiere decir "tu cuenta") | D4 del 0004 y el mismo límite que el chat de los vivos |
| M10 | **Sin notificación en Actividad** | Los mensajes tienen su propio badge; avisar en dos lugares lo mismo es ruido |
| M11 | La bandeja **no lista conversaciones vacías** (abiertas sin mensajes) | Abrir un chat y no escribir no tiene que dejar una fila vacía |

## 2. Modelos (`modules/messages/models/`)

| Modelo | Campos |
|---|---|
| `DmConversation` (tabla `dm_conversation`, `serverOnly`) | `userA`, `userB` (par ordenado, único), `lastReadA?`, `lastReadB?`, `lastMessageId?`, `lastActivityAt` (default now), `createdAt`. Índices por `userA, lastActivityAt` y `userB, lastActivityAt` |
| `DmMessage` (tabla `dm_message`, `serverOnly`) | `conversationId` (relación, cascade), `authorId`, `body`, `createdAt`. Índice `conversationId, id` |
| `DirectMessageView` | `id`, `conversationId`, `authorId`, `body`, `createdAt` |
| `ConversationView` | `id`, `other: ProfileView`, `lastMessage: DirectMessageView?`, `unreadCount`, `lastActivityAt` |
| `ConversationPage` | `items`, `nextCursor: PageCursor?` |
| `DirectMessagePage` | `items` (de la más vieja a la más nueva), `hasMore` |
| `DirectMessageEvent` | `kind` (`message`, `read`), `conversationId`, `message?`, `readerId?`, `lastReadMessageId?`, `unreadConversations` |

## 3. Endpoint `messages`

| Método | Quién | Errores |
|---|---|---|
| `conversations({PageCursor? after, int? limit}) → ConversationPage` | Sesión. Más reciente primero | `unauthenticated` |
| `open(UuidValue userId) → ConversationView` | Sesión activa | `invalidInput` (a sí mismo), `notFound`, `forbidden` (el otro no puede recibir: está suspendido), `accountSuspended` (la cuenta propia) |
| `conversation(int conversationId) → ConversationView` | Miembro. Para dibujar el chat cuando se abre directo | `forbidden`, `notFound` |
| `history(int conversationId, {int? beforeId, int? limit}) → DirectMessagePage` | Miembro | `forbidden`, `notFound` |
| `send(int conversationId, String body) → DirectMessageView` | Miembro activo | `forbidden` (no es miembro, o el otro está suspendido), `invalidInput`, `rateLimited`, `accountSuspended` |
| `markRead(int conversationId) → int` | Miembro. Devuelve las conversaciones que quedan sin leer | `forbidden` |
| `unreadCount() → int` | Sesión | — |
| **`watch() → Stream<DirectMessageEvent>`** | Sesión | `unauthenticated` |

## 4. App

- `features/messages/{data,domain,presentation}`, con `ServerpodMessagesRepository` y `MockMessagesRepository` elegidos en `injection.dart`.
- **Bandeja** (`AppRoutes.messages`, ruta raíz empujada sobre el shell) y **chat** (`AppRoutes.conversation(id)`, ídem).
- **Botón Mensajes del feed** con badge (cubit app-wide que sigue la sesión), y **"Enviar mensaje"** en el perfil ajeno.
- **Chat:** envío optimista con reintento, scroll anclado abajo, anteriores al llegar arriba, tiempo real con reconexión y marcar leído al abrir y mientras está abierto.

## 5. Tests

- **Servidor:**
  - Reglas puras.
  - Permisos de cada endpoint.
  - Par único, y par único con concurrencia (`RollbackDatabase.disabled`).
  - No leídos y `markRead`.
  - Paginación de bandeja e historia.
  - Rate limit.
  - Cuenta suspendida.
  - `watch` recibe el mensaje que manda el otro.
- **App:**
  - Cubits de bandeja, chat (optimista, reintento, tiempo real, reconexión) y badge.
  - Mapeo del repositorio.
  - Widgets de bandeja, chat y el botón del perfil.

## 6. Fuera de alcance

Bloquear, solicitudes de mensaje, grupos, adjuntos, "escribiendo…", borrar o
editar mensajes, y notificaciones push.
