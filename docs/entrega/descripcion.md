# Descripción para BuilderBase: Nexo Social

Textos para el formulario de envío de la hackathon "Build Something Real" de
Serverpod. Hay una versión larga, una corta y un post para redes. Todo lo que
dicen funciona hoy en producción. Lo que todavía no existe va sólo en "Qué
sigue".

---

## Datos del proyecto

| Campo | Valor |
|---|---|
| Nombre | **Nexo Social** |
| Frase | Una red social para creadores y sus comunidades, con vivos, chat y moderación en tiempo real, donde cada permiso lo decide el servidor. |
| App web (producción) | https://52-45-123-215.sslip.io/ |
| API (Serverpod) | https://api.52-45-123-215.sslip.io/ |
| Repositorio | https://github.com/JosueLemus/serverpod_social_media |
| Video | `[link de YouTube]` |
| Cuentas de demo | `elena@nexo.demo` (creadora), `tomas@nexo.demo` (usuario), `moderador@nexo.demo` (moderadora) y `troll@nexo.demo` (usuario). Contraseña: `nexo-demo-2026` |
| Stack | Flutter (Android, iOS, web, macOS) · Serverpod 4.0.3 · PostgreSQL 16 · Agora · AWS |
| Equipo | `[Nombre Apellido — rol]`, `[Nombre Apellido — rol]`, `[Nombre Apellido — rol]` |

---

## Versión larga

**Nexo Social** es una red social para creadores y sus comunidades, con vivos,
chat y moderación en tiempo real, donde cada permiso lo decide el servidor.

**El problema.** Quien transmite en vivo necesita que su comunidad se entere,
que el chat no se le vaya de las manos y que una decisión de moderación se
aplique para todos en el mismo momento. Si esas reglas viven en la app,
cualquiera las puede saltear, y una moderación sin registro no se puede
revisar.

**La solución.** Una app Flutter con un backend Serverpod que hace de
autoridad: decide quién transmite, quién modera y en qué estado está cada
vivo. En producción ya funcionan el registro con código por email, las
publicaciones con foto y video, likes, comentarios, seguir, la búsqueda y
perfiles con banner y contadores reales. Los vivos tienen video, chat y
espectadores, y avisan a los seguidores del creador. Un moderador oculta
comentarios en medio del vivo y resuelve una cola de reportes. Las
notificaciones y los mensajes directos llegan en tiempo real.

**Cómo usamos Serverpod.** El ORM, con diez migraciones y transacciones con
bloqueo de fila: cada acción de moderación y cada cambio de estado de un vivo
se audita en la misma transacción. La auth, con email y JWT, y los scopes
`moderator` y `admin`, que controla cada endpoint. Los Streaming
Methods (`live.watch`, `notifications.watch`, `messages.watch`) sobre
`session.messages`. Las Future Calls, que avisan 15 minutos antes de un show,
cancelan el que nunca arrancó y publican el replay solas. Cloud Storage, para
subir fotos, videos y avatares directo. Y tests de integración con
`withServerpod`, con casos de concurrencia. El token de video de Agora también
lo firma el servidor: la app nunca decide si transmite.

**Arquitectura.** Nueve módulos de dominio en el servidor y Clean
Architecture con BLoC en la app, en una VM de AWS con Docker Compose:
Serverpod, PostgreSQL y Caddy con HTTPS. Cada push a `main` corre los tests y
se despliega con GitHub Actions, que entra a AWS por OIDC, sin claves
guardadas.

**Cómo probarlo.** En https://52-45-123-215.sslip.io/, con `elena@nexo.demo`
o `moderador@nexo.demo` (contraseña `nexo-demo-2026`). El tiempo real se ve
con dos sesiones en dos dispositivos.

**Qué sigue.** Llevar al servidor la consola del operador (suspender, banear,
verificar), que hoy es una maqueta. Después, silenciar desde el chat, pagos y
membresías, notificaciones push y Serverpod Insights.

**Equipo.** `[nombres y roles]`.

---

## Versión corta

Nexo Social es una red social para creadores y comunidades: publicaciones,
vivos con video y chat, moderación y mensajes directos, todo en tiempo real.
Flutter en el cliente y Serverpod como autoridad: el servidor decide quién
transmite, quién modera y en qué estado está cada vivo. Usa el ORM con
transacciones auditadas, auth con scopes, Streaming Methods, Future Calls para
avisos y replays, y Cloud Storage. Está en producción en AWS, con deploy
automático: https://52-45-123-215.sslip.io/

---

## Si el formulario pide el detalle de Serverpod

| Pieza | Cómo la usa Nexo | Dónde |
|---|---|---|
| **ORM y migraciones** | Diez migraciones, que el servidor aplica al arrancar (`--apply-migrations`). Las transiciones de un vivo bloquean la fila (`LockMode.forUpdate`), y la auditoría (`AuditLog`) se escribe en la misma transacción: si la acción falla, no queda registro, y si queda registro, la acción ocurrió | `services/serverpod/nexo_server/migrations/`, `lib/src/shared/audit/` |
| **Auth y scopes** | Serverpod Auth con email (código de 8 dígitos que vence a los 15 minutos, enviado por SMTP) y JWT con refresh. Los scopes `moderator` y `admin` deciden quién oculta, quién resuelve la cola y quién cambia un show ajeno. Sin scope, `forbidden` | `lib/server.dart`, `lib/src/shared/auth/auth_context.dart` |
| **Streaming Methods y `session.messages`** | `live.watch` (chat, comentarios ocultos, espectadores y estado), `live.watchIndex` ("En vivo ahora"), `notifications.watch` y `messages.watch`. Los eventos se publican después del commit, así que nadie ve algo que se revirtió | `lib/src/modules/live/`, `notifications/`, `messages/` |
| **Future Calls** | `LiveShowFutureCall`: `remind` (15 minutos antes), `expire` (cancela el show que a los 30 minutos no arrancó) y `publishReplay` (un minuto después de terminar). Quedan guardadas en la base y sobreviven a un reinicio. Cada una vuelve a mirar el estado, así que un reintento no duplica nada | `lib/src/modules/live/future_calls/live_show_future_call.dart` |
| **Cloud Storage** | Subida directa (`createUploadDescription`), y después `verifyUpload` antes de crear la publicación. En AWS el proveedor es `DatabaseCloudStorage`, así que los archivos quedan en Postgres. Pasar a S3 es cambiar el proveedor en `server.dart` | `lib/src/shared/gateways/serverpod_media_storage_gateway.dart` |
| **Tests** | 37 archivos de test en el servidor, 26 de ellos de integración con `withServerpod`. Entre ellos hay casos de concurrencia con `RollbackDatabase.disabled` (seguir, reportes, mensajes, creación del perfil) y streams probados de punta a punta (`live.watch`, `notifications.watch`, `messages.watch`). En CI corren contra un PostgreSQL temporal | `services/serverpod/nexo_server/test/` |

**Lo que no usamos, para que quede claro:** Serverpod Cloud (el equipo eligió
AWS), el web server de Serverpod (la web la sirve Caddy) y Serverpod Insights.

---

## Post para redes

El handle de Serverpod en X es **@ServerpodDev**, no `@serverpod_dev`: ese
no apareció en la búsqueda, y el pie del sitio oficial (serverpod.dev) enlaza
a `x.com/ServerpodDev` (revisado el 12/10/2026). En LinkedIn, la página es
`linkedin.com/company/serverpod`: se etiqueta escribiendo "@Serverpod" y
eligiendo la página de la empresa.

Antes de publicar, revisar en las bases si piden un hashtag oficial. Los
textos van en bloques de código para copiarlos tal cual, con sus saltos de
línea.

### LinkedIn

```text
Presentamos Nexo Social, nuestro proyecto para la hackathon Build Something Real de @Serverpod.

Es una red social para creadores y comunidades: publicaciones con foto y video, vivos con chat, moderación y mensajes directos, todo en tiempo real. Flutter en el cliente y Serverpod en el servidor, que es quien decide los permisos: quién transmite, quién modera y qué ve cada uno.

Del lado de Serverpod usamos el ORM con transacciones y migraciones, auth con scopes, Streaming Methods, Future Calls (avisos, vencimientos y replays automáticos) y Cloud Storage. Está desplegado en AWS, y cada push a main se prueba y se despliega solo.

Video (menos de 2 minutos): [link del video]
Código: https://github.com/JosueLemus/serverpod_social_media
Probarlo: https://52-45-123-215.sslip.io/

[etiquetar a las personas del equipo]

#Flutter #Dart #Serverpod
```

### X

Ocupa unos 271 de los 280 caracteres (X cuenta cada link como 23).

```text
Nexo Social: red social para creadores con vivos, chat, moderación y mensajes en tiempo real. Flutter + Serverpod, en producción en AWS. Hecho para Build Something Real de @ServerpodDev.

Video: [link del video]
Código: https://github.com/JosueLemus/serverpod_social_media

#Flutter #Serverpod
```
