# SDD 0001 — Consola de Operador (panel de administración)

| | |
|---|---|
| Estado | **Implementado en mock** (fases 0–3), 2026-09-28. Ver §13 |
| Fecha | 2026-09-28 |
| Fuente | `panel-admin-capacidades.pdf` (catálogo de 92 capacidades) + estado real del repo |
| Alcance | Las **10 capacidades** de la §06 del catálogo |
| Datos | **Todo en mock** en esta etapa, incluida la autenticación. Backend Serverpod después |
| Plataformas | Escritorio **y móvil** |
| Plazo | Hoy/mañana, una persona. Las fases van ordenadas para que cortar en cualquier punto deje algo demostrable |

---

## 1. Objetivo

Construir la consola separada y auditada del **Operador** que define el Notion,
con las 10 capacidades de mejor relación costo/prueba del catálogo, y dejar
cada contrato listo para que pasar a Serverpod sea cambiar la implementación
del repositorio en `injection.dart` y no reescribir pantallas.

### Qué significa "mock" acá

El mock no es una UI que finge: es un **servidor falso con las mismas reglas**
que va a tener Serverpod. Los permisos, la máquina de estados del live y el
gate de verificación se aplican **dentro del repositorio mock**, que lanza el
mismo tipo de fallo que va a lanzar el backend (`forbidden`,
`creatorNotVerified`, `accountSuspended`). La View nunca decide un permiso.

Esto tiene un costo que conviene decir: en esta etapa la demo **no** prueba
todavía que "el servidor rechaza", porque el servidor es código del cliente. Lo
que sí prueba es que la regla vive en una sola capa (datos), así que al
reemplazar el mock por Serverpod la regla se muda entera. El paso 7 del guion
recién es "a prueba de DevTools" cuando exista el backend (§11).

### No-objetivos

Salen del catálogo, §07:

- Gráficos, analítica y métricas.
- Apelaciones, acciones masivas y exportación.
- IA (módulo M).
- Una app separada.
- Agora real.
- El backend Serverpod de estas capacidades: queda como siguiente SDD, pero el
  diseño de §11 fija los contratos.

---

## 2. Punto de partida (verificado en el repo)

| Pieza | Estado |
|---|---|
| `UserRole` | `visitor, user, creator, moderator`: **no hay operador** |
| `MockAuthRepository` | Iniciar sesión y registrarse devuelven siempre a Elena |
| Guard de `/moderation` | Sólo bloquea al visitante; **cualquier usuario autenticado entra** |
| Feature `moderation/` | Mock completo: cola por severidad, ocultar, silenciar 15m/1h/24h, expulsar y auditoría append-only. Estado en memoria del repositorio |
| `LiveRepository.transition` | Existe, sin gate de verificación |
| `ShellDestinations` | Soporta `desktopOnly`; `/studio` y `/moderation` son sólo de escritorio |
| `MockSocialStore` | Persistencia mock sobre `SharedPreferences` |
| Backend | Scopes `moderator`/`admin` y `AuditService` existen; los módulos de dominio no. Sin cambios en esta etapa |

---

## 3. Decisiones tomadas

| # | Decisión | Por qué |
|---|---|---|
| D1 | Todo en mock, incluida la auth | Pedido del equipo: poder ver la app sin levantar servidor |
| D2 | Dos ambientes: `DATA_SOURCE=mock` (por defecto) y `DATA_SOURCE=api` | Ya existe el flag. En `api`, lo que todavía no tiene backend **cae a mock** y se loguea una sola vez al arrancar |
| D3 | La consola es `/admin`, separada de `/moderation` | Moderador y Operador no son el mismo rol con distinto tamaño (catálogo §04) |
| D4 | El moderador es **global** en esta etapa | No existe el módulo de comunidades. Queda anotado como deuda; el contrato recibe `communityId?` para no romperlo después |
| D5 | Sanciones: suspender (reversible), restaurar y banear (permanente) | El baneo no se restaura desde la consola |
| D6 | Verificación sí/no | Es lo único que necesita el gate de lives |
| D7 | Entrada por **selector de cuentas demo** | Visible sólo con `DATA_SOURCE=mock`; en `api` no se compila en la pantalla |
| D8 | La consola funciona en **móvil y escritorio** | Tablas con versión angosta; entra en `small_screen_overflow_test` |
| D9 | Echar al suspendido **en el acto**, simulado en mock | Ver §6.3 |
| D10 | La expulsión se muestra con **dos pestañas de Chrome** que comparten el estado mock | Es la única forma de verla "en el acto" sin servidor; §6.3 |

---

## 4. Modelo de permisos

| Rol | Cómo lo obtiene | Qué puede en la consola |
|---|---|---|
| Visitante | Invitado | Nada; ni `/moderation` ni `/admin` |
| Usuario | Cuenta activa | Reportar |
| Creador | `isCreator` en el perfil (no es un rol del sistema de permisos) | Iniciar un live **sólo si está verificado** |
| Moderador | Scope `moderator` | `/moderation`: cola, resolver, silenciar, ocultar |
| Operador | Scope `admin` | `/admin` completo y `/moderation` |

### Cambios en el dominio del cliente

`UserRole` hoy mezcla dos cosas: el nivel de permiso y "es creador". Siguiendo
al backend (creador vive en el perfil, no en el scope):

```dart
enum UserRole { visitor, user, moderator, operator }   // scope, excluyentes

class AppUser extends Equatable {
  final String id, username, name, email;
  final UserRole role;
  final bool isCreator;
  final VerificationStatus verification;   // none | verified | revoked
  final AccountStatus status;              // active | suspended | banned
}
```

Todos los usos de `UserRole.creator` pasan a `user.isCreator` (hay que buscar
los call sites: guard, Studio, perfil).

### Reglas

- **R1.** Cada método de `AdminRepository` y `ModerationRepository` verifica el
  rol del actor **dentro del repositorio** y lanza `ForbiddenFailure`. El
  guard del router es layout, no seguridad.
- **R2.** Cada mutación agrega su entrada de auditoría en la misma operación:
  el mock aplica los dos cambios o ninguno. Esto espeja la `Transaction` de
  `AuditService.record`.
- **R3.** Nada se borra: ocultar pone `hiddenAt`/`hiddenBy`; suspender y
  banear cambian `status`.
- **R4.** Un operador no puede sancionarse a sí mismo ni a otro operador.

---

## 5. Arquitectura mock: `MockPlatform`

Hoy cada repositorio mock tiene su propio estado en memoria, así que suspender
a Elena en un repositorio no se entera el de auth, y ocultar un comentario en
la consola no lo saca de la sala. Para que la consola **afecte** al resto de la
app hace falta una sola fuente de verdad.

```
core/mock/mock_platform.dart      # el "servidor falso": estado + reglas compartidas
  accounts:  Map<id, MockAccount>     (rol, isCreator, verification, status)
  sessions:  Set<accountId>           (sesiones "activas", para revocar)
  lives:     Map<id, LiveSession>
  comments:  Map<id, LiveComment>     (hiddenAt, hiddenBy)
  reports:   Map<id, ModerationReport>
  sanctions: List<Sanction>
  audit:     List<AuditEntry>         (append-only)
  Stream<PlatformEvent> events        (accountStatusChanged, commentHidden, liveEnded, …)
```

- Singleton en GetIt, persistido en `SharedPreferences` (clave versionada
  `mock_platform_v1`). Tiene un botón "Reiniciar demo" en Ajustes, sólo en mock.
- Los repositorios mock (`MockAuthRepository`, `MockLiveRepository`,
  `MockModerationRepository`, `MockAdminRepository`) **dejan de tener estado
  propio** y leen y escriben en `MockPlatform`.
- Latencia simulada de 150–400 ms y fallo inyectable para probar los estados de
  error. Existe porque un mock instantáneo esconde los estados de carga.
- Los ids nuevos son temporales y únicos (regla del proyecto: nada de
  `length + 1`).

### Cuentas sembradas

| Cuenta | Rol | Creador | Verificación | Uso en el guion |
|---|---|---|---|---|
| Elena (`@elena_ux`) | user | sí | verificada | Inicia el live |
| Operador (`@nexo_ops`) | operator | no | — | Consola |
| Moderador (`@mod_lucia`) | moderator | no | — | `/moderation` |
| Espectador (`@tomas`) | user | no | — | Reporta |
| Abusivo (`@troll_99`) | user | no | — | Sancionado |

---

## 6. Capacidades

Numeradas como en el catálogo, §06.

| # | Capacidad | Dónde | Regla (en el repositorio) |
|---|---|---|---|
| 1 | Rol de operador | `UserRole.operator`, cuentas semilla | — |
| 2 | Guard por rol | `_guard`: `/admin` → operador; `/moderation` → moderador u operador | Además R1 |
| 3 | Auditoría filtrable | `/admin` › Auditoría: filtro por actor, acción, entidad y fecha; paginado por cursor | Sólo operador |
| 4 | Resolver un reporte | `resolve(reportId, decision)`: aplica la decisión y cierra el reporte en un paso | Moderador u operador; R2 |
| 5 | Buscar cuentas | `/admin` › Cuentas: por correo, usuario o id, más la ficha (estado, rol, alta, sanciones) | Sólo operador |
| 6 | Suspender, banear, restaurar y revocar sesión | Ficha de cuenta | R4; revoca las sesiones de la cuenta (§6.3) |
| 7 | Verificar y desverificar | `/admin` › Creadores y ficha de cuenta | Motivo obligatorio al revocar |
| 8 | Gate de lives | `LiveRepository.transition(→live)` | `isCreator && verified && active`, si no `CreatorNotVerifiedFailure` |
| 9 | Estado visible en el perfil público | `/u/:username` | Suspendida: insignia "Cuenta suspendida" y contenido oculto |
| 10 | Forzar fin de un live | `/admin` › Lives: activos y "Finalizar" con motivo | Transición `live → ending → recorded`, con `endedBy` = operador |

### 6.1 Contratos de dominio nuevos

```dart
abstract interface class AdminRepository {
  Future<Page<AccountSummary>> searchAccounts(String query, {PageCursor? after});
  Future<AccountDetail> account(String accountId);
  Future<void> suspend(String accountId, ModerationReason reason);
  Future<void> ban(String accountId, ModerationReason reason);
  Future<void> restore(String accountId);
  Future<void> setVerification(String accountId, {required bool verified, ModerationReason? reason});
  Future<List<LiveSession>> activeLives();
  Future<void> forceEndLive(String liveId, ModerationReason reason);
  Future<Page<AuditEntry>> audit(AuditFilter filter, {PageCursor? after});
}
```

`ModerationRepository` cambia `create` + `resolve` sueltos por
`resolve(reportId, ModerationDecision)`. Hoy son dos llamadas y eso permite
ocultar sin cerrar el reporte, justo lo que la regla del proyecto prohíbe.
`ModerationDecision` es lo que ya devuelve `ModerationSheet`.

`ModerationReason` es un enum tipificado: spam, acoso, discurso de odio,
contenido sexual, violencia, suplantación u otro. La etiqueta en español va en
el enum.

`Failure` suma `ForbiddenFailure`, `CreatorNotVerifiedFailure` y
`AccountSuspendedFailure`, cada una con su copy en la View.

### 6.2 Feature `admin/`

```
features/admin/
  domain/       entities/ (AccountSummary, AccountDetail, AuditEntry, AuditFilter, Sanction)
                repositories/admin_repository.dart
  data/         repositories/mock_admin_repository.dart    (sobre MockPlatform)
  presentation/
    pages/      admin_console_page.dart    (Resumen de cola · Cuentas · Creadores · Lives · Auditoría)
                account_detail_page.dart
    bloc/       account_search_cubit, account_detail_cubit, verification_queue_cubit,
                active_lives_cubit, audit_log_cubit
    widgets/    sanction_sheet.dart (motivo tipificado + confirmar), audit_entry_tile.dart
```

- Cada cubit tiene loading, empty, error y success, y `Equatable` con `props`
  completo. Ningún cubit lleva copy; los motivos son enums.
- **Confirmar antes de sancionar.** Igual que el silenciamiento: elegir el
  motivo no aplica; "Suspender" confirma.
- La cola de reportes de `/admin` **reutiliza** `ModerationCubit` y
  `ModerationSheet`.
- **Móvil (D8).** `compact` usa pestañas arriba y listas de tarjetas; la
  auditoría es una lista de dos renglones (actor · acción / entidad · hora).
  `expanded` muestra tabla y panel lateral con la ficha. Todo con `NexoPage`.
- **Entrada:** en escritorio, "Consola" en el rail (sólo operador). En móvil no
  hay pestaña nueva (la barra ya tiene cinco): se entra desde **Perfil ›
  Consola**, visible sólo para el operador. `/admin` es ruta raíz empujada
  sobre el shell, igual que Ajustes.

### 6.3 Echar al suspendido en el acto (simulado)

1. `suspend()` o `ban()` cambia `status`, borra la cuenta de `sessions` y
   emite `accountStatusChanged`.
2. `AuthCubit` escucha `MockPlatform.events`. Si la cuenta en sesión dejó de
   estar activa, cierra la sesión y la guarda (vía `refreshListenable`) lleva a
   una pantalla **"Tu cuenta está suspendida"** con el motivo. No se navega a
   mano, como en `signOut()`.
3. Cualquier operación de un repositorio con una sesión que ya no está en
   `sessions` lanza `AccountSuspendedFailure`: es la red de seguridad si el
   evento se pierde.
4. El selector de cuentas no deja entrar a una cuenta suspendida o baneada: el
   login falla con `AccountSuspendedFailure`.

**Demo con dos pestañas de Chrome (D10).** El operador está en una pestaña y
el sancionado en otra:

- **El estado de `MockPlatform` es compartido.** En web vive en `localStorage`,
  que las dos pestañas del mismo origen comparten. Cada pestaña escucha el
  evento `storage` del navegador y re-hidrata `MockPlatform`, que re-emite los
  cambios en `events`.
- **La sesión es propia de cada pestaña.** En web va a `sessionStorage`; si no,
  las dos pestañas compartirían al usuario logueado. En móvil y escritorio
  sigue en `SharedPreferences`.
- **El código de web queda aislado** detrás de una interfaz
  `MockPlatformSync`, con una implementación `web` (`package:web`, import
  condicional) y una `noop` en el resto. Sólo lo usa la capa `data/` del mock.
  `layer_boundaries_test` no se toca.
- **En móvil** (una sola app) la expulsión se ve con el selector: la cuenta
  sancionada no puede volver a entrar.

Costo estimado: unas 2 h extra, dentro de la fase 1.

---

## 7. Plan por fases

Cada fase termina con `flutter analyze` limpio, `flutter test` verde y algo
demostrable.

| Fase | Contenido | Resultado demostrable |
|---|---|---|
| **0 — Cimientos** (≈2 h) | `MockPlatform` + semilla; migrar los repositorios mock a él; `UserRole.operator` + `isCreator`/`verification`/`status`; selector de cuentas demo; guards de `/admin` y `/moderation` | Entrar como operador, moderador o Elena; un usuario común no puede abrir `/moderation` |
| **1 — Núcleo** (≈6 h) | #4 resolver en un paso · #6 suspender, banear, restaurar y revocar · #8 gate de lives · pantalla de suspendido · sincronización entre pestañas | Las 3 del catálogo: resolución auditada, suspensión con expulsión inmediata, live rechazado |
| **2 — Consola** (≈4 h) | #5 búsqueda y ficha · #7 verificar y desverificar · #3 auditoría filtrable · #9 estado en el perfil · versión móvil | Guion §8 completo menos el paso 10 |
| **3 — Cierre** (≈2 h) | #10 lives activos y forzar fin · "Reiniciar demo" · ensayo del guion | Top 10 completo |

## 8. Guion de demo (mock)

| Paso | Qué se hace | Qué debe pasar |
|---|---|---|
| 1 | Elena inicia un live | `scheduled → live` |
| 2 | `@troll_99` comenta y `@tomas` lo reporta | El reporte aparece en la cola con la severidad que calcula el repositorio |
| 3 | El operador abre `/admin` › Reportes | Aparece el reporte |
| 4 | Resuelve: ocultar + silenciar 24 h | El comentario desaparece de la sala, el reporte sale de la cola y hay una sola entrada de auditoría por acción |
| 5 | Auditoría | Actor, acción, entidad y hora; nada borrado |
| 6 | El operador desverifica a Elena, con motivo | `verification = revoked` + auditoría |
| 7 | Elena intenta iniciar otro live | Rechazado con "Tu cuenta de creadora no está verificada". **El botón no se esconde** |
| 8 | Se restaura la verificación | El live arranca |
| 9 | El operador suspende a `@troll_99`, que está logueado en otra pestaña | Esa pestaña pasa sola a "Tu cuenta está suspendida" (§6.3) |
| 10 | El operador fuerza el fin de un live | La sala muestra "El vivo terminó" |

## 9. Testing

- **Unit:** reglas de `MockPlatform`: gate de live, R4, un reporte resuelto
  sale de la cola, auditoría append-only, una cuenta suspendida no opera.
- **Cubit** (`bloc_test`): cada cubit nuevo, con sus cuatro estados.
- **Guard:** `router_guard_test` suma operador y moderador en `/admin` y
  `/moderation`, visitante y usuario rechazados.
- **Widget:** consola y ficha; el botón de iniciar live sigue visible para un
  creador desverificado y el rechazo muestra la copy.
- **Arquitectura:** la consola entra en `page_frame_test` y en
  `small_screen_overflow_test` a 320 px.
- **Contrato:** un solo suite de tests escrito contra `AdminRepository` que hoy
  corre sobre el mock y mañana sobre Serverpod.

## 10. Riesgos

| Riesgo | Mitigación |
|---|---|
| Migrar los repositorios mock existentes a `MockPlatform` rompe tests actuales | Hacerlo en la fase 0, sola, con el suite en verde antes de sumar nada |
| Quitar `UserRole.creator` toca varios call sites | Buscarlos antes de empezar; el compilador marca los que falten |
| Estado mock persistido que se corrompe entre versiones | Clave versionada y "Reiniciar demo" |
| El jurado pregunta "¿esto lo decide un servidor?" | Decirlo de frente: las reglas viven en la capa de datos, detrás del mismo contrato que va a implementar Serverpod (§11) |
| Plazo de un día | Las fases son cortables; al terminar la fase 1 ya está el "si sólo entran tres" |

## 11. Hacia Serverpod (siguiente SDD, fuera de esta etapa)

Esto sólo fija los contratos, para que el mock no invente algo que el backend
no pueda cumplir:

- Módulos `identity`, `live`, `content` y `moderation` bajo
  `nexo_server/lib/src/modules/`.
- Endpoints `admin*` con `requireScope(NexoScopes.admin)` en la primera línea.
- Cada mutación en una `Transaction` con `AuditService.record`.
- `AuditLog` es `serverOnly`: el cliente recibe un `AuditEntryDto`.
- Revocación real: revocar los refresh tokens, `requireActiveUser()` en cada
  endpoint y un stream de Serverpod para expulsar en el acto.
- `NexoErrorCode` suma `accountSuspended` y `creatorNotVerified`, que mapean
  1:1 a los `Failure` de §6.1.
- `DATA_SOURCE=api` reemplaza `Mock…Repository` por `Serverpod…Repository` en
  `injection.dart`, módulo por módulo.

## 12. Preguntas abiertas

Ninguna. Resueltas con el equipo el 2026-09-28 (D1–D10).

**Deuda aceptada:**

- Moderador global (D4).
- El rechazo del paso 7 lo decide el mock y no un servidor (§1).
- Cuando exista el backend, `sessionStorage` y la sincronización entre
  pestañas se descartan.

## 13. Estado de implementación

Las 10 capacidades están construidas sobre `MockPlatform`
(`lib/core/mock/mock_platform.dart`). Hay 161 tests en verde, contra 106
antes, y `flutter analyze` está limpio. El recorrido de dos pestañas (§6.3)
se verificó en Chrome headless.

**Diferencias con este documento:**

- **Sin latencia simulada.** Un `Future.delayed` en el mock deja timers
  pendientes en los tests de widget y los hace fallar. Los estados de carga
  existen igual en cada cubit.
- **Silenciar y bloquear desde la hoja del chat en vivo siguen siendo sólo
  registro local de la sala**, como antes. Silenciar y expulsar con efecto real
  se hace resolviendo un reporte (cola de `/moderation` o `/admin`).
  Reportar y ocultar desde el chat sí van al `MockPlatform`.
- **Bugs que encontraron los tests nuevos**, ya corregidos: el `copyWith` que
  borraba la confirmación recién emitida, el cubit de la sala que emitía
  después de cerrarse, y la búsqueda que sacaba la `@` de los correos.

## 14. Cómo probarlo

```bash
cd apps/nexo_social
flutter run -d chrome        # modo mock, no necesita servidor
```

1. En la bienvenida, tocar **"Elegir cuenta de demo"** y entrar como
   **Operaciones Nexo**. El feed muestra la tarjeta **"Sesión de operador"**
   con los reportes pendientes, y el perfil dice OPERADOR.
2. **Abrir consola de operador** › Creadores › **Revocar** a `@elena_ux`, con
   un motivo.
3. Cerrar sesión y entrar como **Elena Vega** › Studio › **Iniciar vivo**: el
   botón está, pero la acción se rechaza con "Tu cuenta de creador no está
   verificada".
4. **Expulsión en el acto (web):** en una pestaña entrar como **Troll 99**; en
   otra, del mismo navegador, como operador › Consola › Cuentas ›
   `@troll_99` › **Suspender**. La primera pestaña pasa sola a "Tu cuenta está
   suspendida".
5. Consola › **Auditoría**: cada acción aparece con actor, motivo y hora.

Para volver a la semilla: borrar los datos del sitio en el navegador.
