# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

- **Creadores**: publican posts, programan e inician vivos, invitan cohosts y
  monetizan con suscripciones VIP. Su trabajo es mantener viva a su comunidad.
- **Audiencia**: personas que siguen a sus creadores. Entran a mirar el feed,
  descubrir vivos y perfiles, reaccionar y comentar. Muchas llegan como
  visitantes sin cuenta y se convierten en usuarios dentro de la app.
- **Moderadores y operadores**: cuidan la comunidad. Ocultan comentarios,
  silencian, resuelven reportes y suspenden cuentas, y todo queda auditado.

La demo del hackathon se muestra **en un teléfono (simulador iOS)**. Escritorio
y web existen y se adaptan, pero son secundarios.

## Product Purpose

Nexo es una red social para creadores y sus comunidades: feed, contenido, vivos
y monetización en un mismo lugar. Para el hackathon, el éxito es completar el
recorrido entero sin cortes: un creador publica, programa e inicia un vivo,
suma un invitado, un moderador oculta un comentario y el vivo terminado queda
como replay.

## Positioning

En Nexo los vivos no son una sección aparte: son contenido dentro del
descubrimiento, junto a posts, perfiles y categorías. La moderación es de
primera clase y auditable (append-only), no un panel escondido. El backend
(Serverpod) es la autoridad sobre permisos, estados y acceso. La app muestra la
experiencia y nunca decide por su cuenta.

## Operating Context

- Ciclo del vivo: programado → en vivo → terminado → replay. Cada transición
  la acepta el servidor.
- Roles (scopes): visitante, usuario, moderador, operador. Ser creador y estar
  verificado son atributos del perfil, no roles.
- Navegación móvil: Inicio · Explorar · Crear (acción) · Actividad · Perfil.
  En escritorio se suman Studio y Moderación.
- La sala en vivo es inmersiva: el video ocupa toda la pantalla y el chat flota
  encima.
- Moderar sale de una pulsación larga sobre un comentario.

## Capabilities and Constraints

- Cliente Flutter (iOS, Android, macOS, web) con Clean Architecture, BLoC y
  GetIt; backend Serverpod + PostgreSQL. Hoy los datos son mock o vienen de
  Serverpod según el entorno.
- Video en vivo con Agora (etapa A integrada). Pagos e IA son simulados, y la
  pantalla lo dice.
- La app está en español. El selector ES/EN del onboarding existe pero todavía
  no traduce.
- Restricciones de calidad: nada desborda a 320 de ancho (hay un test), cero
  warnings en `flutter analyze` y tests de arquitectura que vigilan capas,
  tokens y marco de página.

## Brand Commitments

- **Nombre:** Nexo (Nexo Social).
- **Logo:** gato blanco con contorno negro grueso y un borde exterior
  holográfico (cian → azul → violeta/magenta, y amarillo-verde → verde → cian),
  estilo sticker, sobre negro. Archivo: `logo nexo.png` en la raíz del repo.
- **El gato es la mascota con personalidad**: aparece en estados vacíos, carga,
  errores, logros y onboarding, no sólo en el logo. Lo decidió el usuario.
- **Íconos e ilustraciones se generan con Higgsfield usando el modelo más
  barato** (Z Image). Las animaciones vendrán después, también con los modelos
  más baratos.
- El rediseño debe dejar de parecer "hecho por IA".

## Evidence on Hand

- El logo: `logo nexo.png` (1254×1254, PNG).
- El contenido de demo es mock: la cuenta de demo es Elena (`@elena_ux`).
- No hay testimonios, métricas reales, clientes ni prensa. No inventarlos.

## Product Principles

1. **El recorrido de la demo no se corta.** Toda decisión visual se mide en si
   publicar → vivo → invitado → moderación → replay se entiende a la primera.
2. **Los vivos son contenido, no una sección.** Viven en el descubrimiento,
   junto a lo demás.
3. **La moderación se ve y deja rastro.** Una acción de moderación siempre
   queda registrada y visible.
4. **Honestidad del mock.** Lo simulado (pagos, IA) se dice en pantalla.
5. **El servidor decide.** La interfaz sólo ofrece las acciones que el backend
   acepta en ese estado.
