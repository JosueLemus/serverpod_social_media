# SDD 0007 — Cierre del front para la demo

| | |
|---|---|
| Estado | **Implementado** (salvo F3 y HU-08/09), 2026-10-11 |
| Qué es | Lo que la auditoría del front encontró roto o desconectado, ordenado para los 3 días que quedan |
| Entrada | `auditoria-front-historias.txt` (HU-01 a HU-35) |
| Entrega | 14/10/2026 23:59 |
| Relación | No reemplaza al SDD 0004/0005: cierra el front **sin backend nuevo**. Corre en paralelo con el **SDD 0006 (vivos reales, M4)**, que es dueño de `features/live/**`, de `failureFromServer` y de la fila de vivos del feed |

---

## 1. Dónde estamos

Hoy es el día 9 del plan del SDD 0005. M3 está cerrado; la línea de corte 1
(vivos y sanciones contra Serverpod) era el día 7, y M4 y M6 no empezaron.

La auditoría encontró dos tipos de problema:

- **Cosas que el backend ya resuelve y la app no usa:** `profiles.byUsername`,
  `posts.byAuthor`, `moderation.queue`, `moderation.resolve`,
  `profiles.update` y `profiles.becomeCreator`.
- **Cosas que rompen la demo con cuentas reales:** con `AUTH_SOURCE=serverpod`
  la sesión no llega a `MockPlatform`, así que vivos, programar show,
  moderación y consola contestan "sin permiso". El Studio abre siempre
  `live-2`. Los errores de login se traducen todos a "No pudimos completar la
  operación". El perfil y el compositor dicen "Elena Vega" sea quien sea la
  sesión.

Este SDD arregla eso **sin escribir endpoints nuevos**, para que con lo que
queda de tiempo se pueda decidir M4 con el resto del front ya en pie.

---

## 2. Decisiones

| # | Decisión | Por qué |
|---|---|---|
| F1 | **Puente de identidad hacia `MockPlatform`**, sólo con `AUTH_SOURCE=serverpod`: al iniciar, restaurar o cerrar sesión, la cuenta real se asocia a la cuenta mock que tiene **el mismo correo** | Las cuentas del seed (`demo_seed.dart`) y las del mock (`DemoAccounts`) comparten correo. Con el puente, una cuenta real puede hacer el recorrido del hackathon contra las reglas del mock mientras M4 y M6 no existen. Sin él, toda acción de vivos responde "sin permiso" |
| F2 | El puente es un **decorador** de `AuthRepository` (`BridgedAuthRepository`), registrado sólo en `injection.dart` | `ServerpodAuthRepository` no se entera de que existe un mock. En M7 se borra un archivo y una línea |
| F3 | Una cuenta real **sin** pareja en el mock (una recién registrada) queda sin actor, y vivos y consola lo dicen con copy propia: "todavía no está disponible para tu cuenta" | Decir "sin permiso" a alguien que sí tiene permiso es mentirle. Decir "el servidor rechazó" cuando rechazó el mock, también |
| F4 | El Studio abre **el vivo del host en sesión**: el que está al aire o, si no, el próximo programado. Acepta `?show=<id>` para entrar a uno puntual | Con `live-2` fijo, un show recién programado no se podía iniciar nunca, y sólo Elena podía usar el Studio. Es la L14 del SDD 0006; se hizo acá primero (`pickStudioShow`, `LiveRepository.mine()`) y el 0006 la continúa sobre Serverpod |
| F5 | Los errores de auth se traducen **por tipo y por `reason`** (`EmailAccountLoginException`, `EmailAccountRequestException`, `EmailAccountPasswordResetException`), nunca por `runtimeType.toString()` | El cliente lanza `_EmailAccountLoginExceptionImpl`: el nombre del tipo no dice el motivo, el campo `reason` sí |
| F6 | `signIn` sólo guarda la sesión si `profiles.me` responde. Si falla, cierra la sesión del dispositivo antes de propagar el error | Si no, la UI queda deslogueada y la credencial persiste: en el próximo arranque la app entra sola |
| F7 | `ProfileRepository` tiene implementación Serverpod: perfil por `profiles.byUsername` y publicaciones por `posts.byAuthor` | El endpoint existe. El perfil es lo que se ve en el video |
| F8 | El perfil muestra **sólo lo que sabe**. Seguidores, siguiendo y likes son opcionales en la entidad: el mock los trae, el servidor todavía no (M2), y entonces no se dibujan | Pintar "48.5K" en una cuenta real es exactamente el dato inventado que la auditoría marcó |
| F9 | La moderación con Serverpod es **híbrida**: la cola junta los reportes de posts del servidor (`moderation.queue`) con los del chat de vivos del mock. Resolver va a quien tiene el reporte | Los reportes del feed ya van al servidor y ninguna pantalla los leía. Los del chat siguen en el mock hasta M4 |
| F10 | En un reporte del servidor sólo se ofrecen **ocultar** y **descartar** | Es lo que acepta `moderation.resolve` (SDD 0003, D10). Silenciar y expulsar llegan con M6. Ofrecer un botón que el servidor rechaza es una petición fallida con el moderador ya comprometido |
| F11 | Un botón que no hace nada se **deshabilita con tooltip**, como ya hace "Compartir" en la tarjeta de post | Un botón activo que no responde se lee como una app rota |
| F12 | El compositor usa los límites del servidor: 2200 caracteres y se puede publicar sólo con un adjunto | El servidor y el diálogo de editar ya permiten eso; el compositor tenía 500 y exigía texto |
| F13 | Se puede volver a la semilla de la demo desde la app (consola del operador) | `MockPlatform.reset()` existía y nadie lo llamaba. Repetir la grabación exigía borrar el storage del navegador |

---

## 3. Alcance

### Fase 1 — Bloqueantes (HU-01 a HU-06)
- F1, F2, F3: puente de identidad y copy para la cuenta sin pareja.
- F4: Studio sobre el show del host.
- F5, F6: errores de auth y orden de `signIn`.
- F7, F8: perfil real, propio y ajeno, incluido el visitante que abre `/u/:username`.
- El compositor muestra el autor de la sesión.

HU-04 (`promo@nexo.demo`) **no aplica**: la cuenta existe en `DemoAccounts`
pero no está en `DemoAccounts.all`, así que el selector nunca la ofrece. Es
un falso positivo de la auditoría.

### Fase 2 — Conectar lo que ya existe (HU-07, HU-10)
- F9, F10: moderación híbrida.
- "Olvidé mi contraseña" en la hoja de login.

### Fase 3 — Bugs del front (HU-18 a HU-31)
- Feed: un cambio no descarta lo paginado; `loadMore` no pisa likes hechos durante la carga.
- Comentarios: paginar no duplica.
- Compositor: F12.
- Invitado que da like: se le pide iniciar sesión.
- Studio: "Rechazar" rechaza (hecho antes de que existiera el 0006).
- F13: reiniciar la demo.
- Ajustes con forma de volver; programar show desde el rail; el menú de un perfil ajeno no ofrece las opciones de la cuenta propia.
- F11: botones muertos deshabilitados.

### Lo que pasa al SDD 0006 (vivos reales)
Para no editar los mismos archivos a la vez, desde que apareció el 0006 este
SDD no toca `features/live/**` (salvo F4 y "Rechazar", que ya estaban hechos),
`core/network/serverpod_failures.dart` ni la fila de vivos del feed. Eso
incluye: listas de vivos que no se actualizan (HU-27), comentar en un vivo
terminado (HU-24), "Descartar" en programar show (HU-25), los controles del
Studio y la sala, y `ServerpodShowScheduleRepository`.

El puente de identidad (F1) sigue haciendo falta con el 0006 terminado: la
consola del operador y los reportes del chat siguen en el mock hasta M6.

### Fuera de alcance
- Backend nuevo: M4 (vivos), M5 (notificaciones), M6 (sanciones y consola), M2 (seguir), M1 (avatar).
- Editar perfil y "Ser creador" (HU-08, HU-09): los endpoints existen, pero son pantallas nuevas. Entran sólo si sobra tiempo.
- Deuda de convenciones (HU-33) salvo lo que se toque de paso.

---

## 4. Cómo se prueba

- `flutter analyze` sin issues y `flutter test` en verde, mirando el exit code.
- Tests nuevos por cada decisión con lógica:
  - F5: un test por motivo de error.
  - F1: el puente asocia por correo y desasocia al cerrar sesión.
  - F4: el Studio elige el vivo al aire antes que el programado, y respeta `?show=`.
  - F7: el perfil se traduce desde `ProfileView`.
  - F9: la cola mezcla las dos fuentes y resolver va a la correcta.
- A mano, con `tool/demo.sh` y `AUTH_SOURCE=serverpod`: Elena programa e inicia; Tomás comenta; la moderadora oculta; Elena termina.

---

## 5. Qué se retira en M7

| Pieza | Se va cuando |
|---|---|
| `BridgedAuthRepository` | Exista el endpoint `admin` y los reportes del chat vayan al servidor (M6) |
| La mitad mock de la moderación híbrida | Los comentarios de vivos se reporten al servidor (M4) |
| Métricas opcionales del perfil | Existan los follows (M2) |

---

## 6. Estado (2026-10-11)

| Decisión / HU | Estado | Dónde |
|---|---|---|
| F1, F2 — puente de identidad | Hecho | `auth/data/repositories/bridged_auth_repository.dart`. Además lleva a la sesión real las sanciones de la consola mock |
| F3 — copy para una cuenta sin pareja | **No hecho** | Con el SDD 0006, vivos y programar dejan de depender del mock; queda sólo la consola, que una cuenta nueva no usa en la demo |
| F4 — Studio sobre el show del host | Hecho; lo continúa el 0006 | `live/domain/studio_show.dart`, `LiveRepository.mine()` |
| F5, F6 — errores de auth y orden de `signIn` | Hecho | `ServerpodAuthRepository.failureFor`, `_completeSignIn` |
| F7, F8 — perfil real | Hecho | `ServerpodProfileRepository`, `PublicProfileCubit`, `profile_page.dart` |
| HU-06 — autor del compositor | Hecho | `_AuthorRow` lee el `AuthCubit` |
| F9, F10 — moderación híbrida | Hecho | `ServerpodModerationRepository`; `ModerationReport.canSanctionAuthor` |
| HU-10 — "Olvidé mi contraseña" | Hecho | hoja de login |
| HU-18, HU-19 — feed y comentarios | Hecho | `FeedCubit.mergeFirstPage`, `CommentsCubit.mergeComments` |
| F12 — límites del compositor | Hecho | 2200 caracteres, sólo media, error del selector |
| HU-22 — invitado que da like | Hecho | `post_card.dart` |
| HU-23 — "Rechazar" | Hecho | `LiveRoomCubit.rejectGuest` |
| F13 — reiniciar la demo | Hecho | Consola del operador, `AdminRepository.resetDemo` |
| HU-28, HU-29, HU-31 — navegación | Hecho | rail → hoja de crear; Ajustes con AppBar; menú sólo en el perfil propio |
| F11 — botones muertos | Hecho en lo propio | Compositor (encuesta, enlace, emoción, VIP, IA), perfil, Google/Apple, Mensajes. Los de vivos, Studio y Explorar son del 0006 |
| HU-08, HU-09 — editar perfil, ser creador | **Pendiente** | Endpoints listos; falta la pantalla y refrescar la sesión del `AuthCubit` después de `becomeCreator` |

Tests nuevos: `bridged_auth_repository_test`, `serverpod_auth_repository_test`
(un caso por motivo), `serverpod_profile_repository_test`,
`public_profile_cubit_test`, `serverpod_moderation_repository_test`,
`mock_admin_repository_test`, y casos nuevos en los tests del feed, los
comentarios, el compositor y el perfil.

