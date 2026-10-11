import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/injection.dart';
import '../../app/router/app_routes.dart';
import '../../app/theme/app_tokens.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/explore/presentation/bloc/explore_cubit.dart';
import '../../features/explore/presentation/widgets/discovery_sections.dart';
import 'package:nexo_social/core/widgets/create_sheet_widget.dart';
import '../animations/app_motion.dart';
import '../widgets/nexo_icon.dart';
import '../widgets/nexo_logo.dart';
import '../widgets/section_header.dart';
import 'breakpoints.dart';
import 'shell_destinations.dart';

/// The persistent frame around every signed-in surface.
///
/// It wraps a [StatefulNavigationShell], so each tab keeps its own navigator
/// and its own scroll position. The previous shell used a plain `ShellRoute`
/// plus `context.go`, which rebuilt the whole subtree on every tab change:
/// opening a live room and returning to Inicio put the feed back at the top,
/// and there was no per-tab back stack at all.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    this.unreadActivity = 0,
  });

  final StatefulNavigationShell navigationShell;

  /// Notificaciones sin leer. Con 0 la campana va sola; con más, lleva el
  /// contador. Lo calcula quien construye el shell: el shell sólo lo dibuja.
  final int unreadActivity;

  /// Switches branch, and taps on the branch you are already in pop that
  /// branch back to its root — the standard tab-bar gesture, and the only way
  /// out of a deep stack without hunting for the back button.
  void _select(int branch) {
    _currentBranchNavigator.currentState?.popUntil(
      (route) => route is! PopupRoute,
    );
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  GlobalKey<NavigatorState> get _currentBranchNavigator =>
      navigationShell.route.branches[navigationShell.currentIndex].navigatorKey;

  Future<void> _openCreate(BuildContext context) async {
    final branchContext = _currentBranchNavigator.currentContext;
    if (branchContext == null) return;
    final option = await showCreateSheet(branchContext);
    if (option == null || !context.mounted) return;
    switch (option) {
      case CreateOption.post:
        unawaited(context.push(AppRoutes.create));
      case CreateOption.goLive:
        final auth = context.read<AuthCubit>().state;
        final isVisitor =
            auth is AuthAuthenticated && auth.user.role == UserRole.visitor;
        if (isVisitor) {
          unawaited(context.push(AppRoutes.studio));
        } else {
          context.go(AppRoutes.studio);
        }
      case CreateOption.scheduleShow:
        unawaited(context.push(AppRoutes.scheduleShow));
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = AppBreakpoints.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Row(
          children: [
            if (form.hasRail)
              _ShellRail(
                form: form,
                currentBranch: navigationShell.currentIndex,
                unreadActivity: unreadActivity,
                onSelected: _select,
                onCompose: () => unawaited(_openCreate(context)),
              ),
            Expanded(child: SafeArea(bottom: false, child: navigationShell)),
            if (form.isExpanded) const _SidePanel(),
          ],
        ),
        bottomNavigationBar: form.isCompact
            ? _ShellBottomBar(
                currentBranch: navigationShell.currentIndex,
                unreadActivity: unreadActivity,
                onSelected: _select,
                onCompose: () => unawaited(_openCreate(context)),
              )
            : null,
      ),
    );
  }
}

class _ShellBottomBar extends StatelessWidget {
  const _ShellBottomBar({
    required this.currentBranch,
    required this.unreadActivity,
    required this.onSelected,
    required this.onCompose,
  });

  final int currentBranch;
  final int unreadActivity;
  final ValueChanged<int> onSelected;
  final VoidCallback onCompose;

  /// Dónde cae el botón de componer entre los destinos. Componer es una
  /// acción, no una pestaña: empuja una ruta a pantalla completa sobre el
  /// shell en vez de tener branch propio, así que no hay estado que preservar
  /// y al volver el usuario queda en la pestaña de la que salió.
  static const _composeSlot = 2;

  @override
  Widget build(BuildContext context) {
    final destinations = ShellDestinations.compact;
    // La barra es una tira del mismo liner, separada por un filete: sobre un
    // fondo negro una sombra no se ve, y un color distinto la despegaría del
    // contenido que pasa por debajo.
    return Material(
      color: AppColors.background,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
            child: SizedBox(
              height: 62,
              child: Row(
                children: [
                  for (var slot = 0; slot < destinations.length + 1; slot++)
                    Expanded(
                      child: slot == _composeSlot
                          ? _ComposeButton(onPressed: onCompose)
                          : _BottomBarItem(
                              destination:
                                  destinations[slot < _composeSlot
                                      ? slot
                                      : slot - 1],
                              currentBranch: currentBranch,
                              unreadActivity: unreadActivity,
                              onSelected: onSelected,
                            ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.destination,
    required this.currentBranch,
    required this.unreadActivity,
    required this.onSelected,
  });

  final ShellDestination destination;
  final int currentBranch;
  final int unreadActivity;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = destination.branch == currentBranch;
    final color = selected ? AppColors.textPrimary : AppColors.textSecondary;
    final unread = destination.path == AppRoutes.activity ? unreadActivity : 0;
    return Semantics(
      selected: selected,
      button: true,
      label: unread > 0
          ? '${destination.label}, $unread sin leer'
          : destination.label,
      child: InkWell(
        key: Key('tab-${destination.path}'),
        onTap: () => onSelected(destination.branch),
        borderRadius: AppRadii.medium,
        splashFactory: NoSplash.splashFactory,
        highlightColor: AppColors.textPrimary.withValues(alpha: .04),
        excludeFromSemantics: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _WithCount(
              count: unread,
              child: AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.feedbackDuration,
                curve: Curves.easeOutBack,
                child: NexoIcon(
                  destination.glyph,
                  filled: selected,
                  size: 26,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// El contador sobre un ícono: un sticker rojo con su troquel del color del
/// liner, para que se despegue del ícono que tapa.
class _WithCount extends StatelessWidget {
  const _WithCount({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -5,
          right: -9,
          child: Container(
            key: const Key('tab-unread-count'),
            constraints: const BoxConstraints(minWidth: 19),
            height: 19,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: AppRadii.pill,
              border: Border.all(color: AppColors.background, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              count > 9 ? '9+' : '$count',
              style: const TextStyle(
                color: AppColors.sticker,
                fontSize: 9.5,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// La acción principal, como un sticker blanco: se hunde al presionarlo, como
/// cuando se aprieta un sticker contra la plancha.
class _ComposeButton extends StatefulWidget {
  const _ComposeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ComposeButton> createState() => _ComposeButtonState();
}

class _ComposeButtonState extends State<_ComposeButton> {
  bool _down = false;

  void _press(bool down) {
    if (_down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Tooltip(
      message: 'Crear publicación',
      child: Semantics(
        button: true,
        label: 'Crear publicación',
        child: GestureDetector(
          onTapDown: (_) => _press(true),
          onTapCancel: () => _press(false),
          onTapUp: (_) => _press(false),
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          child: AnimatedScale(
            scale: _down ? .9 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: 52,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.sticker,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.brandShadow,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const NexoIcon(
                NexoGlyph.add,
                color: AppColors.ink,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _ShellRail extends StatelessWidget {
  const _ShellRail({
    required this.form,
    required this.currentBranch,
    required this.unreadActivity,
    required this.onSelected,
    required this.onCompose,
  });

  final FormFactor form;
  final int currentBranch;
  final int unreadActivity;
  final ValueChanged<int> onSelected;

  /// La misma hoja que el + de la barra inferior. El rail empujaba el
  /// compositor directo, así que en tablet y escritorio no había forma de
  /// programar un show ni de ir a transmitir.
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    final extended = form.isExpanded;
    // Creator surfaces need the width, so they only join the rail once the
    // layout is expanded. On a tablet the phone set is what fits.
    final auth = context.watch<AuthCubit>().state;
    final destinations = extended
        ? ShellDestinations.expandedFor(
            auth is AuthAuthenticated ? auth.user : null,
          )
        : ShellDestinations.compact;
    // The rail's selected index is a position in the list it was given, which
    // is not the branch index once desktop-only entries are filtered out.
    final selectedIndex = destinations.indexWhere(
      (destination) => destination.branch == currentBranch,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: NavigationRail(
        extended: extended,
        labelType: extended ? null : NavigationRailLabelType.all,
        backgroundColor: AppColors.background,
        // A branch with no rail entry (a pushed detail, or Studio on tablet)
        // leaves nothing selected. NavigationRail rejects a negative index, so
        // it gets null — no highlight, rather than a wrong one. The old shell
        // clamped -1 to 0 and lit up "Inicio" while the user was elsewhere.
        selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
        onDestinationSelected: (index) =>
            onSelected(destinations[index].branch),
        leading: _RailLeading(extended: extended, onCompose: onCompose),
        destinations: [
          for (final destination in destinations)
            NavigationRailDestination(
              icon: _WithCount(
                count: destination.path == AppRoutes.activity
                    ? unreadActivity
                    : 0,
                child: NexoIcon(destination.glyph),
              ),
              selectedIcon: NexoIcon(destination.glyph, filled: true),
              label: Text(destination.label),
            ),
        ],
      ),
    );
  }
}

class _RailLeading extends StatelessWidget {
  const _RailLeading({required this.extended, required this.onCompose});

  final bool extended;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Column(
      children: [
        if (extended)
          const NexoWordmark(markSize: 40)
        else
          const NexoLogo(size: 44),
        const SizedBox(height: AppSpacing.lg),
        if (extended)
          SizedBox(
            width: 168,
            child: FilledButton.icon(
              key: const Key('rail-create'),
              onPressed: onCompose,
              icon: const NexoIcon(NexoGlyph.add, size: 18),
              label: const Text('Crear'),
            ),
          )
        else
          IconButton.filled(
            key: const Key('rail-create'),
            tooltip: 'Crear',
            onPressed: onCompose,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.sticker,
              foregroundColor: AppColors.ink,
            ),
            icon: const NexoIcon(NexoGlyph.add, size: 20),
          ),
      ],
    ),
  );
}

/// The right-hand column on wide viewports.
class _SidePanel extends StatelessWidget {
  const _SidePanel();

  @override
  Widget build(BuildContext context) => Container(
    // 320 con margen de 16: con 300 y margen de 24 la fila de creadores
    // —avatar, nombre y botón de seguir— se queda sin ancho y desborda.
    width: 320,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    decoration: const BoxDecoration(
      color: AppColors.background,
      border: Border(left: BorderSide(color: AppColors.border)),
    ),
    // Reusa las mismas secciones que Explorar y el feed vacío, con su propio
    // cubit. Tres copias del mismo bloque se separan, y el panel es donde
    // menos se mira: sería el último en enterarse.
    child: BlocProvider(
      create: (_) => ExploreCubit(sl(), sl())..load(),
      child: BlocBuilder<ExploreCubit, ExploreState>(
        builder: (context, state) {
          final cubit = context.read<ExploreCubit>();
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TrendingTopicsSection(
                  topics: state.topics,
                  onToggle: cubit.toggleTopic,
                  title: 'Tendencias',
                ),
                SuggestedCreatorsSection(
                  creators: state.creators,
                  onToggle: cubit.toggleCreator,
                  title: 'A quién seguir',
                ),
                const SectionHeader(title: 'Herramientas'),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.premium),
                  icon: const NexoIcon(NexoGlyph.crown, size: 18),
                  label: const Text('Membresías'),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.settings),
                  icon: const NexoIcon(NexoGlyph.settings, size: 18),
                  label: const Text('Ajustes'),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    ),
  );
}
