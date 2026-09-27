import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_tokens.dart';
import 'breakpoints.dart';

class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.child,
    required this.location,
  });
  final Widget child;
  final String location;
  static const _items = [
    (Icons.home_outlined, 'Inicio', '/'),
    (Icons.add_box_outlined, 'Crear', '/create'),
    (Icons.sensors_outlined, 'En vivo', '/live'),
    (Icons.notifications_none, 'Actividad', '/activity'),
    (Icons.person_outline, 'Perfil', '/profile/nexo'),
  ];
  int get _selected => _items
      .indexWhere(
        (item) =>
            location == item.$3 ||
            (item.$3 != '/' && location.startsWith(item.$3)),
      )
      .clamp(0, _items.length - 1);
  @override
  Widget build(BuildContext context) {
    final desktop = AppBreakpoints.isDesktop(context);
    final tablet = AppBreakpoints.isTablet(context);
    return Scaffold(
      body: Row(
        children: [
          if (tablet)
            NavigationRail(
              selectedIndex: _selected,
              extended: desktop,
              labelType: desktop ? null : NavigationRailLabelType.all,
              onDestinationSelected: (index) => context.go(_items[index].$3),
              destinations: _items
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.$1),
                      label: Text(item.$2),
                    ),
                  )
                  .toList(),
            ),
          Expanded(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Padding(
                    // On phones screens own their horizontal rhythm. This keeps
                    // profile covers, media and full-bleed states truly edge-to-edge.
                    padding: EdgeInsets.all(desktop ? AppSpacing.xl : 0),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
          if (desktop) const _ContextPanel(),
        ],
      ),
      bottomNavigationBar: tablet
          ? null
          : _MobileNavigation(
              selectedIndex: _selected,
              onSelected: (index) => context.go(_items[index].$3),
            ),
    );
  }
}

class _MobileNavigation extends StatelessWidget {
  const _MobileNavigation({required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      height: 68,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: List.generate(ResponsiveScaffold._items.length, (index) {
          final item = ResponsiveScaffold._items[index];
          final selected = selectedIndex == index;
          final isCreate = index == 1;
          return Expanded(
            child: InkResponse(
              onTap: () => onSelected(index),
              radius: 30,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCreate)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    )
                  else
                    Icon(
                      item.$1,
                      size: 23,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  const SizedBox(height: 3),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    ),
  );
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel();
  @override
  Widget build(BuildContext context) => Container(
    width: 260,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: AppColors.border)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nexo Social', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Espacio para contexto, tendencias y herramientas de creador.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
