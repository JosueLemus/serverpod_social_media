# Nexo Social

Monorepo de Nexo Social: una red de creadores y comunidades.

## Estructura

```text
apps/
  nexo_social/       # Aplicación Flutter: móvil, web y escritorio
services/
  serverpod/         # Backend Serverpod, API y migraciones
```

## App Flutter

```bash
cd apps/nexo_social
flutter pub get
flutter run --dart-define=DATA_SOURCE=mock
flutter analyze
flutter test
```

La app usa datos mock mientras se implementa el servidor. Cuando Serverpod esté
disponible, se podrá usar `DATA_SOURCE=api` sin cambiar las capas de dominio o UI.
