# Nexo Social — Project Context

## Qué es esto

Red social para creadores y comunidades: feed, contenido, en vivos y
monetización. Monorepo con dos paquetes:

```
apps/nexo_social/      # Cliente Flutter — móvil, escritorio y web
services/serverpod/    # Backend Serverpod + PostgreSQL (todavía sólo README)
```

**El objetivo del hackathon** es demostrar el recorrido completo: un creador
publica, programa e inicia un vivo, incorpora un invitado, un moderador oculta
un comentario, y el vivo terminado se convierte en replay.

**El backend es la autoridad.** Flutter muestra la experiencia; Serverpod
decide permisos, estados y acceso a recursos. Hoy todo eso está detrás de
repositorios mock, y esa frontera es lo que hace que cambiar de mock a API sea
un cambio de una línea en `injection.dart` y no una reescritura.

---

## Estado de la app hoy

| Capa | Estado |
|---|---|
| Datos | **Mock**, seleccionable por entorno (`--dart-define=DATA_SOURCE=api`) |
| Sesión | Mock persistida en `SharedPreferences`; el invitado es efímero a propósito |
| Agora / pagos / IA / grabación | No integrados. Interfaces y mocks, como decide el Notion |
| Plataformas verificadas | iOS simulador, macOS, Web (Chrome) |
| SDK mínimo | **Flutter 3.47.5 / Dart 3.12.2.** No es una recomendación |

Nada de lo que hay en `lib/` habla con un backend real todavía. Un repositorio
mock que *parece* real es la forma más rápida de que alguien construya encima
asumiendo garantías que no existen, así que cada uno se llama `Mock…` en el
nombre del archivo y de la clase.

---

## Arquitectura

**Clean Architecture + Feature First + BLoC + GetIt + Dio.** Estricta: cada
feature no trivial tiene `data / domain / presentation`.

```
lib/
  app/
    app.dart            # NexoApp: provee AuthCubit y construye el router UNA vez
    di/injection.dart   # GetIt. Único lugar donde se decide mock vs API
    router/
      app_routes.dart   # Constantes de ruta. Nada de literales en call sites
      app_router.dart   # StatefulShellRoute + las guardas de rol
    theme/
      app_tokens.dart   # AppColors, AppSpacing, AppRadii
      app_theme.dart    # ThemeData único
  core/
    animations/         # AppMotion, Enter, EnterStatic, Pop
    constants/          # Environment (dart-defines)
    errors/             # Failure sellado + excepciones + copy
    layout/nexo_page.dart   # El marco de TODA pantalla del shell
    network/            # DioClient + interceptors
    responsive/         # FormFactor, AppBreakpoints, AppShell, ShellDestinations
    storage/            # Persistencia mock
    usecases/           # Contrato UseCase
    utils/              # RelativeTime, MockContent
    widgets/            # Estados compartidos, logo
  features/
    auth/ explore/ feed/ live/ moderation/
    notifications/ posts/ profile/ subscriptions/
```

### La regla de dependencia

`presentation → domain ← data`. El dominio no importa nada de las otras dos.

- **Un BLoC depende de casos de uso o repositorios, nunca de `Dio`, de
  `SharedPreferences` ni de un widget.**
- **Un widget nunca toca `sl<…Repository>()`.** Pasó: `ProfilePage` resolvía
  `AuthRepository` desde un `FutureBuilder`, así que releía disco en cada
  rebuild y no se enteraba de un cierre de sesión ocurrido en otra parte del
  árbol. Hoy lee `context.watch<AuthCubit>()`.
- **`sl<T>()` sólo en el `create:` de un `BlocProvider`**, para obtener el
  cubit de la pantalla. En cualquier otro lugar es el service locator usado
  como variable global.

---

## Bloc / Cubit

- **Cubit por defecto.** `Bloc` sólo cuando los eventos necesitan encolarse,
  transformarse o reproducirse. Hoy no hace falta en ninguna feature.
- **Inyección por constructor con impl real por defecto**:
  `FeedCubit(this._getFeedStatus, [this._store])`. Nunca instanciar una
  dependencia dentro del cuerpo.
- **`Equatable` en TODO estado, con `props` completo.** Un campo que falta es
  un no-rebuild silencioso: el cubit emite, el estado compara igual y la UI no
  se redibuja. El fallo opuesto (sin `Equatable`) sólo cuesta rebuilds de más,
  que se ven; éste no se ve.
- **El estado es dato, nunca una orden de navegación.** Un estado que lleva
  `navigateTo:` hace que la View sea un despachador y que dos vistas de la
  misma feature se comporten distinto.
- **La copy no vive en el estado ni en la capa de datos.** Un cubit no tiene
  `BuildContext`, así que un mensaje ya escrito ahí no se puede traducir ni
  reusar. El estado lleva un **motivo tipado** (enum) y la View lo traduce.
- **El texto del backend nunca se pinta.** Va a telemetría; al usuario se le
  muestra copy propia, en español, sobre lo que estaba haciendo.
- **Efectos secundarios fire-and-forget desde el cubit**, con `unawaited()`,
  nunca desde la View.

### Lo que decide un cubit y lo que decide la View

| Decide el cubit | Decide la View |
|---|---|
| Si el formulario se puede enviar (`canPublish`) | Cómo se dibuja un botón deshabilitado |
| Qué filtro está activo y qué items pasan | Que el chip activo sea azul |
| Que una acción quedó auditada | Cómo se lista la auditoría |

`PostComposerCubit.canPublish` existe justamente por esto: la regla vivía
escrita a mano dentro del `builder`, o sea en dos lugares, y dos copias de una
regla se separan.

---

## Navegación — `go_router`

### `StatefulShellRoute.indexedStack`, no `ShellRoute`

El shell anterior era un `ShellRoute` + `context.go`, y eso **reconstruía todo
el subárbol en cada cambio de pestaña**: abrir un vivo y volver a Inicio dejaba
el feed arriba de todo, y no había pila por pestaña. Hoy cada branch tiene su
propio Navigator y su propio scroll.

- **Tocar la pestaña en la que ya estás** vuelve a la raíz de ese branch
  (`initialLocation: branch == currentIndex`). Es el gesto estándar de una tab
  bar y la única salida de una pila profunda sin buscar el botón atrás.
- **Nunca empujar entre branches.** `context.push('/profile/x')` desde el feed
  deja la página en el Navigator del branch de perfil mientras en pantalla está
  el del feed: no pasa nada visible y el back popea algo que el usuario nunca
  vio. Por eso el perfil ajeno es `/u/:username`, una ruta **raíz** empujada
  sobre el shell, y `/profile` (sin usuario) es la pestaña. Por lo mismo, la
  sala de un vivo vive **dentro** del branch de Explorar
  (`/explore/live/:liveId`): se entra a un vivo desde el descubrimiento.
- **La segunda pestaña es Explorar, no "En vivo".** Lo dicen el diseño y el
  Notion: los vivos son un tipo de contenido dentro del descubrimiento, no una
  sección hermana del feed, y una pestaña dedicada sólo a ellos dejaba sin
  entrada a perfiles y categorías.
- **Crear es una acción, no un destino.** No tiene branch: empuja una ruta a
  pantalla completa sobre el shell. Por eso su botón va sin etiqueta —las
  otras cuatro entradas son destinos, y una palabra debajo lo alinearía
  visualmente con ellas— y se busca en tests por su semántica
  (`Crear publicación`), no por texto.
- **Lo que es una tarea se empuja sobre el shell** con
  `parentNavigatorKey: rootNavigatorKey`: componer, paywall, ajustes. Dejar la
  barra visible invita a abandonar la tarea a medias, y `go` en vez de `push`
  descarta la pestaña desde donde salió.
- **`go` reemplaza, `push` apila.** Un CTA que abre una ruta raíz con `go`
  desmonta el shell entero y deja al usuario sin a dónde volver.

### Las guardas viven en un solo lugar

`_guard(AuthState, String)` en `app_router.dart`, expuesto como
`guardRedirect` para que `router_guard_test.dart` lo maneje como función pura.
Una guarda repartida entre `redirect`, un `BlocListener` y un `initState` es
tres reglas que se contradicen.

Roles, según el Notion: **visitante** explora público; **usuario autenticado**
interactúa; **creador** publica e inicia; **host** controla su sesión;
**moderador** actúa sobre su comunidad.

Tres cosas que salieron de bugs reales al escribir esto:

- **El splash no es un destino en ninguna dirección.** Estaba en `publicOnly`,
  así que la guarda le contestaba "podés quedarte" a un usuario sin sesión y la
  app no salía nunca del logo.
- **Un visitante SÍ puede quedarse en `/sign-in`.** Esa pantalla es cómo se
  convierte en usuario. Mandarlo al feed desde ahí lo rebota entre `/sign-in` y
  `/` para siempre.
- **Por eso entrar como invitado navega a mano** (`_exploreAsGuest`). La guarda
  no puede distinguir "acaba de tocar explorar" de "rebotó de una ruta
  restringida": las dos son un visitante parado en `/sign-in`.
- **`authenticatedOnly` se compara por segmento**, no con `startsWith` pelado:
  toda ruta empieza con `/`, así que un `startsWith(feed)` cerraría la app
  entera.

### `refreshListenable`

La guarda se re-evalúa cuando cambia la sesión, no en la próxima navegación.
Por eso **cerrar sesión no navega a mano**: `signOut()` cambia el estado, el
listener dispara y el redirect mueve al usuario. Navegar además compite con la
guarda.

### El router se construye UNA vez

En `initState`, guardado en un campo. El router es dueño del historial: si se
construye en `build`, cualquier rebuild del ancestro —o un hot reload— devuelve
al usuario a la ruta inicial a mitad de sesión.

---

## Responsive — es app Y escritorio

`FormFactor` (`core/responsive/breakpoints.dart`) tiene tres valores y **toda**
decisión responsive resuelve a uno. Nada de `MediaQuery.sizeOf(context).width >
n` escrito en una pantalla: dos pantallas con dos números dejan de cambiar a la
vez y la app se reacomoda en pedazos.

| FormFactor | Desde | Navegación | Contenido |
|---|---|---|---|
| `compact` | 0 | Barra inferior: Inicio · Explorar · **+** · Actividad · Perfil | Una columna |
| `medium` | 700 | Rail con íconos (las mismas cuatro) | Una columna centrada |
| `expanded` | 1100 | Rail extendido + Studio y Moderación | Columna + panel lateral |

- **Los destinos se declaran una vez** (`ShellDestinations`) y los leen la barra
  y el rail. Así fue como `/studio` y `/moderation` existían como rutas sin
  forma de llegar a ellas: dos listas separadas.
- **`branch` es explícito en cada destino**, no la posición en la lista. Al
  filtrar los de escritorio, un índice posicional se corre y las pestañas
  siguientes apuntan al branch equivocado.
- **Un branch sin entrada en el rail no selecciona nada** (`null`), no el
  índice 0. El shell viejo hacía `indexWhere(...).clamp(0, n)`, y `-1` se
  convertía en `0`: "Inicio" quedaba encendido estando en Ajustes.

### `NexoPage` — el marco de toda pantalla del shell

**Toda pantalla dentro del shell se construye con `NexoPage` o
`NexoPage.slivers`.** No es preferencia de estilo: resuelve tres cosas que cada
pantalla se equivocaba por su cuenta.

- **El margen lateral.** El shell entrega al hijo cero padding horizontal a
  propósito, para que una portada de perfil pueda sangrar hasta los bordes — y
  durante un tiempo ninguna pantalla lo repuso. **El título "Para ti" se
  dibujaba medio fuera de la pantalla y el chip "Comunidades" se salía por la
  derecha, en todos los teléfonos.** Hoy el margen es el default y el borde a
  borde es opt-in (`fullBleed: true`), así que olvidarlo ya no se puede.
- **El ancho de lectura.** Pasados los 640 una columna de texto deja de leerse;
  en escritorio se centra en vez de estirarse a la ventana.
- **El respiro inferior.** El contenido scrollea por debajo de la barra, así que
  la última tarjeta necesita `NexoPage.bottomInset` o queda bajo las etiquetas.

`NexoPage` es una `CustomScrollView`, así que **lo que va adentro no puede ser
un scrollable propio**: un `ListView` como hijo de la lista de slivers no tiene
altura acotada y revienta en layout. Por eso `FeedSkeleton` es un `Column` y no
un `ListView`.

---

## Diseño

El design system está transcrito de Stitch. Los valores de abajo **son** el
diseño, no una aproximación: si algo en pantalla no coincide, lo que está mal
es la pantalla.

### Colores — `app_tokens.dart`

Cuatro colores base, y todo lo demás sale de ellos:

| Token | Valor | Uso |
|---|---|---|
| `primary` | `#3B82F6` | Acentos, selección, enlaces |
| `secondary` | `#EF4444` | **No es "error"**: es la marca de en vivo y de reacción |
| `tertiary` | `#16A34A` | Confirmación, online, disponibilidad |
| `neutral` | `#172033` | Texto principal y el botón invertido |

- **`primaryDeep` (`#1D4ED8`) es el azul de los CTA rellenos**, no `primary`.
  En el design system el swatch es el acento y el botón usa un paso más
  profundo.
- **`error` y `secondary` son el mismo valor, con dos nombres.** Se elige por
  lo que la pantalla quiere decir: `error` cuando algo falló, `secondary`
  cuando es la insignia de en vivo o el corazón de un like. Pintar un pill de
  "EN VIVO" con un token llamado `error` hace que la próxima persona lo trate
  como un fallo.
- **`secondary` del `ColorScheme` es `primaryDeep`, no `tertiary`.** Material
  saca el tinte de "seleccionado" del contenedor secundario: con el verde ahí,
  **el indicador del rail salía verde** y la selección se leía como
  confirmación.

**Siempre `AppColors`. Nunca hex crudo, nunca `Colors.X`** (salvo
`Colors.white` / `transparent` sobre una superficie de marca, que son
absolutos y no decisiones de paleta). Única excepción: el color de marca de un
tercero (el azul de Google en el botón de identidad). Es suyo, no nuestro.

### Forma — todo es pill

**`AppRadii.pill` es la forma por defecto de todo control**: botones, chips,
campos de búsqueda, snackbars, insignias. No es una variante — un rectángulo
redondeado en un botón se lee como otra app. Los radios `small` / `medium` /
`large` son para superficies (tarjetas, hojas, media), no para controles.

`AppSizes` fija los altos (`buttonHeight` 52, `buttonHeightDense` 44,
`chipHeight` 38, `searchHeight` 46) para que dos pantallas no inventen dos
botones distintos.

### Tipografía

**Bricolage Grotesque** para titulares, **Hanken Grotesk** para cuerpo y
etiquetas. Las dos salen del tema: `context.textTheme`. **Nunca
`TextStyle(fontSize: …)` crudo** salvo para micro-etiquetas (pills de 9–11px)
que no existen en la escala; para un ajuste puntual, `.copyWith()`.

### Componentes compartidos

Antes de escribir un widget, revisar `core/widgets/`:

| Widget | Para qué |
|---|---|
| `NexoWordmark` / `NexoMark` / `NexoLogo` | La marca: header, header chico, presentación |
| `UserAvatar` | Avatar con inicial y anillo opcional (rojo = en vivo) |
| `SearchField` | El buscador pill del design system |
| `SectionHeader` | Título de sección + pista o acción |
| `FilterPill` | Chip de filtro con estado, punto de color y contador |
| `StatusBadge` | EN VIVO, PRO, DESTACADO, VIP — con pulso opcional |
| `PulsingDot` | El punto que late, ya aislado en su capa |
| `compactCount()` | 2845 → "2.8K" |
| `AppOfflineView` | Modo sin conexión con lecturas guardadas |

### Layout de pantalla — `NexoPage`

**Toda pantalla del shell se construye con `NexoPage` o `NexoPage.slivers`.**
Resuelve cuatro cosas que cada pantalla se equivocaba por su cuenta:

- **El margen lateral.** El shell entrega al hijo cero padding horizontal a
  propósito, para que una portada pueda sangrar hasta los bordes, y durante un
  tiempo ninguna pantalla lo repuso: **el título "Para ti" se dibujaba medio
  fuera de pantalla y el último chip se salía por la derecha, en todos los
  teléfonos.** Hoy el margen es el default y el borde a borde es opt-in
  (`fullBleed`).
- **El ancho de lectura.** Pasados los 640 una columna de texto deja de leerse;
  en escritorio se centra.
- **El respiro inferior.** El contenido scrollea bajo la barra, así que la
  última tarjeta necesita `NexoPage.bottomInset`.
- **La barra de marca.** Marca a la izquierda, sección y avatar a la derecha.
  Escrita una vez, no una por pantalla.

`NexoPage` es una `CustomScrollView`, así que **lo que va adentro no puede ser
un scrollable propio**: un `ListView` como hijo de la lista de slivers no tiene
altura acotada y revienta en layout. Por eso `FeedSkeleton` es un `Column`.

### Nada desborda a 320

`test/core/small_screen_overflow_test.dart` monta cada pantalla a 320 de ancho
y falla ante cualquier overflow de RenderFlex. Existe porque **un overflow no
rompe la app**: pinta la banda amarilla en debug y en release recorta en
silencio — y lo que recorta es siempre lo último de la fila, que en este diseño
suele ser la insignia de "en vivo" o el botón de acción. La primera corrida
encontró **once** filas rotas.

Las tres técnicas, y cuándo va cada una:

| Síntoma | Arreglo |
|---|---|
| Fila de insignias que no entra | `Wrap` — baja de renglón en vez de recortar |
| Texto largo junto a controles fijos | `Flexible`/`Expanded` + `overflow: ellipsis` |
| `Spacer` + `Flexible` peleando | **Nunca los dos**: el Spacer se lleva todo el espacio libre y deja al Flexible en cero, así que el texto se dibuja a su ancho mínimo y desborda igual. Expandir el propio texto |

Y una trampa aparte: **un `title` de `AppBar` centrado recibe restricciones
sueltas**. Una fila que ocupa el ancho completo puesta ahí se mide por su
contenido y desborda; el compositor necesita `centerTitle: false`.

### Animaciones — `animate_do`, vía `core/animations/app_motion.dart`

Todo lo que entra pasa por `Enter`, `EnterStatic` o `Pop`, para que el producto
entero se mueva a un solo tempo. Tres reglas, y las tres salieron de romperlas:

- **Lo que se mueve es lo que no se toca.** Una traslación deja al hijo
  desplazado de su posición final mientras dura, y el hit test sigue al
  transform: en esa ventana los toques caen al vacío. El contenido se desliza
  (`Enter`); todo lo tappable sólo aparece (`EnterStatic`).
- **El stagger tiene techo** (`AppMotion.maxStaggerSteps`, 12). Multiplicar por
  el índice crudo hace que el item 30 espere tres segundos, así que un feed que
  se scrollea rápido muestra tarjetas en blanco.
- **`animate: false` de `animate_do` NO significa "sin animar".** Deja al hijo
  en el frame cero, que para un scale-and-fade es **invisible**. Cableado de la
  forma obvia, **todos los corazones sin like desaparecieron del feed** y quedó
  un contador sin nada que tocar. Por eso `Pop` devuelve el hijo tal cual
  cuando no hay que animar, en vez de pasar el flag.
- **Nada bloquea la UX**: 200–400 ms, `delay` con moderación, y nunca una
  animación de más de 500 ms sin que el usuario la haya pedido.

**Lo que se repite necesita un `RepaintBoundary`.** Un pulso o un shimmer
programa un repintado por frame; sin la barrera, ese repintado sube al ancestro
y vuelve a rasterizar todo lo que comparte la capa — normalmente una miniatura
de video.

## Testing

Cuatro niveles, y cada uno responde algo que los otros no pueden:

| Nivel | Dónde | Qué prueba |
|---|---|---|
| Unit | `test/features/*/domain`, `test/core` | Reglas puras: formatos, guardas, catálogos |
| Cubit | `test/features/*/presentation` | Transiciones de estado con `bloc_test` |
| Widget | `test/features/*/presentation`, `test/widgets` | Que la pantalla dibuje y reaccione |
| Integration | `integration_test/` | El recorrido completo sobre un dispositivo |

### `AppHarness` — cómo se arranca la app en un test

**Nunca llamar `configureDependencies()` a pelo en un test.**
`SharedPreferences.getInstance()` no tiene lado de plataforma en un test: el
`await` **no completa nunca** y el test se cuelga hasta el timeout de 10
minutos del suite. Dos tests de este repo morían así y el suite igual reportaba
verde porque el comando estaba piped a `tail`, que se come el exit code.

Usar `AppHarness.bootstrap()` (`test/support/app_harness.dart`), que siembra
`SharedPreferences` en memoria y resetea GetIt entre tests.

**`configureDependencies()` corta si el grafo ya está armado**, así que sin el
reset todos los tests comparten un contenedor: lo que el primero escribe en
preferencias se filtra al resto y el suite pasa o falla según el orden de los
archivos.

### Correr los tests

```bash
cd apps/nexo_social && flutter test
```

**No pipear a `tail`/`head`.** El exit code que importa es el de `flutter test`,
y una tubería devuelve el del último comando: un suite en rojo se ve verde.
Para acortar la salida, `flutter test --reporter=failures-only`.

### Tests del backend

```bash
cd services/serverpod/nexo_server
SERVERPOD_PASSWORD_database=cualquier-valor dart test
```

No necesitan Docker: `config/test.yaml` define `database.dataPath` y Serverpod
levanta un PostgreSQL embebido. **Falla si la carpeta de datos queda en una
ruta con espacios** (por ejemplo, un repo en `social media`): todos los tests
de integración caen con *"Another process is using the local database"*,
aunque no haya nada corriendo. No es un bug del código: es la ruta del
`dataPath`. Se arregla apuntándolo a una ruta sin espacios, sin tocar la
configuración:

```bash
SERVERPOD_DATABASE_DATA_PATH="$HOME/.nexo/test-pgdata" \
SERVERPOD_PASSWORD_database=cualquier-valor dart test
```

`tool/demo.sh` hace lo mismo con la base de desarrollo cuando hace falta.

Si una corrida se corta, puede quedar un PostgreSQL huérfano en
`.serverpod/test/pgdata`. Cerrarlo antes de volver a correr.

### Tests de guarda (`test/architecture/`)

Escanean el fuente y fallan ante una violación. Existen porque estos bugs son
**ausencias**: una línea que nadie escribió no falla ruidosamente, sólo deja la
pantalla rota.

| Test | Qué hace fallar |
|---|---|
| `layer_boundaries_test` | `Dio`/`SharedPreferences` en `presentation/`; `domain/` importando `flutter/material` o `data/` |
| `design_tokens_test` | Hex crudo o `Colors.X` fuera de `app_tokens.dart`, y literales de ruta en `context.go/push` |
| `page_frame_test` | Una página del shell que no use `NexoPage`, o que anide su propio `Scaffold` |
| `small_screen_overflow_test` | Cualquier pantalla que desborde a 320 de ancho |

Si un test de guarda molesta, la respuesta es arreglar el código o **agregar la
excepción con su motivo escrito** en la allowlist del propio test — nunca
borrar el test. Una red más ancha que el pez obliga a tirar la red.

---

## El piso de Flutter es 3.47.5, y falla de forma poco obvia

`nexo_client` —el cliente generado por Serverpod— declara `sdk: '^3.12.2'`, y
esa restricción la hereda el app por depender de él por path. Con un SDK menor
**no falla al compilar: falla al resolver**, así que `pub get`, `analyze`,
`test` y `run` se caen todos juntos con un mensaje sobre *version solving* que
no nombra a Serverpod:

```
Because nexo_social depends on nexo_client from path
which requires SDK version ^3.12.2, version solving failed.
```

Es fácil leerlo como un problema del app, porque el app declara `^3.12.1` y su
propio pubspec se ve bien. El constraint que manda está en
`services/serverpod/nexo_client/pubspec.yaml`, y lo regenera Serverpod: no se
edita a mano, se actualiza el SDK.

Subir de 3.44 a 3.47 además **sube el deployment target de iOS de 13.0 a
15.0** (`Podfile`, `project.pbxproj`). Lo hace el propio tooling la primera vez
que se buildea, así que esos archivos aparecen modificados sin que nadie los
haya tocado.

---

## Comandos

```bash
# Móvil (simulador iOS ya levantado)
cd apps/nexo_social && flutter run

# Escritorio nativo
cd apps/nexo_social && flutter run -d macos

# Web
cd apps/nexo_social && flutter run -d chrome

# Contra una API real en vez de los mocks
flutter run --dart-define=DATA_SOURCE=api --dart-define=API_BASE_URL=http://localhost:8080

# Calidad — los dos tienen que pasar antes de un commit
flutter analyze
flutter test
```

`flutter analyze` **no debe introducir warnings nuevos**. Hoy está en cero.

---

## Reglas de oro

1. **Nunca lógica de negocio ni llamadas de red en la capa de UI.**
2. **`flutter analyze` limpio y `flutter test` verde antes de commitear** — y
   mirando el exit code, no la última línea.
3. **Toda pantalla del shell se construye con `NexoPage`.** Es lo que garantiza
   márgenes, ancho de lectura y respiro inferior.
4. **Revisar `core/widgets/`, `core/layout/` y `core/animations/` antes de
   escribir un widget nuevo.**
5. **Revisar `AppColors` antes de usar un color y el `textTheme` antes de un
   `TextStyle`.**
6. **Rutas por `AppRoutes`, nunca literales.**
7. **`Equatable` con `props` completo en todo estado.**
8. **Un estado por resultado**: loading, empty, error y success. Una pantalla
   que sólo tiene spinner y contenido hace que un endpoint caído se vea igual
   que uno lento.
9. **`unawaited()` para todo Future fire-and-forget** (`import 'dart:async'`).
10. **`git mv` para mover o renombrar archivos** — preserva el blame.

---

## Decisiones ya tomadas

- **El acceso de invitado es efímero a propósito.** `exploreAsGuest()` *limpia*
  el almacenamiento en vez de escribir una sesión: reabrir la app no debe
  restaurar un invitado. Está dicho en la pantalla, no sólo en el código.
- **`AuthCubit` es singleton, no factory.** La guarda del router, el shell y el
  perfil leen la misma sesión; con un factory, cerrar sesión en un lado dejaría
  a los otros autenticados. **Consecuencia:** ninguna pantalla puede envolverlo
  en `BlocProvider(create:)` — ese provider **cierra** lo que construyó al
  desmontarse, y cerraría la sesión de toda la app. Se lee del árbol.
- **`Post.createdAt` es un `DateTime`, no un string.** Una cadena escrita al
  construir congela "hace 25 min" para siempre, que es literalmente lo que el
  feed mostraba en cada publicación sin importar su edad. El formato vive en
  `RelativeTime`, con `now` inyectable para poder testearlo.
- **El id de un borrador es temporal, no `draft-${length + 1}`.** Ese esquema
  repite un id apenas se borra algo, y dos posts con la misma key hacen que la
  lista reutilice el elemento equivocado.
- **Un enum nunca se pinta con `.name`.** Es el identificador de Dart: la lista
  de vivos mostraba "live", "scheduled", "recorded" —en inglés, en una app en
  español—. La etiqueta va en el enum (`FeedFilter.label`,
  `NotificationType.label`) o en una extensión de presentación
  (`LiveStatusUI.label`) cuando además necesita color.
- **La auditoría de moderación es append-only.** Un comentario oculto se mueve
  a `hiddenComments`, no se borra: una auditoría que borra lo que audita no
  prueba nada, y probar que la moderación queda registrada es el punto de la
  demo.
- **Resolver un reporte aplica la acción y lo saca de la cola en un solo paso.**
  Dos llamadas sueltas dejan ocultar un comentario y no cerrar su reporte, así
  que el siguiente moderador revisa algo ya resuelto.
- **"Marcar todo" marca todo, no sólo lo visible.** Con un filtro activo, saltar
  los ocultos deja un badge que el usuario cree haber limpiado.
- **Las transiciones de vivo que se ofrecen son sólo las que el backend acepta
  desde ese estado.** La máquina de estados es del servidor; un botón para una
  transición ilegal es una petición que se rechaza después de que el usuario ya
  se comprometió.
- **El pago es simulado y la pantalla lo dice.** Una demo de pagos que parece un
  cobro real es lo único que un mock de pagos no puede hacer.
- **La cuenta de demo es Elena en los dos caminos.** Iniciar sesión y
  registrarse devuelven la misma identidad a propósito: todo el contenido mock
  —feed, perfil, vivos— es de ella, y una sesión con otro nombre dejaba la
  barra del perfil diciendo `@creador` mientras el cuerpo decía `@elena_ux`.
- **La portada del perfil no es un `SliverAppBar`.** El avatar se monta a
  caballo entre portada y resumen, y un sliver recorta lo que se sale de su
  caja: con la portada en su propio sliver, la mitad superior del avatar
  desaparecía. Portada, avatar y resumen comparten una sola caja.
- **La sala en vivo es inmersiva.** El video ocupa todo y el chrome flota
  encima con un velo en degradado; el chat no vive en una hoja blanca debajo.
  Partir la pantalla en dos deja el video del tamaño de una miniatura, que es
  lo contrario de lo que alguien viene a hacer ahí. Es la única pantalla
  exenta de `NexoPage`.
- **Moderar sale de una pulsación larga sobre el comentario**, no de un ícono
  por fila: con seis acciones disponibles, un control por mensaje convierte el
  chat en una consola. La hoja **devuelve** una decisión en vez de aplicarla —
  en un directo la aplica el cubit de la sala, en la consola el de moderación.
- **Elegir la duración de un silenciamiento no silencia.** Los chips arman la
  decisión y "Aplicar" la confirma: aplicar en el tap del chip deja al
  moderador sin forma de corregirse.
- **El editor de encuesta es `StatefulWidget` y es dueño de sus controllers.**
  Construirlos en `build` los recrea en cada tecla: el cursor salta al
  principio apenas el cubit emite, y cada controller descartado queda sin
  liberar.
- **El mock es un servidor falso, no una colección de mocks.** Auth, vivos,
  moderación y consola leen y escriben un solo `MockPlatform`
  (`core/mock/`), que aplica las reglas que va a tener Serverpod —scopes, gate
  de verificación, máquina de estados del vivo, auditoría todo-o-nada— y lanza
  los mismos `Failure`. Con un estado por repositorio, la consola no afectaba
  al resto de la app. Un repositorio mock nuevo va encima de él, no al lado.
- **Creador no es un rol.** `UserRole` son los scopes (`visitor`, `user`,
  `moderator`, `operator`); ser creador y estar verificado viven en el perfil
  (`isCreator`, `verification`), igual que en el backend. `/moderation` exige
  moderador u operador, y `/admin` exige operador.
- **En web, la sesión mock va a `sessionStorage`** (`SessionStorage`), no a
  `SharedPreferences`. Así dos pestañas pueden tener dos cuentas mientras
  comparten el estado de `MockPlatform` por `localStorage`, que es la demo de
  suspensión en el acto. `PlatformSync` escucha el evento `storage`. Las dos
  cosas se borran cuando exista el backend.
- **Los assets son WebP.** Hoy sólo hay `assets/branding/nexo_mark.svg`. Al
  sumar imágenes: medir antes de convertir, y acotar el decode de cualquier PNG
  grande — Flutter decodifica a resolución nativa y se queda con ese bitmap.

---

## Pendiente (en orden)

1. **Comentarios de post** — crear, ocultar, eliminar.
2. **Detección de conectividad.** `AppOfflineView` existe y está completa, pero
   hoy sólo se muestra cuando quien la invoca ya sabe que el fallo fue de red.
   Nada observa la conexión todavía.
3. **Paginación por cursor y caché offline del feed.** El modo offline lista
   lecturas guardadas de mentira; no hay caché real detrás.
4. **Agora detrás de `LiveMediaGateway`**, con tokens emitidos por Serverpod.
   El cliente nunca genera un token ni decide volverse broadcaster. Los
   controles del Studio (girar, silenciar, EQ) esperan eso para hacer algo.
5. **Conectar los contratos mock al backend Serverpod.**

### Del diseño, lo que falta

- **El selector ES/EN del onboarding está dibujado pero no traduce.** Decisión
  tomada: el control existe para que la pantalla coincida con el mockup, y la
  deuda queda a la vista en vez de escondida. Hoy **nada lee ese valor**, así
  que no puede desincronizarse con nada; al montar `gen-l10n` pasa a leer y
  escribir el `LocaleCubit` y esa es la única línea que cambia.
- **Filtros de media en el compositor** ("Filtro Cálido") y el nombre/peso real
  del archivo: no hay subida, así que el adjunto es un placeholder que se
  nombra a sí mismo.
- **Cohosts en la sala de audiencia.** El panel de host ya aprueba solicitudes;
  falta el PiP del cohost sobre el video, que necesita medios reales.
