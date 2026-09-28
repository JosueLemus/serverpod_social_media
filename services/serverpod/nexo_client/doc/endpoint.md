# API de Nexo Social

Cada clase `Endpoint…` corresponde a un endpoint del servidor. Sus métodos se
llaman desde la app con `client.<endpoint>.<metodo>(...)`:

```dart
final client = Client('http://localhost:8080/');
final status = await client.health.ping(); // "ok"
```

## Errores

Los errores de negocio llegan como `NexoException`, con un `code`
(`NexoErrorCode`) y un `message`:

```dart
try {
  await client.health.ping();
} on NexoException catch (e) {
  switch (e.code) {
    case NexoErrorCode.unauthenticated: // pedir login
    case NexoErrorCode.forbidden:       // sin permisos
    default:                            // mostrar e.message
  }
}
```

## Paginación

Los listados reciben un `PageCursor?`. Envía `null` para pedir la primera página
y, para la siguiente, el `createdAt` y el `id` del último elemento recibido.
