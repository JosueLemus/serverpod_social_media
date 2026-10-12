# De dónde salen los íconos de `assets/icons`

Los 80 SVG se generaron así, y se regeneran de la misma forma.

1. **Generación.** GPT Image 2.5 vía Higgsfield, calidad `high`, 1k, fondo
   transparente. Cada plancha es una grilla de 4×4 glifos negros. Las cinco
   están en `sheets/`, con su prompt abajo.
2. **Corte.** `tools/slice_sheet.py <plancha> <salida> nombre1 … nombre16`.
   Corta por componentes conectados y no por una grilla fija, porque GPT
   dibuja la grilla a ojo y un recorte de 256 px se lleva pedazos del vecino.
   Re-centra cada glifo a la escala de la plancha (los tamaños relativos se
   conservan) y lo traza con `potrace`. Corre con `python3 -I`, y necesita
   `magick` y `potrace` (`brew install potrace`).
3. **Limpieza.** Sin `<?xml>`, sin `DOCTYPE` y sin `<metadata>`, con el
   `viewBox` común `40 40 432 432`. Con ese recorte el glifo promedio ocupa el
   84 % de la caja, igual que un ícono de Material, y ninguno se corta.

Las versiones `_outline` y rellenas salen dibujadas por GPT en la misma
plancha, no derivadas por código: así el contorno conserva los detalles
interiores (la huella del escudo, la puerta de la casa).

## Prompts

Todas las planchas comparten este estilo:

> A professional mobile app icon set on a fully transparent background: 16
> icons arranged in a strict 4 by 4 grid with large equal spacing, every icon
> centered in its own cell and the same visual size. Style: bold, friendly,
> rounded geometric glyphs in solid pure black (#000000) only, consistent heavy
> stroke weight (like a 2.5px stroke at 24px), rounded caps and rounded joins,
> soft rounded corners, slightly chunky like the thick outline of a cartoon cat
> sticker. No color, no gradients, no text, no labels, no shadows, no grid
> lines.

Y cada una agrega su contenido:

- **`icons_a.png`.** Fila 1, contorno: casa con dos orejas de gato en el techo
  y puerta en arco; brújula; campana; cabeza de gato con dos ojos ovalados.
  Fila 2: los mismos, rellenos. Fila 3, contorno: cámara de video; escudo con
  huella; escudo con tilde; lupa. Fila 4: los mismos, rellenos.
- **`icons_b.png`.** Contorno y relleno de: corazón, globo de diálogo, avión de
  papel, marcador; señal en vivo, engranaje, corona, foto.
- **`icons_c.png`.** Prompt reescrito como "UI pictogram sheet", porque la
  primera versión cayó en un falso positivo del filtro de contenido. Contorno
  y relleno de: calendario, bandera, candado, ojo tachado; papelera,
  comunidad, barras, play.
- **`icons_e.png`.** Contorno y relleno de: tilde, lápiz, regalo, ecualizador;
  salir, refrescar, cambiar de cuenta, destellos.
- **`icons_d.png`.** Todo en contorno: más, cerrar, más opciones, enviar;
  micrófono, micrófono tachado, sello verificado, estrella; chevrones
  izquierda y derecha, reloj, enlace; cara sonriente, numeral, arroba, girar
  cámara.

## Las fuentes

`../fix_ellipsis.py` rehace el glifo U+2026 de las fuentes empaquetadas como
tres puntos sobre la línea de base. Dela Gothic One y M PLUS Rounded son
japonesas y lo dibujan centrado ("···"). Hay que correrlo de nuevo cada vez que
se vuelva a recortar una fuente con `pyftsubset`.
