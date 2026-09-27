# Nexo Social

Base Flutter para una red social de creadores y comunidades. Esta etapa entrega arquitectura, rutas, responsive, tema, DI, red y pruebas; no incluye aún feed real, pagos, Serverpod ni Agora.

## Ejecutar

```bash
flutter pub get
flutter run --dart-define=DATA_SOURCE=mock
flutter run --dart-define=DATA_SOURCE=api --dart-define=API_BASE_URL=https://api.example.com
flutter analyze
flutter test
flutter test integration_test -d macos
```

No se guardan URLs productivas, tokens ni secretos. `API_BASE_URL`, `NETWORK_LOGS` y `DATA_SOURCE` se inyectan con `--dart-define`. `mock` es el valor predeterminado y permite trabajar sin backend. `api` conecta el mismo contrato contra `/health` cuando Serverpod esté disponible.

## Estructura

- `lib/app`: raíz, router, tema y registro central de dependencias.
- `lib/core`: contratos comunes, errores, red, responsive y widgets reutilizables.
- `lib/features/<feature>/{data,domain,presentation}`: Clean Architecture feature-first.
- `test`: unit, repository, Cubit y widget tests.
- `integration_test`: flujo de navegación, likes, creación local y live usando mocks.

Cada feature nueva debe separar datasource/model/repository en `data`, entidades/contratos/casos de uso en `domain`, y BLoC, páginas y widgets en `presentation`. Los widgets solo renderizan e interactúan con estado: las reglas de negocio viven en casos de uso.

## Convenciones

- Un `Failure` representa errores de dominio; las capas data lanzan `Exception` y los repositorios los traducen al extender la implementación.
- Registrar dependencias en `app/di/injection.dart`; usar interfaces para sustituirlas por mocks.
- Usar `ResponsiveScaffold` y `AppBreakpoints`, nunca asumir un ancho móvil.
- Ejecutar `flutter analyze` y `flutter test` antes de integrar cambios.
- Ejecutar las pruebas de integración en macOS, iOS o Android; el runner de integración de esta versión de Flutter no soporta Chrome.
