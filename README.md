# Nexo Social

Una red social para creadores y comunidades: publicaciones con fotos y
videos, vivos con chat en tiempo real y una moderación que el servidor aplica
y deja auditada. Flutter en el cliente, **Serverpod** de punta a punta en el
servidor.

## Probarlo ya, sin instalar nada

Nexo está desplegado en AWS. Cada push a `main` se despliega solo.

| | |
|---|---|
| **App web** | **https://52-45-123-215.sslip.io/** |
| **API (Serverpod)** | https://api.52-45-123-215.sslip.io/ |
| **App Android** | APK de release (pedila al equipo). Apunta a la misma API |
| **Video de la demo** | _(link pendiente)_ |

Entrá con **"Elegir cuenta de demo"** en la pantalla de bienvenida, o con
cualquiera de las [cuentas de demo](#cuentas-de-demo) (contraseña
`nexo-demo-2026`). Para ver el tiempo real, abrí dos sesiones con cuentas
distintas, por ejemplo Elena en un teléfono y Tomás en la web: un vivo, un
comentario, un mensaje directo o un seguimiento aparecen en el otro lado sin
recargar.

## Probarlo en un comando (local)

Requisitos: **Flutter 3.47.5 o superior** y Chrome. No hace falta Docker: la
base de datos es un PostgreSQL embebido que levanta Serverpod.

> **Cloná el repo en una ruta sin espacios** (por ejemplo `~/dev/nexo`, no
> `~/mis proyectos/nexo`). El PostgreSQL embebido de Serverpod no arranca si
> su carpeta de datos queda en una ruta con espacios. `tool/demo.sh` lo
> esquiva para la base de desarrollo, pero los tests del servidor no.

```bash
git clone https://github.com/JosueLemus/serverpod_social_media.git
cd serverpod_social_media
tool/demo.sh
```

El script instala el CLI de Serverpod si falta, genera los secretos de
desarrollo, levanta el servidor con datos de demo y abre la app en Chrome.

### Cuentas de demo

Todas con la contraseña **`nexo-demo-2026`**, o con el botón **"Elegir
cuenta de demo"** de la pantalla de bienvenida.

| Cuenta | Rol | Para qué |
|---|---|---|
| `elena@nexo.demo` | Creadora verificada | Publica e inicia vivos |
| `carlos@nexo.demo` | Creador verificado | Otro creador |
| `operador@nexo.demo` | Operador (scope `admin`) | Consola: sanciones, verificación, auditoría |
| `moderador@nexo.demo` | Moderador | Cola de reportes |
| `tomas@nexo.demo` | Usuario | Comenta y reporta |
| `troll@nexo.demo` | Usuario | El que recibe la sanción |

Una cuenta nueva también funciona: el código de verificación aparece en el
log del servidor (el script dice dónde está).

### Opciones

```bash
tool/demo.sh -d <device-id>     # la app en un teléfono (flutter devices)
tool/demo.sh --server-only      # sólo el servidor
API_HOST=192.168.1.20 tool/demo.sh -d <android>   # el teléfono llega al servidor por la IP de la máquina
AGORA_APP_ID=<app-id> tool/demo.sh                # video real en los vivos (Agora, modo de prueba)
AGORA_APP_ID=<app-id> AGORA_APP_CERTIFICATE=<cert> tool/demo.sh   # proyecto con certificado: el servidor firma los tokens
```

Si el proyecto de Agora tiene **App Certificate**, sin `AGORA_APP_CERTIFICATE`
el video no conecta (`errInvalidToken`): el token lo emite el servidor
(`live.mediaToken`) y el certificado nunca llega a la app. En vez de pasarlo
por el entorno, se puede dejar en `services/serverpod/nexo_server/config/passwords.yaml`,
que no se versiona:

```yaml
development:
  agoraAppId: '<app-id>'
  agoraAppCertificate: '<certificado>'
```

## Producción en AWS

Una sola VM con todo adentro (SDD 0009): el servidor Serverpod, Postgres y
Caddy, con HTTPS gratis por [sslip.io](https://sslip.io). La API queda en
`https://api.<ip-con-guiones>.sslip.io/` y la web en
`https://<ip-con-guiones>.sslip.io/`.

```bash
tool/aws/provision.sh                # crea la VM (t4g.micro), la IP fija y el firewall
tool/aws/deploy.sh <ip>              # imagen, compose, secretos, Caddy y backups
tool/aws/deploy.sh <ip> --web        # además, la app web de Flutter
```

- **Imagen:** `deploy.sh` compila la imagen en la máquina de desarrollo para
  `linux/arm64` y la carga en la VM con `docker save` / `docker load`. No
  usa un registro.
- **Secretos:** el primer deploy los genera en la VM, en `/opt/nexo/.env`
  (`chmod 600`). Las claves están documentadas en
  `services/serverpod/deploy/aws/.env.example`.
  - Los de Agora salen del `passwords.yaml` local y viajan por SSH.
  - `passwords.yaml` nunca entra a la imagen: lo excluye
    `services/serverpod/.dockerignore`.
- **Cuentas de demo:** el servidor corre en `staging`, donde el seed está
  habilitado. En `production` no lo está.
- **Backups:** `pg_dump` diario a `/opt/nexo/backups`, con 7 días de
  retención.

### Deploy automático: cada push a `main`

`.github/workflows/deploy.yml` hace esto en cada push a `main`:

1. Corre los tests del backend y de la app (los mismos workflows `Backend` y `App` de los PR). Si alguno falla, no se despliega nada.
2. Compila la imagen del servidor en un runner **ARM**, que es la arquitectura de la VM, y la web de Flutter contra la API pública.
3. Despliega con el mismo `tool/aws/deploy.sh` que se usa a mano, y después prueba que la API y la web respondan. El resumen de la corrida muestra los links.

Dos deploys nunca corren a la vez: el segundo espera al primero.

**Credenciales: ninguna vive en el repo.**

| Dónde | Qué |
|---|---|
| AWS | **Sin claves.** El workflow asume el rol `nexo-github-deploy` por OIDC. Sólo lo asumen los workflows de la rama `main` de este repo, y su único permiso es abrir y cerrar el puerto 22 del security group de Nexo |
| SSH | Cerrado al mundo. Cada corrida abre el 22 sólo para la IP del runner y lo cierra al terminar, falle o no. La huella del servidor está fijada: si cambia, el deploy se corta |
| GitHub Secrets | `NEXO_SSH_PRIVATE_KEY`, `NEXO_SSH_KNOWN_HOSTS`, los secretos del servidor (`NEXO_DB_PASSWORD`, `NEXO_SERVICE_SECRET`, `NEXO_JWT_PRIVATE_KEY`, `NEXO_JWT_REFRESH_PEPPER`, `NEXO_EMAIL_PEPPER`), `AGORA_APP_ID`, `AGORA_APP_CERTIFICATE` y, opcionales, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD` y `SMTP_FROM` |
| GitHub Variables | `AWS_REGION`, `AWS_DEPLOY_ROLE_ARN`, `NEXO_VM_IP` y `NEXO_SG_ID`. No son secretos |

**Configurarlo desde cero** (después de `provision.sh` y del primer `deploy.sh`):

```bash
tool/aws/setup-github-deploy.sh   # crea el rol y carga secretos y variables, sin imprimir valores
```

Los secretos del servidor se copian de la VM: desde ese momento, GitHub Secrets es la fuente de verdad y cada deploy los vuelve a escribir.

**Para activar el email**, cargá `SMTP_*` como secretos (`gh secret set SMTP_PASSWORD`) y corré el workflow a mano (`gh workflow run deploy.yml`) o esperá el próximo push.

### Email de los códigos de verificación

Registrarse y restablecer la contraseña mandan un código de 8 números, que
vence a los 15 minutos. Sin SMTP, el código aparece en
`docker compose logs server`, que es lo que pasa hasta cargar la contraseña de
Gmail. Las cuentas de demo no lo necesitan.

**Activarlo en producción, gratis, con Gmail (unos 500 mails por día):**

1. En la cuenta de Google que envía, activá la **verificación en 2 pasos**
   (https://myaccount.google.com/signinoptions/twosv). Sin eso Google no deja
   crear contraseñas de aplicación.
2. Creá una **contraseña de aplicación** en
   https://myaccount.google.com/apppasswords, con el nombre "Nexo". Google
   muestra 16 letras en cuatro grupos; los espacios no importan.
3. Desde el repo, con `gh` logueado, corré:

   ```bash
   tool/aws/set-smtp-password.sh
   ```

   Pide la contraseña sin mostrarla, la guarda en GitHub Secrets
   (`SMTP_PASSWORD`, junto con `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER` y
   `SMTP_FROM`) y dispara el deploy. Desde ese momento los códigos llegan por
   mail, y el log sólo dice a quién se mandó, sin el código.

Si el envío falla (contraseña revocada, límite diario de Gmail), el registro
no se corta: el log dice `Failed to send verification email … via
smtp.gmail.com` y la persona puede tocar **Solicitar un código nuevo**.

Para un deploy a mano, sin CI, el script de deploy toma las mismas variables:

```bash
# Gmail: una dirección con verificación en dos pasos y una contraseña de aplicación
SMTP_HOST=smtp.gmail.com SMTP_PORT=587 SMTP_USER=tu.cuenta@gmail.com \
SMTP_PASSWORD=<contraseña de aplicación> tool/aws/deploy.sh <ip>

# Brevo: 300 correos por día gratis. El login y la clave SMTP están en su panel
SMTP_HOST=smtp-relay.brevo.com SMTP_PORT=587 SMTP_USER=<login SMTP> \
SMTP_PASSWORD=<clave SMTP> SMTP_FROM=<remitente verificado> tool/aws/deploy.sh <ip>
```

### Variables de entorno que sobreescriben la config

El servidor lee `config/staging.yaml`, y el entorno pisa cualquier valor. Las
que usa este deploy:
- `SERVERPOD_API_SERVER_PUBLIC_HOST`: el host de las URLs de archivos.
- `SERVERPOD_PASSWORD_<clave>`: cada secreto. Sirve para claves propias, como
  `agoraAppCertificate` o `smtpHost`.

Hay más, todas en `serverpod_shared` (`environment_variables.dart`):
`SERVERPOD_DATABASE_HOST`, `_PORT`, `_NAME`, `_USER` y `_REQUIRE_SSL`;
`SERVERPOD_FUTURE_CALL_ENABLED`; `SERVERPOD_SESSION_CONSOLE_LOG_ENABLED`;
`SERVERPOD_MAX_REQUEST_SIZE`.

## Estructura

```text
apps/
  nexo_social/       # App Flutter: móvil, web y escritorio
services/
  serverpod/         # Backend Serverpod: módulos, migraciones, cliente generado
docs/sdd/            # Diseño: qué se construye, por qué y en qué orden
tool/demo.sh         # Demo local en un comando
```

## Desarrollo

```bash
# App
cd apps/nexo_social
flutter analyze && flutter test

# Backend
cd services/serverpod/nexo_server
SERVERPOD_PASSWORD_database=cualquier-valor dart test
```

Las reglas de arquitectura, diseño y testing están en `CLAUDE.md`. El estado
del proyecto y el plan, en `docs/sdd/` (empezar por el 0004 y el 0005).
