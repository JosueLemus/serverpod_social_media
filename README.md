# Nexo Social

Una red social para creadores y comunidades: publicaciones con fotos y
videos, vivos con chat en tiempo real y una moderación que el servidor aplica
y deja auditada. Flutter en el cliente, **Serverpod** de punta a punta en el
servidor.

## Probarlo en un comando

Requisitos: **Flutter 3.47.5 o superior** y Chrome. No hace falta Docker: la
base de datos es un PostgreSQL embebido que levanta Serverpod.

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

### Email de los códigos de verificación

Sin SMTP, el código de una cuenta nueva aparece en
`docker compose logs server`. Para mandarlo por correo, el deploy toma estas
variables:

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
