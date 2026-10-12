# SDD 0009 — Dónde vive el backend: el deploy de Nexo

| | |
|---|---|
| Estado | **Aprobado**, 2026-10-11: **AWS, una sola VM con todo adentro** (§4). Las decisiones están en §5 |
| Qué es | Dónde se despliega el servidor Serverpod, qué exige el código de hoy de un host, las opciones con su costo y el plan para la opción elegida |
| Depende de | SDD 0004 (M8, D12, R1), 0005 (V3: "sin deploy" se decidió por falta de cuenta, no por diseño), 0006 (vivos, token de Agora), 0008 (Future Calls, notificaciones) |
| Entrega | 14/10/2026 23:59. El deploy tiene que estar andando el 13, para grabar y para que el jurado tenga un link |

---

## 1. Por qué ahora

Hoy el servidor corre en una Mac. Un teléfono llega por cable (`adb reverse`)
o por la misma red Wi-Fi (`API_HOST`). Eso alcanza para grabar, pero no para
que alguien fuera de la casa abra la app: el APK de Drive apunta a
`192.168.0.13`, que sólo existe en esa red y sólo mientras la Mac está
prendida.

El SDD 0005 decidió "sin deploy" (V3) porque no había cuenta de Serverpod
Cloud, y dejó escrito que el deploy se suma en medio día cuando aparezca. Las
bases de la hackathon miden "¿Funciona?" (30%) y "Uso del stack de
Serverpod" (25%): un link que el jurado abre suma a los dos.

---

## 2. Qué le exige el código de hoy a un host

No es una lista genérica: cada fila sale de algo que ya está escrito.

| # | Requisito | Por qué, en el código |
|---|---|---|
| H1 | **Un proceso siempre prendido, una sola instancia** | La presencia de los vivos (`LivePresence`) y el límite del chat viven en memoria, y `session.messages` publica en local porque no hay Redis (D12/R1 del 0004). Con dos instancias, la mitad de los espectadores no ve el chat de la otra mitad. Un host que apaga el proceso sin tráfico corta los vivos |
| H2 | **WebSockets de larga duración** | `live.watch`, `live.watchIndex` y `notifications.watch` son Streaming Methods |
| H3 | **Future Calls** | `LiveShowFutureCall` (0008): recordatorio −15 min, expiración +30 min y replay publicado solo. Si el proceso duerme o el plan las desactiva, no corren |
| H4 | **PostgreSQL 16 con migraciones** | 9 migraciones; el servidor las aplica con `--apply-migrations` |
| H5 | **Almacenamiento de archivos** | `ServerpodCloudProvider.private/public` usa los buckets de Serverpod Cloud y, **fuera de Cloud**, cae a `DatabaseCloudStorage`: los bytes de fotos, videos (hasta 50 MB) y avatares quedan dentro de Postgres |
| H6 | **Email de verificación** | `ServerpodCloudEmailIdpConfig`: en `development` el código va a la consola; en `staging`/`production` **se manda por el servicio de email de Serverpod Cloud**. Fuera de Cloud hay que cambiarlo a `EmailIdpConfigFromPasswords` con un proveedor propio, o una cuenta nueva nunca recibe su código |
| H7 | **HTTPS y WSS con dominio** | La app web exige `https` (un navegador bloquea la API en `http` como contenido mixto). En Android `http` funciona, pero un token de sesión no viaja en claro en producción |
| H8 | **Secretos** | `database`, `serviceSecret`, `jwtHmacSha512PrivateKey`, `jwtRefreshTokenHashPepper`, `emailSecretHashPepper`, `agoraAppId`, `agoraAppCertificate`. Los de producción son **nuevos**: no se reusan los de la Mac |
| H9 | **Cuentas de demo** | `_seedDemoIfAsked` sólo siembra en `development`, a propósito: en producción una variable de entorno no puede crear una cuenta con scope `admin`. Sin una decisión (§5, Q3), el deploy arranca sin Elena, sin operador y sin moderador |

---

## 3. Opciones

Precios consultados el 2026-10-11, en USD salvo indicación. Los de terceros
cambian seguido: se revisan en la consola de cada uno antes de pagar.

| | **A. Serverpod Cloud** | **B. Railway** | **C. Fly.io** | **D. Render** | **E. VPS + Docker Compose** | **F. GCP/AWS con Terraform** |
|---|---|---|---|---|---|---|
| Cómo se despliega | `serverpod cloud launch` y después `serverpod cloud deploy` | Desde el repo con el `Dockerfile` que ya existe | `fly launch` con el `Dockerfile` | Docker o Git | `docker compose up` (servidor + Postgres + Caddy) en una VM | Los scripts oficiales de Serverpod |
| Postgres | Gestionado, con backups y migraciones automáticas | Servicio de Railway | Gestionado desde ~38/mes, o uno externo (Neon, Supabase) | El gratis vence a los 30 días | En la misma VM; los backups son tuyos | Cloud SQL o RDS |
| Archivos (H5) | **Buckets propios**, sin tocar código | En Postgres (fallback) | En Postgres, o S3/R2 con cambios | En Postgres | En Postgres, o S3/R2 | GCS o S3 |
| Email (H6) | **Anda sin tocar código** | Hay que cambiarlo | Hay que cambiarlo | Hay que cambiarlo | Hay que cambiarlo | Hay que cambiarlo |
| H1 / H2 / H3 | Sí. **Future Calls sólo desde Growth** | Sí | Sí, con `auto_stop` apagado | **No en el plan gratis**: duerme a los 15 min sin tráfico y tarda ~1 min en despertar | Sí | Sí en VM; **Cloud Run escala a cero** |
| HTTPS (H7) | Incluido, con subdominio de Serverpod | Incluido (`*.up.railway.app`) | Incluido (`*.fly.dev`) | Incluido | Caddy + un dominio (o `sslip.io`) | Balanceador |
| Web de Flutter | **Hosting incluido** | Otro servicio | Otro servicio | Sitio estático gratis | El mismo Caddy | Bucket + CDN |
| Costo aprox. | **Starter 5/mes** (1 podlet de 256 MB, 1 base S, sin Future Calls). **Growth 20/mes + uso** (podlet S ~19/mes + base S ~31/mes ≈ **70/mes**). **1 mes gratis** en el primer proyecto, sin tarjeta | Hobby: 5/mes de mínimo, que incluye 5 de uso. Server chico + Postgres ≈ **5–15/mes**. Prueba con crédito | Máquina 256 MB ~2/mes + IPv4 2/mes + Postgres. Con Postgres externo gratis ≈ **5–10/mes**. Pide tarjeta | Gratis con las limitaciones de arriba; pago ~7 + Postgres | Hetzner CX22 ~4,5 €/mes (2 vCPU, 4 GB); hay reportes de stock limitado. DigitalOcean desde ~6 | GCP ≈ **36/mes** (VM 7 + balanceador 19 + Cloud SQL 10) |
| Trabajo para nosotros | **Bajo**: secretos y seed | Medio: email, `publicHost`, seed | Medio: igual que B, más el Postgres | Medio, y no sirve gratis | **Alto**: servidor, TLS, backups, actualizaciones | Alto |
| Para la nota | **Suma a "Uso del stack"**: Cloud, buckets, email y web, todo de Serverpod | Neutro | Neutro | Neutro | Neutro | Neutro |

---

## 4. Decisión: AWS, una VM con todo adentro

El equipo eligió **no usar Serverpod Cloud**. El backend sigue siendo
Serverpod y se despliega en **AWS** (la cuenta configurada en la máquina de
desarrollo, `us-east-1`), en la opción más barata que cumple §2.

| Pieza | Qué | Por qué |
|---|---|---|
| Máquina | **EC2 `t4g.micro`** (ARM Graviton, 2 vCPU, 1 GB) + 2 GB de swap + gp3 de 10 GB | Es la más chica en la que entran Postgres, Serverpod y Caddy sin que el kernel mate procesos en medio de un vivo. La `t4g.nano` (512 MB) ahorra ~3 USD/mes a cambio de ese riesgo |
| Contenedores | `docker compose`: `server` (la imagen del `Dockerfile`), `postgres:16-alpine` (volumen persistente) y `caddy:2-alpine` | Todo en una VM: H1 se cumple sin Redis ni cambios de código |
| HTTPS (H7) | **Caddy + sslip.io**: `api.<ip>.sslip.io` → servidor, `<ip>.sslip.io` → la web de Flutter. Certificados de Let's Encrypt automáticos | Gratis y sin comprar dominio. La IP es una **Elastic IP**: no cambia si la VM se reinicia |
| Base (H4) | Postgres en la misma VM; las migraciones con `--apply-migrations` al arrancar | Sin RDS: lo más barato. Backups: `pg_dump` diario al disco (§6) |
| Archivos (H5) | `DatabaseCloudStorage`: el fallback que ya está en `server.dart` | Sin tocar código. S3 queda para después (R3) |
| Email (H6) | **SMTP genérico** (`mailer`): Gmail con contraseña de aplicación o Brevo (300/día gratis), elegido por secretos. Sin credenciales SMTP, el código va al log (como en desarrollo) | Es gratis y el mismo código sirve para los dos proveedores. Reemplaza a `ServerpodCloudEmailIdpConfig`, que sólo envía dentro de Serverpod Cloud |
| Run mode | **`staging`**: el seed de demo se habilita en `staging` y nunca en `production` (H9) | El jurado entra con las cuentas sembradas; `production` conserva la garantía de D13 |
| Imagen | Se construye en la Mac para `linux/arm64` (nativo en Apple Silicon) y se copia con `docker save` / `docker load` por SSH | Compilar Dart AOT en una VM de 1 GB se queda sin memoria; sin ECR no hay otro costo |
| Acceso | SSH sólo desde la IP de quien despliega; abiertos sólo el 80 y el 443 | El 8080 y el 5432 nunca se exponen: entra todo por Caddy |
| Costo | `t4g.micro` ≈ 6,1/mes + IPv4 ≈ 3,6/mes + disco ≈ 0,8/mes ≈ **10–11 USD/mes** (≈ 1,5 hasta el 15/10). **Alerta de presupuesto en 10 USD** antes de crear nada | |

---

## 5. Decisiones (cerradas el 2026-10-11)

| # | Pregunta | Respuesta |
|---|---|---|
| Q1 | ¿Dónde? | **AWS**, no Serverpod Cloud |
| Q2 | ¿Qué arquitectura? | **Una VM, la más barata, con todo adentro** |
| Q3 | ¿Cuentas de demo? | **Sí, en `staging`** |
| Q4 | ¿Web de Flutter? | **Sí, en la misma VM** (Caddy sirve el build) |
| Q5 | ¿Dominio? | **sslip.io**, gratis |
| Q6 | ¿Cuenta de AWS? | **La configurada en la máquina de desarrollo** |
| Q7 | ¿Email? | **SMTP gratis** (Gmail o Brevo); sin credenciales, al log |
| Q8 | ¿Cómo llegan los cambios de `main` a AWS? | **GitHub Actions** (`deploy.yml`): tests → imagen ARM → web → `deploy.sh` → humo. AWS por **OIDC** (rol con permiso sólo para abrir y cerrar el SSH del runner) y todo lo demás en **GitHub Secrets** |

---

## 6. Plan

| # | Paso | Detalle | Verificación |
|---|---|---|---|
| 1 | Presupuesto | Alerta de AWS Budgets en 10 USD | Aparece en la consola de Billing |
| 2 | Código del servidor | Email por SMTP (con fallback al log) y seed habilitado en `staging`, con tests. `staging.yaml` con hosts por entorno | `dart test` en verde |
| 3 | Infra | `tool/aws/provision.sh` (idempotente): key pair, security group (22 sólo desde tu IP, 80 y 443), `t4g.micro` Ubuntu 24.04 ARM con Docker, Elastic IP | `ssh` entra y `docker info` responde |
| 4 | Despliegue | `tool/aws/deploy.sh`: build `linux/arm64`, `docker save` → `scp` → `docker load`, `compose.yaml` + `Caddyfile`, secretos **nuevos** en `/opt/nexo/.env` (`chmod 600`, nunca en el repo) | `curl https://api.<ip>.sslip.io/` responde 200 con un certificado válido |
| 5 | Humo | `live.list`, `feed.home`, `follows.suggestions` por `curl`; `watch` por WSS | Responden con el seed |
| 6 | Web | `flutter build web` con `API_BASE_URL=https://api.<ip>.sslip.io/` → `https://<ip>.sslip.io` | Login con cuenta de demo desde un navegador cualquiera |
| 7 | APK | Release `arm64` con la misma `API_BASE_URL` y `SHARE_BASE_URL=https://<ip>.sslip.io`; reemplaza el APK de Drive que apunta a la Mac (R4) | Con datos móviles y sin Wi-Fi: login, vivo entre dos teléfonos, chat, notificación |
| 8 | Backups | `pg_dump` diario por cron en la VM, con 7 días de retención | Aparece el archivo del día |
| 9 | Docs | README: "Producción en AWS" (provisionar, desplegar, secretos, costo y cómo apagarlo) | Otra persona redespliega siguiendo el README |
| 10 | Deploy continuo | `tool/aws/setup-github-deploy.sh` crea el rol OIDC y carga secretos y variables; `deploy.yml` despliega cada push a `main` | Un merge a `main` aparece en producción sin intervención |

Para apagarlo después de la hackathon: `tool/aws/teardown.sh` termina la VM,
libera la Elastic IP y borra el security group. Una Elastic IP sin VM también
se cobra.

---

## 7. Riesgos

| # | Riesgo | Mitigación |
|---|---|---|
| R1 | 1 GB de RAM no alcanza con un pico (subida de video, varios vivos) | Swap de 2 GB y límites de memoria por contenedor. Si pasa, la VM sube a `t4g.small` (2 GB, ~12/mes) en un minuto, sin perder datos |
| R2 | Todo en una VM: si se cae, se cae todo | Para una demo es aceptable. `restart: unless-stopped` en los tres contenedores, y backup diario de la base |
| R3 | Fotos y videos guardados dentro de Postgres (H5) agrandan la base y el backup | Para la demo alcanza. Después: `serverpod_cloud_storage_s3` con un bucket S3 |
| R4 | El APK de Drive actual apunta a la Mac | Después del paso 6 se sube un APK nuevo, con otro nombre, y el viejo se borra de Drive |
| R5 | Un secreto de desarrollo termina en producción | Paso 2: todo se genera de cero; el certificado de Agora se carga por la CLI y nunca se versiona |
| R6 | Las cuentas de demo, con contraseña conocida, en un link público | Son cuentas de demo, sin datos reales. Después de la hackathon: borrar el run mode `staging` o rotar las contraseñas |
| R7 | Agora en web sigue en alfa (R3 del 0004) | Video entre teléfonos (decidido); la web ve el estado y el chat |
| R8 | Gmail limita los envíos diarios y puede marcar como spam | Para una demo sobra. Si molesta, se cambia a Brevo sólo con secretos |
| R9 | sslip.io depende de un servicio de DNS de terceros | Si se cae, la API sigue respondiendo por IP; comprar un dominio y cambiar `publicHost` lleva minutos |

---

## 8. Fuentes

- Serverpod Cloud, planes y precios: https://serverpod.dev/pricing
- Serverpod Cloud, funcionalidades: https://docs.serverpod.dev/cloud
- Deploy a Serverpod Cloud: https://docs.serverpod.dev/next/deployments/deploy-to-serverpod-cloud
- Estrategias de deploy de Serverpod (costos de GCP): https://docs.serverpod.dev/deployments/deployment-strategy
- Railway: https://livemy.app/blog/railway-pricing
- Fly.io: https://fly.io/pricing.md
- Render, plan gratis y WebSockets: https://render.com/docs/free y https://render.com/changelog/free-web-services-now-remain-active-while-receiving-websocket-messages
- Hetzner: https://deployhandbook.com/pricing/hetzner
- AWS Free Tier desde julio de 2025 (créditos, sin horas gratis de EC2/RDS): https://infratally.com/articles/aws-free-tier-2026/
- Precio de `t4g.micro`/`t4g.nano` en us-east-1: https://calculator.holori.com/aws/ec2/t4g.micro/us-east-1
- SMTP gratis (Brevo 300/día, Resend, Mailjet): https://sendlayer.com/blog/best-free-smtp-servers/
