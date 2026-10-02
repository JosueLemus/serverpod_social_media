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
AGORA_APP_ID=<app-id> tool/demo.sh                # video real en los vivos (Agora)
```

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
