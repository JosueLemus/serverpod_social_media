---
name: Nexo Social
description: Red social para creadores y comunidades, construida como una plancha de stickers troquelados sobre un liner negro.
colors:
  liner: "#0F0F12"
  liner-raised: "#18181D"
  liner-high: "#23232B"
  sticker: "#FFFFFF"
  ink: "#0F0F12"
  ink-secondary: "#57555F"
  vinyl-cyan: "#3FE0F2"
  vinyl-blue: "#4F7BFF"
  vinyl-violet: "#9B5CFF"
  vinyl-magenta: "#E24CF2"
  vinyl-lime: "#C9F24A"
  vinyl-green: "#3EE58C"
  primary: "#8E8BFF"
  primary-deep: "#5B4BFF"
  primary-surface: "#211F38"
  primary-surface-deep: "#2D2A55"
  secondary: "#F0234A"
  success-surface: "#12291E"
  warning: "#FFB020"
  text-primary: "#F4F3EF"
  text-secondary: "#A09EAB"
  text-tertiary: "#6C6A76"
  text-on-brand-surface: "#C7C3FF"
  border: "#2B2A33"
  stage-dark: "#070709"
  stage-scrim: "#99070709"
typography:
  display:
    fontFamily: "DelaGothicOne"
    fontSize: "34px"
    fontWeight: 400
    lineHeight: 1.12
    letterSpacing: "-0.6px"
  headline:
    fontFamily: "DelaGothicOne"
    fontSize: "24px"
    fontWeight: 400
    lineHeight: 1.12
    letterSpacing: "-0.2px"
  title:
    fontFamily: "DelaGothicOne"
    fontSize: "18px"
    fontWeight: 400
    lineHeight: 1.12
    letterSpacing: "0px"
  title-small:
    fontFamily: "MPlusRounded"
    fontSize: "15.5px"
    fontWeight: 800
    lineHeight: 1.3
  body:
    fontFamily: "MPlusRounded"
    fontSize: "14.5px"
    fontWeight: 500
    lineHeight: 1.4
  label:
    fontFamily: "MPlusRounded"
    fontSize: "15px"
    fontWeight: 800
    lineHeight: 1.2
  label-small:
    fontFamily: "MPlusRounded"
    fontSize: "11px"
    fontWeight: 700
    lineHeight: 1.2
rounded:
  small: "10px"
  medium: "18px"
  large: "26px"
  pill: "999px"
spacing:
  xxs: "4px"
  xs: "8px"
  sm: "12px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  xxl: "48px"
components:
  button-primary:
    backgroundColor: "{colors.sticker}"
    textColor: "{colors.ink}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "0 24px"
    height: "52px"
  button-primary-disabled:
    backgroundColor: "{colors.liner-high}"
    textColor: "{colors.text-tertiary}"
  button-primary-in-sticker:
    backgroundColor: "{colors.ink}"
    textColor: "{colors.sticker}"
    rounded: "{rounded.pill}"
    height: "52px"
  button-outline:
    textColor: "{colors.text-primary}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
    padding: "0 24px"
    height: "52px"
  button-text:
    textColor: "{colors.primary}"
    typography: "{typography.label}"
    rounded: "{rounded.pill}"
  chip-filter:
    backgroundColor: "{colors.liner-high}"
    textColor: "{colors.text-secondary}"
    rounded: "{rounded.pill}"
    padding: "0 16px"
    height: "38px"
  chip-filter-selected:
    backgroundColor: "{colors.sticker}"
    textColor: "{colors.ink}"
  input-field:
    backgroundColor: "{colors.liner-high}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.pill}"
    padding: "12px 16px"
  input-search:
    backgroundColor: "{colors.liner-high}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.pill}"
    height: "46px"
  card-panel:
    backgroundColor: "{colors.liner-raised}"
    rounded: "{rounded.medium}"
  card-sticker:
    backgroundColor: "{colors.sticker}"
    textColor: "{colors.ink}"
    rounded: "22px"
    padding: "16px"
  status-badge:
    backgroundColor: "{colors.secondary}"
    textColor: "{colors.sticker}"
    rounded: "{rounded.pill}"
    padding: "3px 7px"
  snackbar:
    backgroundColor: "{colors.sticker}"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
  nav-create:
    backgroundColor: "{colors.sticker}"
    textColor: "{colors.ink}"
    rounded: "16px"
    width: "52px"
    height: "44px"
---

# Design System: Nexo Social

## Overview

**Creative North Star: "La plancha de stickers"**

Nexo es una plancha de vinilo troquelado. El suelo de toda la app es el liner negro brillante sobre el que vienen pegados los stickers, y todo lo que se publica, se reacciona o se colecciona es un sticker cortado exactamente como el gato del logo: relleno blanco, contorno grueso de tinta y borde troquelado. El sistema rechaza el default de la categoría (un feed blanco de tarjetas redondeadas con borde y un solo acento azul): acá la acción principal es un sticker blanco sobre negro, y el color viene en vinilos planos sacados del borde holográfico del logo.

El borde de un sticker no es decoración: es el vocabulario de estado de la app. Troquel blanco es lo normal (y lo que queda cuando un vivo termina y pasa a replay), foil holográfico girando es lo que está al aire, línea de corte punteada es lo programado que todavía no se despegó, y el dorso (liner hacia arriba, sin troquel, con el motivo impreso) es lo oculto. La densidad es la de una app móvil de consumo: una columna, controles de 44 a 52 de alto, ritmo en múltiplos de 4.

Es oscuro por dónde se usa (en la cama, de noche, con el brillo bajo) y por el material: un troquel blanco sólo se lee sobre un liner negro. El gato de la marca acompaña cada momento vacío, roto o de bienvenida, para que un estado vacío siga sintiéndose Nexo.

**Key Characteristics:**
- Liner negro (`liner`) como suelo único; paneles que suben un paso (`liner-raised`, `liner-high`) en vez de sombras.
- La acción principal es un sticker blanco con texto de tinta; seleccionar es despegar (gris en reposo, blanco al elegir).
- El borde dice el estado: troquel, holo, punteado o dorso.
- Holo reservado para lo que está al aire y para la marca.
- Toda forma de control es una pastilla.
- Íconos propios (`NexoIcon`, 80 SVG de trazo redondeado) y el gato mascota en 15 estados.
- Movimiento corto: las reacciones se "pegan" con un slap (escala y giro), nunca con un fundido.

## Colors

Un liner casi negro, un blanco de sticker, seis vinilos planos del holo del logo y un rojo de sticker caliente para vivo y reacción.

### Primary
- **Blanco Sticker** (`sticker`): el relleno de la acción principal. Todo CTA, chip seleccionado, indicador del rail, snackbar, tooltip y la tecla de crear son stickers blancos con tinta encima. También es el troquel de cada sticker.
- **Lila Holo** (`primary`): enlaces, foco, cursor, progreso y el botón de texto. Es el lila del centro del holo, el que se lee sobre el liner.
- **Iris Profundo** (`primary-deep`): relleno de marca que lleva texto blanco, el texto de acción dentro de una `StickerCard` y la acción de la snackbar. Nunca texto sobre el liner: no llega al contraste.
- **Superficie de Marca** (`primary-surface`, `primary-surface-deep`): fondos teñidos de marca y el degradado de placeholders de media; el texto encima es `text-on-brand-surface`.

### Secondary
- **Rojo Sticker** (`secondary`): la marca de en vivo y de reacción (pill EN VIVO, corazón, severidad alta, el contador de la barra). `error` apunta al mismo valor; se elige el nombre por lo que dice la pantalla.

### Tertiary
- **Vinilos** (`vinyl-cyan`, `vinyl-blue`, `vinyl-violet`, `vinyl-magenta`, `vinyl-lime`, `vinyl-green`): rellenos planos de insignias, avatares sin foto y highlights. Llevan **tinta** encima, no blanco. `vinylFor(seed)` asigna a cada persona un vinilo estable por su nombre. `vinyl-green` es además `tertiary`/`success` (confirmación, online), y `vinyl-lime` marca rol de staff (anillo del avatar, insignia OPERADOR/MODERADOR) y la pista del switch encendido.
- **Ámbar** (`warning`): "mirá esto", distinto de error.

### Neutral
- **Liner** (`liner`): el suelo de toda la app, scaffold, app bar, barra inferior y rail.
- **Hoja** (`liner-raised`): paneles, tarjetas, hojas inferiores y diálogos.
- **Hoja Alta** (`liner-high`): campos, chips en reposo, controles apagados, menús, el dorso de un sticker oculto.
- **Tinta** (`ink`): contorno de sticker y texto sobre blanco; `ink-secondary` es el texto secundario sobre blanco.
- **Texto** (`text-primary`, `text-secondary`, `text-tertiary`): crema cálida, gris lavanda, y un tercer gris sólo para deshabilitado (no llega a 4.5:1).
- **Filete** (`border`): divisores y bordes de panel a 1 px.
- **Escenario** (`stage-dark`, `stage-scrim`): video y salas en vivo, y el velo al 60 % que deja legible el chrome encima.

### Named Rules
**The On-Air Holo Rule.** El foil holográfico (cyan → azul → violeta → magenta → lima → verde → cyan, girando una vuelta cada 8 s) sólo rodea lo que está pasando ahora y la marca. Gastarlo en decoración le quita el significado.

**The Ink-On-Vinyl Rule.** Sobre un vinilo o sobre el blanco va tinta; el blanco como texto sólo va sobre `secondary`, `primary-deep` o media oscura.

**The Name-By-Meaning Rule.** `secondary` y `error` son el mismo rojo con dos nombres: `error` cuando algo falló, `secondary` cuando es vivo o reacción. Siempre `AppColors`, nunca hex crudo.

## Typography

**Display Font:** Dela Gothic One (`AppFonts.display`, empaquetada, subset Latin)
**Body Font:** M PLUS Rounded 1c (`AppFonts.text`, pesos 400 a 900, empaquetada, subset Latin con elipsis reconstruida)

**Character:** Una gótica japonesa de trazo grueso como voz de sticker, contra una sans de terminaciones redondeadas que repite el contorno del gato. El contraste es de peso y de forma, no de tamaño.

### Hierarchy
- **Display** (400, 34 / 30 / 26 px, 1.12, tracking -0.6 / -0.5 / -0.4): títulos de presentación (onboarding, muros de acceso).
- **Headline** (400, 24 / 22 / 20 px, 1.12, -0.2): títulos de página (`NexoPage`) y de diálogo.
- **Title** (400 Dela, 18 px, 1.12, 0): encabezados de sección y título de app bar.
- **Title small** (M PLUS 800, 15.5 / 14 px, 1.3): nombres, títulos de fila y de lista.
- **Body** (M PLUS 500, 16 / 14.5 / 12.5 px, 1.4): cuerpo; el pequeño va en `text-secondary`. La columna nunca supera 640 de ancho.
- **Label** (M PLUS 800 / 700 / 700, 15 / 13 / 11 px, 1.2): botones (15), chips y menús (13), metadatos (11).

### Named Rules
**The Sticker Voice Rule.** Dela Gothic One sólo para titulares (display, headline, title y la inicial de un avatar); todo lo demás es M PLUS Rounded. Siempre desde `context.textTheme`.

**The Micro-Label Exception.** Un `TextStyle` crudo sólo para micro-etiquetas de 9 a 11.5 px que no existen en la escala (el texto de `StatusBadge`: 10 px, 900, mayúsculas, tracking 0.5).

## Layout

Una columna, siempre. `FormFactor` resuelve toda decisión responsive: `compact` (0) con barra inferior, `medium` (700) con rail de íconos, `expanded` (1100) con rail extendido, Studio, Moderación y panel lateral. Toda pantalla del shell es `NexoPage`: margen lateral de 16 en compacto y 24 desde medium, ancho de lectura máximo de 640 centrado, y 96 de holgura inferior para pasar la barra. El borde a borde es opt-in (`fullBleed`).

El ritmo sale de `AppSpacing` (4, 8, 12, 16, 24, 32, 48): 16 dentro de un sticker, 24 de padding horizontal en botones, 32 sobre cada encabezado de sección y 12 debajo. Los altos de control son fijos (`AppSizes`): CTA 52, botón denso 44, chip 38, búsqueda 46, avatar de header 34, ícono 24. Las tarjetas no traen margen propio; el gap lo define la pantalla. Nada desborda a 320: filas de insignias en `Wrap`, texto largo en `Expanded` con elipsis.

## Elevation & Depth

Plano por defecto. Sobre un liner negro una sombra casi no se ve, así que la separación la hacen los pasos de liner (`liner` → `liner-raised` → `liner-high`), el filete de 1 px y, sobre todo, el troquel blanco. Card, app bar, snackbar y diálogos van con elevación 0.

### Shadow Vocabulary
- **Sombra de marca** (`brandShadow` `#665B4BFF`, blur 16, offset 0 6): sólo la tecla de crear de la barra inferior, para despegarla de la tira.
- **Sombra de despegue** (`shadow` `#66000000`): reservada en el `ColorScheme` para lo que se levanta (un sticker alzado, una hoja); hoy ningún componente propio la usa.

### Named Rules
**The Cut-Not-Shadow Rule.** La profundidad de un sticker es su troquel (`AppStroke.kissCut` 3) y su contorno de tinta (`AppStroke.ink` 2.5), no una sombra. Nada de sombras duras desplazadas.

## Shapes

Todo control es una pastilla (`pill`, 999): botones, chips, campos, búsqueda, insignias, snackbars, tooltips, el indicador del rail y el segmented button. Los radios `small` (10), `medium` (18) y `large` (26) son para superficies: checkbox y miniaturas, tarjetas y filas, diálogos y tiles grandes; la hoja inferior lleva 28 arriba. `StickerCard` usa 22 de radio interior.

El troquel sigue la forma del contenido: el radio exterior de un `StickerFrame` es el interior más el ancho del borde, para que la esquina de afuera nunca quede más cerrada que la de adentro. Los avatares son stickers redondos con un aro blanco proporcional (6 % del tamaño, entre 1.5 y 4) y, si tienen estado, un anillo separado por un aro de liner.

### Named Rules
**The Pill Control Rule.** Un rectángulo redondeado en un control se lee como otra app. La única excepción hoy es la tecla de crear (52 × 44, radio 16).

**The Edge-Is-State Rule.** `StickerEdge.kissCut` = normal o replay; `holo` = al aire; `dashed` = programado (gris `text-secondary`, trazos de 6 con 5 de gap); `none` = media ya dentro de otro sticker. Oculto es el dorso: `liner-high`, sin borde, con el motivo impreso. Ningún borde se usa por fuera de su significado.

## Components

### Buttons
Stickers que se aprietan.
- **Shape:** pastilla (999), alto 52 (44 denso), padding horizontal 24, etiqueta Label 15/800.
- **Primary (`FilledButton`):** `sticker` con texto `ink`; deshabilitado en `liner-high` con `text-tertiary`. Dentro de una `StickerCard` se invierte solo: relleno `ink`, texto blanco.
- **Outline:** transparente, texto `text-primary`, borde de 1.6 al 38 % de `text-primary`; dentro de una `StickerCard`, borde y texto en tinta.
- **Text:** `primary` sobre el liner, `primary-deep` dentro de un sticker.
- **Icon:** mínimo 44 × 44, siempre con `NexoIcon`.

### Chips
- **Style (`FilterPill`):** 38 de alto, padding 16, `liner-high` con texto `text-secondary` en reposo, sin borde. Punto de color opcional (8 px) y contador tabular.
- **State:** seleccionado = despegado: `sticker` con texto `ink`, transición de 220 ms easeOutCubic. Un solo componente para toda la app.

### Cards / Containers
- **Panel:** `liner-raised`, radio 18, filete `border`, sin margen ni sombra. Para listas densas, nada de tarjeta: filas sobre el liner separadas por filetes.
- **StickerCard:** el objeto que la pantalla quiere que se vea como objeto (un reporte en la cola, un plan, un aviso del staff). Relleno blanco, contorno de tinta de 2.5 y troquel blanco de 3 sobre el liner, radio interior 22, padding 16. Adentro todo pasa a tinta y el contenido debe leer el tema con un contexto que esté **dentro** de la tarjeta.
- **StickerFrame:** recorta media o un panel con su borde de estado (radio 18 por defecto).

### Inputs / Fields
- **Style:** pastilla `liner-high` sin borde, padding 12 × 16, hint en `text-secondary`. `SearchField` es de 46 con la lupa propia a la izquierda.
- **Focus:** borde `primary` de 1.6; la etiqueta flotante pasa a `primary`.
- **Error:** borde `error` de 1.6.

### Status Badge
Un sticker chico: vinilo de color con un troquel blanco de 1.5, padding 3 × 7, texto en mayúsculas 10/900. Rojo con texto blanco por defecto (EN VIVO, con `PulsingDot` sólo si está pasando ahora); vinilo con tinta para rol, severidad o plan. **The Hand-Slapped Tilt Rule.** Una insignia pegada encima de otro sticker (la esquina de una media, el borde de un plan) va apenas torcida (±0.05 rad), como pegada a mano; dentro de una fila de texto va derecha.

### Navigation
- **Barra inferior (compact):** tira `liner` de 62 con filete superior; Inicio · Explorar · crear · Actividad · Perfil. Ícono de 26 en contorno, relleno al seleccionar; etiqueta en `text-primary` o `text-secondary`. Contador rojo con aro de liner.
- **Tecla de crear:** sticker blanco 52 × 44, radio 16, "+" de tinta, sombra de marca; se achica a 0.9 en 120 ms al apretar. Sin etiqueta: es una acción, no un destino.
- **Rail (medium/expanded):** liner con filete; indicador pastilla blanca con ícono en tinta.
- **Barra de marca:** `NexoWordmark` (gato de 30 + "nexo" en Dela 20) a la izquierda; sección y avatar de sesión (anillo lima si es staff) a la derecha.

### Mascota y estados
`MascotIllustration` (148 por defecto) encabeza vacíos, errores, offline, éxito y bienvenida con uno de los 15 estados del gato. `CreateSheetWidget` presenta las tres formas de crear con el borde de su estado: publicar (troquel), salir al aire (holo), programar (punteado).

### Motion
`Enter` desliza contenido 18 px en 320 ms; `EnterStatic` sólo funde lo tappable en 240 ms; stagger de 55 ms con techo de 12 pasos. **The Slap Rule.** Reaccionar pega un sticker: `Pop` aterriza a 135 % y -0.12 rad y se asienta en 280 ms con easeOutBack, sólo escala y giro, nunca opacidad. Con "reducir movimiento", holo y slap quedan quietos.

## Do's and Don'ts

### Do:
- **Do** hacer de cada acción principal un sticker blanco con tinta (`FilledButton`), y dejar que `StickerCard` la invierta a tinta adentro.
- **Do** expresar el estado con el borde: troquel, holo (`HoloRing`, aislado en `RepaintBoundary`), punteado o dorso.
- **Do** usar `NexoIcon` para todo ícono: contorno en reposo, relleno al seleccionar.
- **Do** dar a un avatar sin foto el vinilo de `vinylFor(name)` con la inicial en Dela y tinta.
- **Do** poner el gato en todo estado vacío, de error o sin conexión.
- **Do** tomar color, tipo, radio, espacio y alto de `AppColors`, `textTheme`, `AppRadii`, `AppSpacing` y `AppSizes`.

### Don't:
- **Don't** usar el holo en nada que no esté al aire ni sea la marca.
- **Don't** usar la línea punteada para lo oculto: punteado es "programado".
- **Don't** usar `primary-deep` como texto sobre el liner ni `text-secondary` sobre blanco.
- **Don't** mezclar íconos de Material con `NexoIcon`: es otro trazo y otra mano.
- **Don't** dar forma de rectángulo redondeado a un control ni poner sombras duras desplazadas.
- **Don't** usar `text-tertiary` para nada que haya que leer.
- **Don't** usar texto blanco sobre un vinilo.
