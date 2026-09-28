import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../responsive/breakpoints.dart';
import '../widgets/nexo_logo.dart';
import '../widgets/user_avatar.dart';

/// El marco sobre el que se construye toda pantalla del shell.
///
/// Resuelve cuatro cosas que cada pantalla se equivocaba por su cuenta:
///
/// * **El margen lateral.** El shell entrega al hijo cero padding horizontal a
///   propósito, para que una portada de perfil pueda sangrar hasta los bordes,
///   y durante un tiempo ninguna pantalla lo repuso: el título "Para ti" se
///   dibujaba medio fuera de pantalla y el último chip se salía por la derecha
///   en todos los teléfonos. Hoy el margen es el default y el borde a borde es
///   opt-in ([fullBleed]).
/// * **El ancho de lectura.** Pasado [AppBreakpoints.contentMaxWidth] una
///   columna de texto deja de leerse, así que en escritorio se centra.
/// * **El respiro inferior.** El contenido scrollea bajo la barra, así que la
///   última tarjeta necesita [bottomInset].
/// * **La barra de marca.** Todas las pantallas del diseño la llevan: marca a
///   la izquierda, nombre de sección y avatar a la derecha. Escrita una vez,
///   no una por pantalla.
class NexoPage extends StatelessWidget {
  const NexoPage({
    super.key,
    required this.children,
    this.section,
    this.title,
    this.subtitle,
    this.titleActions,
    this.actions,
    this.showBrandBar = true,
    this.fullBleed = false,
    this.scrollController,
    this.onRefresh,
  }) : slivers = null;

  const NexoPage.slivers({
    super.key,
    required this.slivers,
    this.section,
    this.title,
    this.subtitle,
    this.titleActions,
    this.actions,
    this.showBrandBar = true,
    this.fullBleed = false,
    this.scrollController,
    this.onRefresh,
  }) : children = null;

  /// La etiqueta gris en versalitas de la derecha: FEED, PERFIL, ACTIVIDAD.
  /// Dice en qué parte de la app está el usuario sin gastar una línea de
  /// título.
  final String? section;

  /// El titular grande, dentro del scroll. No es el título de una AppBar: se
  /// va al hacer scroll porque en una pantalla de contenido el título es
  /// chrome y el contenido es a lo que la persona vino.
  final String? title;
  final String? subtitle;

  /// Controles a la derecha del titular grande.
  final List<Widget>? titleActions;

  /// Controles en la barra de marca, antes del avatar.
  final List<Widget>? actions;

  final bool showBrandBar;

  /// Quita el margen lateral. Sólo para contenido pensado para tocar los
  /// bordes: portadas, media a ancho completo, superficies de video.
  final bool fullBleed;

  final ScrollController? scrollController;
  final Future<void> Function()? onRefresh;

  /// Exactamente uno de los dos es no nulo; los dos constructores lo
  /// garantizan.
  final List<Widget>? children;
  final List<Widget>? slivers;

  /// Holgura para que el último ítem pase la barra inferior.
  static const bottomInset = 96.0;

  static double gutterOf(FormFactor form) =>
      form.isCompact ? AppSpacing.md : AppSpacing.lg;

  @override
  Widget build(BuildContext context) {
    final form = AppBreakpoints.of(context);
    final gutter = fullBleed ? 0.0 : gutterOf(form);

    final view = CustomScrollView(
      controller: scrollController,
      slivers: [
        if (showBrandBar)
          _BrandBar(section: section, actions: actions, gutter: gutterOf(form)),
        if (title != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                gutterOf(form),
                AppSpacing.md,
                gutterOf(form),
                AppSpacing.sm,
              ),
              child: _PageTitle(
                title: title!,
                subtitle: subtitle,
                actions: titleActions,
              ),
            ),
          ),
        ...slivers ??
            [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, bottomInset),
                sliver: SliverList.list(children: children!),
              ),
            ],
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.contentMaxWidth,
        ),
        child: onRefresh == null
            ? view
            : RefreshIndicator(onRefresh: onRefresh!, child: view),
      ),
    );
  }
}

/// La barra de marca. Fijada, no flotante: es el chrome que ancla la app, y
/// una marca que aparece y desaparece al scrollear se lee como un salto de
/// layout.
class _BrandBar extends StatelessWidget {
  const _BrandBar({
    required this.section,
    required this.actions,
    required this.gutter,
  });

  final String? section;
  final List<Widget>? actions;
  final double gutter;

  @override
  Widget build(BuildContext context) => SliverAppBar(
    pinned: true,
    automaticallyImplyLeading: false,
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    titleSpacing: gutter,
    toolbarHeight: 58,
    centerTitle: false,
    title: const NexoWordmark(),
    actions: [
      if (section != null)
        Text(
          section!.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.textSecondary,
          ),
        ),
      ...?actions,
      const SizedBox(width: AppSpacing.xs),
      // El avatar de la sesión. Mock por ahora: la identidad real llega con
      // Serverpod y este es el único lugar que hay que cambiar.
      const UserAvatar(name: 'Elena Vega', size: AppSizes.avatarHeader),
      SizedBox(width: gutter),
    ],
  );
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
      if (actions != null) ...[
        const SizedBox(width: AppSpacing.xs),
        // Los controles se alinean con la primera línea del titular, no con el
        // centro del bloque: con subtítulo, centrarlos los deja flotando.
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxs),
          child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
        ),
      ],
    ],
  );
}
