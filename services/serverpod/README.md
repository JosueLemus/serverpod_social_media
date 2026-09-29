# Backend Serverpod

Backend de Nexo Social (Serverpod 4). Es un pub workspace con dos paquetes:

- `nexo_server`: el servidor. Aquí se trabaja.
- `nexo_client`: cliente generado. No se edita a mano; lo importa la app Flutter.

## Arrancar

```bash
dart pub global activate serverpod_cli   # una sola vez
cd nexo_server
serverpod start                          # server + Postgres embebido + hot reload
```

La API queda en `http://localhost:8080`. Los códigos de verificación de email
se imprimen en la consola durante el desarrollo.

## Estructura

```text
nexo_server/lib/src/
  shared/    auth, errors, pagination, audit, gateways, health
  modules/   identity, content, social, live, moderation, ...
             cada módulo: models/ (*.spy.yaml), services/, endpoints/
```

La receta para añadir una funcionalidad está en
[`nexo_server/lib/src/modules/README.md`](nexo_server/lib/src/modules/README.md).

## Documentación de la API (estilo Swagger)

Desde `services/serverpod`:

```bash
./tool/api_docs.sh          # genera todo y lo sirve en http://localhost:8000
./tool/api_docs.sh 9000     # igual, en otro puerto
```

Abre:

- `http://localhost:8000/map/`: el "Swagger". Endpoints agrupados por módulo,
  cada método con `POST /endpoint/metodo`, parámetros, respuesta y ejemplos
  en Dart y `curl`.
- `http://localhost:8000/`: referencia Dart completa del cliente (`dart doc`).

El script hace dos cosas: ejecuta `dart doc` en `nexo_client` y luego
`dart run tool/api_map.dart`, que genera el mapa. Para regenerar solo el mapa,
sin servirlo:

```bash
dart run tool/api_map.dart  # escribe nexo_client/doc/api/map/index.html
```

No se mantiene a mano: el mapa se arma con el cliente generado, los endpoints
y los `.spy.yaml` del server. Un endpoint nuevo aparece solo tras regenerar.
Documenta cada endpoint y método con `///`: ese texto es la descripción que se
ve en el mapa.

### Postman

Importa `tool/postman/nexo_api.postman_collection.json`. Trae health, registro,
login, refresh de token y recuperación de contraseña, en ese orden, y guarda los
tokens entre peticiones. Los códigos de verificación salen en la consola de
`serverpod start`: cópialos en la variable `verificationCode`. Esta colección sí
se mantiene a mano: añade ahí los endpoints nuevos.

## Pruebas

```bash
cd nexo_server
dart analyze && dart test                # no necesita Docker
```

Los secretos van en `config/passwords.yaml`, que está en `.gitignore`.

## Autenticación de Nexo

El servidor ya inicializa `JwtConfigFromPasswords` y
`ServerpodCloudEmailIdpConfig` en `nexo_server/lib/server.dart`. La app Flutter
consume los endpoints generados `emailIdp` y `jwtRefresh`; no se añade Firebase,
Supabase ni un proveedor de identidad externo. En desarrollo Serverpod escribe
los códigos de verificación y recuperación en la consola. En staging y
producción el proveedor de correo y el alojamiento tienen sus propias
condiciones, aunque el módulo de identidad no exige contratar otro servicio de
autenticación.

No se creó una migración: Serverpod ya proporciona la tabla de usuarios,
scopes, bloqueo, perfiles base y solicitudes de correo. Si Nexo necesita
nombre visible editable, `isCreator`, estado de sanción o una insignia de
producto persistentes, deberá añadirse un único perfil complementario enlazado
al UUID de `Session.authenticated.authUserId`, junto a endpoints protegidos que
nunca acepten un UUID arbitrario desde Flutter.
