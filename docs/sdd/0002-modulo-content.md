# SDD 0002 — Módulo `content` (posts con fotos y videos)

| | |
|---|---|
| Estado | **Implementado en el backend**, 2026-09-30. La app todavía usa el feed mock |
| Fecha | 2026-09-30 |
| Alcance | Publicar, leer, editar y eliminar posts de texto, fotos y videos |
| Código | `services/serverpod/nexo_server/lib/src/modules/content/` |
| Cliente | `client.posts` |

---

## 1. Objetivo

Primer módulo de dominio del backend. Da al feed principal una fuente real:
un creador publica con fotos o videos, edita y elimina lo suyo, y cualquiera
—incluido un invitado— lee el feed.

### No-objetivos (van en otros módulos)

| Qué | Módulo |
|---|---|
| Likes, lista de quién dio like, comentarios | `social` |
| Reportar un post, ocultar por moderación | `moderation` |
| Visibilidad `followers` y `members` efectiva | `social` y `billing` |
| Encuestas del compositor | Pendiente, sin módulo asignado |
| Perfil con `isCreator` y verificación | `identity` |

---

## 2. Decisiones

| # | Decisión | Por qué |
|---|---|---|
| D1 | Cualquier usuario con sesión publica | Es lo que ya hace la app (`/create` solo exige sesión). El gate de creador llega con `identity` |
| D2 | `followers` y `members` los ve **solo el autor** hasta que existan `social` y `billing` | Sin grafo de seguidores ni suscripciones, negar es lo único seguro. Un post así ya se puede crear; se abre solo cuando exista la regla |
| D3 | Eliminar es borrado lógico (`deletedAt`, `deletedBy`) + auditoría | Regla R3 del SDD 0001: nada se borra. Una auditoría que borra lo que audita no prueba nada |
| D4 | El autor, un moderador o un operador eliminan; **solo el autor edita** | Un moderador saca contenido, no lo reescribe |
| D5 | Los adjuntos no se editan | Cambiar la foto de un post con likes y comentarios cambia de qué hablan. Para otra foto, otro post |
| D6 | Un post ajeno que no puedes ver responde `notFound`, no `forbidden` | `forbidden` confirmaría que existe |
| D7 | `canEdit` y `canDelete` vienen en la respuesta | El servidor decide qué acciones se ofrecen; el cliente no muestra un botón que se va a rechazar |
| D8 | La clave del archivo la arma el servidor: `posts/<autor>/<tipo>/<uuid>.<ext>` | Al publicar, la clave misma prueba de quién es y qué tipo es. No hace falta una tabla de subidas pendientes y el cliente no elige rutas |
| D9 | Contadores `likeCount` y `commentCount` desnormalizados en `post` | El feed no cuenta filas por post. Los actualiza `social` en la misma transacción que crea o borra el like |
| D10 | Paginación keyset sobre `(createdAt, id)` con `PageCursor` | No repite ni saltea posts aunque alguien publique mientras se scrollea |

---

## 3. Flujo de publicación con archivos

```
app                               servidor                         storage
 │ requestMediaUpload(kind,type,size) │                                │
 │───────────────────────────────────>│ valida tipo y tamaño, arma key │
 │<──── ticket { key, description } ──│── createUploadDescription ────>│
 │ FileUploader(description).upload(bytes) ─────────────────────────────>│
 │ create(draft{ mediaKeys:[key] })   │                                │
 │───────────────────────────────────>│ key del autor? subida? libre?  │
 │                                    │── verifyUpload ───────────────>│
 │<──────────── PostView ─────────────│ inserta post + media (1 tx)    │
```

- **Tipos:** imagen JPEG, PNG, WebP o GIF hasta 10 MB; video MP4, MOV o WebM
  hasta 50 MB. Hasta 4 archivos por post.
- `sizeBytes` es el tamaño exacto: el storage rechaza una subida distinta.
- Un archivo subido que nunca se publica queda huérfano en el storage. En
  Serverpod Cloud caduca solo; en la base de datos (desarrollo) no. Aceptado.

---

## 4. Contrato

| Método | Sesión | Qué hace |
|---|---|---|
| `feed({after, limit})` | No | Feed del más nuevo al más viejo |
| `byAuthor(authorId, {after, limit})` | No | Posts de un perfil |
| `get(postId)` | No | Un post |
| `requestMediaUpload({kind, contentType, sizeBytes})` | Sí | Permiso de subida |
| `create(draft)` | Sí | Publica. Texto, archivos o ambos |
| `update(postId, edit)` | Autor | Texto, etiquetas, visibilidad, comentarios |
| `delete(postId)` | Autor o moderador | Borrado lógico auditado |

Errores: siempre `NexoException` con `unauthenticated`, `forbidden`,
`notFound`, `conflict` (archivo ya publicado) o `invalidInput`.

`Post` y `PostMedia` son `serverOnly`: el cliente recibe `PostView`, que no
expone `deletedAt` ni la clave del storage.

---

## 5. Testing

- **Unit** (`test/unit/content/`): normalización de etiquetas y texto, límites
  de página, tipos aceptados y claves que el servidor no armó.
- **Integración** (`test/integration/content/`): 18 casos de endpoint, entre
  ellos invitado rechazado, archivos en orden, archivo ajeno o sin subir,
  archivo reusado, paginación sin repetidos, visibilidad D2, edición D4,
  borrado auditado y borrado por moderador.

## 6. Pendiente

1. **App:** `ServerpodFeedRepository` detrás de `DATA_SOURCE=api`, selector de
   archivos (`image_picker`) y reproductor (`video_player`), y el menú `⋯` con
   editar y eliminar según `canEdit` y `canDelete`.
2. ~~**`social`** y **`moderation`**~~: hechos, ver
   [SDD 0003](0003-social-y-moderation.md). Ocultar por moderación usa el
   mismo borrado lógico que eliminar (`deletedBy` es el moderador).
4. Media privada para `members`: hoy todo va al storage `public`, así que
   quien tenga la URL de un archivo lo ve aunque no vea el post.
