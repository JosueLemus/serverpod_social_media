import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/injection.dart';
import '../../app/router/app_routes.dart';
import '../../app/theme/app_tokens.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import '../../features/explore/presentation/bloc/explore_cubit.dart';
import '../../features/explore/presentation/widgets/discovery_sections.dart';
import 'package:nexo_social/core/widgets/create_sheet_widget.dart';
import '../animations/app_motion.dart';
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
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Switches branch, and taps on the branch you are already in pop that
  /// branch back to its root — the standard tab-bar gesture, and the only way
  /// out of a deep stack without hunting for the back button.
  ///
  /// Cierra antes cualquier hoja abierta en el branch actual: la barra queda
  /// tocable debajo del menú de crear, y sin esto la hoja se quedaría
  /// escondida en el branch de origen y reaparecería al volver.
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

  /// Abre el menú de crear en el Navigator del branch activo, no en el raíz.
  ///
  /// El botón vive en el `bottomNavigationBar`, así que su Navigator más
  /// cercano es el raíz y una hoja abierta desde ahí tapa el shell entero.
  /// El del branch está dentro del `body`: la hoja y su velo terminan justo
  /// encima de la barra.
  void _openCreate() {
    final branchContext = _currentBranchNavigator.currentContext;
    if (branchContext == null) return;
    // Fase 1: sólo la hoja. A dónde lleva cada opción se cablea en la fase 2;
    // por ahora la elección se descarta.
    unawaited(showCreateSheet(branchContext));
  }

  @override
  Widget build(BuildContext context) {
    final form = AppBreakpoints.of(context);
    return Scaffold(
      body: Row(
        children: [
          if (form.hasRail)
            _ShellRail(
              form: form,
              currentBranch: navigationShell.currentIndex,
              onSelected: _select,
            ),
          Expanded(child: SafeArea(bottom: false, child: navigationShell)),
          if (form.isExpanded) const _SidePanel(),
        ],
      ),
      bottomNavigationBar: form.isCompact
          ? _ShellBottomBar(
              currentBranch: navigationShell.currentIndex,
              onSelected: _select,
              onCompose: _openCreate,
            )
          : null,
    );
  }
}

class _ShellBottomBar extends StatelessWidget {
  const _ShellBottomBar({
    required this.currentBranch,
    required this.onSelected,
    required this.onCompose,
  });

  final int currentBranch;
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
    // The material includes the home-indicator inset and owns all tap ink.
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.shadow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: SizedBox(
            height: 64,
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
                            onSelected: onSelected,
                          ),
                  ),
              ],
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
    required this.onSelected,
  });

  final ShellDestination destination;
  final int currentBranch;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = destination.branch == currentBranch;
    final color = selected ? AppColors.primaryDeep : AppColors.textSecondary;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: () => onSelected(destination.branch),
        borderRadius: AppRadii.medium,
        splashFactory: NoSplash.splashFactory,
        highlightColor: AppColors.primary.withValues(alpha: 0.06),
        excludeFromSemantics: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppMotion.feedbackDuration,
              curve: Curves.easeOutCubic,
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primarySurface
                    : AppColors.primarySurface.withValues(alpha: 0),
                borderRadius: AppRadii.pill,
              ),
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 23,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              destination.label,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontSize: 11,
                height: 1.2,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primary action, with feedback clipped to its own rounded surface.
class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Tooltip(
      message: 'Crear publicación',
      child: SizedBox.square(
        dimension: 50,
        child: Material(
          color: AppColors.primaryDeep,
          elevation: 3,
          shadowColor: AppColors.brandShadow,
          borderRadius: AppRadii.pill,
          clipBehavior: Clip.antiAlias,
          child: Semantics(
            button: true,
            label: 'Crear publicación',
            child: InkWell(
              onTap: onPressed,
              excludeFromSemantics: true,
              splashFactory: NoSplash.splashFactory,
              highlightColor: Colors.white.withValues(alpha: 0.16),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 27,
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
    required this.onSelected,
  });

  final FormFactor form;
  final int currentBranch;
  final ValueChanged<int> onSelected;

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

    return NavigationRail(
      extended: extended,
      labelType: extended ? null : NavigationRailLabelType.all,
      backgroundColor: AppColors.surface,
      // A branch with no rail entry (a pushed detail, or Studio on tablet)
      // leaves nothing selected. NavigationRail rejects a negative index, so
      // it gets null — no highlight, rather than a wrong one. The old shell
      // clamped -1 to 0 and lit up "Inicio" while the user was elsewhere.
      selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
      onDestinationSelected: (index) => onSelected(destinations[index].branch),
      leading: _RailLeading(extended: extended),
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}

class _RailLeading extends StatelessWidget {
  const _RailLeading({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Column(
      children: [
        const NexoLogo(size: 40, showBadge: false),
        const SizedBox(height: AppSpacing.md),
        if (extended)
          SizedBox(
            width: 168,
            child: FilledButton.icon(
              onPressed: () => context.push(AppRoutes.create),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear'),
            ),
          )
        else
          IconButton.filled(
            tooltip: 'Crear',
            onPressed: () => context.push(AppRoutes.create),
            icon: const Icon(Icons.add_rounded),
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
      color: AppColors.surface,
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
                const SectionHeader(
                  title: 'Herramientas',
                  icon: Icons.tune_rounded,
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.premium),
                  icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                  label: const Text('Membresías'),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutes.settings),
                  icon: const Icon(Icons.settings_outlined, size: 18),
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
