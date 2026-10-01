# Módulos

Una carpeta por módulo: `identity`, `content`, `social`, `live`, `moderation`,
`billing`, `notifications` y `ai`. Cada una tiene:

```text
<modulo>/
  models/     # *.spy.yaml: tablas y DTOs
  services/   # reglas de negocio y transacciones
  endpoints/  # entrada fina: login, validación, delega en el service
```

## Estado

| Módulo | Estado | Diseño |
|---|---|---|
| `content` | Posts con fotos y videos: `client.posts` | [SDD 0002](../../../../../../docs/sdd/0002-modulo-content.md) |
| `social` | Likes y comentarios: `client.likes`, `client.comments` | [SDD 0003](../../../../../../docs/sdd/0003-social-y-moderation.md) |
| `moderation` | Reportes y cola: `client.moderation` | [SDD 0003](../../../../../../docs/sdd/0003-social-y-moderation.md) |
| `identity`, `live`, `billing`, `notifications`, `ai` | Sin empezar | — |

Para cada funcionalidad nueva:

1. Crear o editar el modelo en `models/*.spy.yaml`.
2. Ejecutar `serverpod generate`.
3. Si cambió alguna tabla, ejecutar `serverpod create-migration`.
4. Escribir las reglas en el service.
5. Escribir el endpoint (usar `session.requireUserId` de `shared/auth`).
6. Añadir un test en `test/integration/<modulo>/`.
