# Nexo Social

Base Flutter para una red social de creadores y comunidades. El feed continúa
simulado por defecto, pero la autenticación puede usar Serverpod de forma real.

## Ejecutar

```bash
flutter pub get
# Autenticación real (valor predeterminado), con el feed mock.
flutter run --dart-define=AUTH_SOURCE=serverpod --dart-define=DATA_SOURCE=mock --dart-define=API_BASE_URL=http://localhost:8080/
# Demo explícita: jamás se activa como fallback ante un error de red.
flutter run --dart-define=AUTH_SOURCE=mock --dart-define=DATA_SOURCE=mock
flutter analyze
flutter test
flutter test integration_test -d macos
```

No se guardan URLs productivas, tokens ni secretos. `API_BASE_URL`,
`NETWORK_LOGS`, `DATA_SOURCE` y `AUTH_SOURCE` se inyectan con
`--dart-define`. `AUTH_SOURCE=serverpod` es el predeterminado; el demo exige
`AUTH_SOURCE=mock`. Las credenciales de Serverpod se almacenan mediante
`flutter_secure_storage`, con una clave separada para cada URL de backend. No
se persisten contraseñas, códigos ni tokens temporales de verificación.

## Autenticación real

El registro, la verificación de correo, el reenvío de código y la recuperación
de contraseña usan los endpoints estándar `emailIdp` de Serverpod. En
desarrollo, inicia el backend con `serverpod start` desde
`services/serverpod/nexo_server`; el código de correo aparece en esa consola.
No existe un endpoint que devuelva códigos al cliente. El gestor oficial de
sesión restaura, valida y renueva los JWT; cerrar sesión intenta revocar sólo
este dispositivo y siempre borra la credencial local aunque no haya red.

Direcciones de desarrollo:

- macOS, Windows, Linux, iOS Simulator y escritorio: `http://localhost:8080/`.
- Android Emulator: `http://10.0.2.2:8080/`.
- Dispositivo físico: la IP accesible del equipo en la misma red.
- Distribución: una URL HTTPS.

En web la seguridad y el aislamiento dependen del navegador; las pestañas
pueden compartir almacenamiento. Para probar dos cuentas reales usa perfiles
de navegador distintos. El aislamiento por pestaña de las cuentas demo se
mantiene sólo bajo `AUTH_SOURCE=mock`.

El UUID emitido por Serverpod es la identidad canónica. Los scopes firmados
`moderator` y `admin` se traducen respectivamente a `moderator` y `operator`;
una cuenta nueva no recibe scopes, `isCreator` ni verificación de producto. La
verificación del email tampoco es la insignia de creador. Aún no existe un
perfil Nexo administrado en el backend: el cliente muestra un alias estable
derivado del UUID y no expone el correo. Los cambios remotos de perfil,
suspensión y creador requerirán ese endpoint protegido; los mocks actuales
siguen cubriendo esas pantallas para la demo.

Los lives no se incluyen aquí. Cuando se implementen, la participación usará
el UUID autenticado; host, invitado y audiencia serán roles por live, los
scopes administrativos seguirán separados y la regla de no participar en dos
lives se resolverá con una reserva atómica por cuenta en el backend, no
prohibiendo varias sesiones de acceso.

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
