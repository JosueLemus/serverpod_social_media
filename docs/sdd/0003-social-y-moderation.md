# SDD 0003 — Módulos `social` y `moderation`

| | |
|---|---|
| Estado | **Implementado en el backend**, 2026-10-01. La app todavía usa mocks |
| Fecha | 2026-10-01 |
| Alcance | Likes, lista de quién dio like y comentarios de posts; reportar posts y comentarios, cola de moderación y resolver |
| Código | `nexo_server/lib/src/modules/social/` y `.../moderation/` |
| Cliente | `client.likes`, `client.comments`, `client.moderation` |

---

## 1. Por qué dos módulos

Like y reporte parecen lo mismo —un botón sobre un post— pero no se parecen
en nada más:

| | Like / comentario | Reporte |
|---|---|---|
| Lo lee | El creador y otros espectadores | Moderadores, en una cola |
| Dispara | Contadores | Un proceso: abierto → resuelto, con auditoría |
| Sobre qué | Posts | Posts, comentarios y, después, comentarios de vivos y cuentas |
| Volumen | Alto | Bajo |

Por eso `social` tiene likes y comentarios (y tendrá los follows que abren la
visibilidad `followers`) y `moderation` tiene un solo tipo de reporte para todo
lo reportable, que es lo que ya modela la consola de la app.

### Dependencias

```
content  ◄──  social  ◄──  moderation
   └────── lee post_like (isLiked) ──┘
```

- `social` y `moderation` actúan sobre posts a través de `PostService`
  (`loadVisible`, `markRemoved`, `adjustCounts`), nunca escribiendo la tabla.
  "Quién ve un post" sigue siendo una sola regla.
- La única excepción: `content` lee `post_like` para llenar `PostView.isLiked`.
  Pedirle el dato a `social` costaría una consulta por post o un segundo viaje
  de la app.

---

## 2. Decisiones

| # | Decisión | Por qué |
|---|---|---|
| D1 | Dar y quitar like son idempotentes y devuelven el contador ya actualizado | Un doble toque o un reintento de red no descuadran nada, y la app no adivina el número |
| D2 | Los contadores se actualizan con el post bloqueado (`FOR UPDATE`) en la misma transacción | Dos likes simultáneos no se pisan |
| D3 | Quitar un like borra la fila; eliminar un comentario la marca (`deletedAt`) | Un like no es contenido; un comentario sí, y R3 dice que el contenido no se borra |
| D4 | Borran un comentario su autor, **el autor del post** y el staff | El creador modera su propio espacio sin esperar a un moderador |
| D5 | Comentarios planos, del más viejo al más nuevo | Se leen como conversación. Respuestas anidadas, después |
| D6 | `allowComments: false` rechaza comentarios nuevos con `forbidden` | Los existentes se siguen viendo |
| D7 | La severidad la decide el servidor por el motivo, igual que la app | Quien reporta pondría todo en "alta" |
| D8 | La cola muestra **un ítem por contenido**, con su severidad más alta y la cantidad de reportes | Diez reportes del mismo post son una sola revisión |
| D9 | Resolver aplica la decisión y cierra **todos** los reportes abiertos del contenido en una transacción, con una entrada de auditoría | Regla del SDD 0001: ocultar sin cerrar deja trabajo ya hecho en la cola |
| D10 | Decisiones: `hideContent` y `dismiss` | Silenciar y expulsar necesitan el estado de la cuenta (`identity`) |
| D11 | No se puede reportar contenido propio; repetir un reporte abierto no crea otro | Ruido que la cola no necesita |
| D12 | Si el autor ya eliminó lo reportado, la cola lo marca `targetRemoved` | Solo queda descartar |

---

## 3. Contrato

| Método | Quién | Qué hace |
|---|---|---|
| `likes.like(postId)` / `unlike(postId)` | Sesión | Devuelve `LikeState { isLiked, likeCount }` |
| `likes.likers(postId, {after, limit})` | Quien ve el post | Quién dio like, paginado |
| `comments.list(postId, {after, limit})` | Quien ve el post | Comentarios, paginados |
| `comments.create(postId, body)` | Sesión | Hasta 1000 caracteres |
| `comments.delete(commentId)` | D4 | Borrado lógico, auditado |
| `moderation.report({targetType, targetId, reason, details})` | Sesión | `targetType`: `post` o `postComment` |
| `moderation.queue({limit})` | Staff | Ítems por contenido, más graves primero |
| `moderation.resolve(reportId, decision)` | Staff | D9 |

`PostView` suma `isLiked` (con default, compatible con clientes viejos).

---

## 4. Probarlo con un moderador

No hay todavía una pantalla para dar roles (es del módulo `identity`). En
desarrollo, se da el scope a mano en la base local y se vuelve a iniciar
sesión, porque los scopes viajan en el token:

```sql
UPDATE serverpod_auth_core_user
SET "scopeNames" = '["moderator"]'
WHERE id = '<authorId de tu cuenta>';
```

La base de desarrollo es la PostgreSQL embebida: `localhost:8090`, base
`nexo`, usuario `postgres`, contraseña `development.database` de
`config/passwords.yaml`.

## 5. Testing

- **Unit:** severidad por motivo y recorte del extracto.
- **Integración:** 8 casos de likes, 11 de comentarios y 11 de moderación
  (cola agrupada y ordenada, permisos, ocultar post y comentario con su
  contador, auditoría única, reporte ya resuelto, contenido ya eliminado).
- Los helpers comunes viven en `test/integration/support/fixtures.dart`.

## 6. Pendiente

1. **`identity`:** perfil con usuario y nombre, `isCreator`, estado de cuenta.
   Habilita silenciar y expulsar desde `resolve` y una pantalla para dar roles.
2. **Follows** en `social`, que abren la visibilidad `followers`.
3. Reportar comentarios de vivos y cuentas, cuando existan `live` e `identity`.
4. **App:** repositorios Serverpod para feed, likes, comentarios y la cola de
   moderación detrás de `DATA_SOURCE=api`.
