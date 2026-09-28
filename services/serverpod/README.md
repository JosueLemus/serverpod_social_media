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

## Documentación de la API

```bash
./tool/api_docs.sh          # genera y sirve en http://localhost:8000
```

- `http://localhost:8000/map/`: mapa por módulo y endpoint, estilo Swagger
  (`POST /endpoint/metodo`, parámetros, respuesta y ejemplos).
- `http://localhost:8000/`: referencia Dart completa del cliente.

Ambos salen del código y de los comentarios `///` escritos en el server.
Documenta cada endpoint nuevo con `///`.

## Pruebas

```bash
cd nexo_server
dart analyze && dart test                # no necesita Docker
```

Los secretos van en `config/passwords.yaml`, que está en `.gitignore`.
