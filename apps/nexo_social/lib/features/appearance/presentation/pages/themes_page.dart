import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../app/theme/nexo_themes.dart';
import '../../../../core/widgets/section_header.dart';
import '../bloc/theme_cubit.dart';
import '../widgets/theme_preview_card.dart';

/// Perfil → Temas: el catálogo entero, oscuros y claros, cada uno dibujado con
/// sus propios colores. Tocar uno lo aplica a toda la app en el acto y queda
/// guardado en el dispositivo.
///
/// No hay botón de "aplicar": el cambio es inmediato y reversible con otro
/// toque, así que un paso de confirmación sólo agregaría fricción. El
/// [ThemeCubit] es el de la raíz (singleton), no uno de esta pantalla.
class ThemesPage extends StatelessWidget {
  const ThemesPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Temas')),
    body: BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final active = NexoThemes.byId(state.themeId);
        final dark = NexoThemes.all.where((t) => t.isDark).toList();
        final light = NexoThemes.all.where((t) => !t.isDark).toList();
        final width = MediaQuery.sizeOf(context).width;
        // En escritorio la grilla no se estira a la ventana: se centra.
        final side = math.max(AppSpacing.md, (width - 960) / 2);
        void select(NexoThemeSpec spec) =>
            context.read<ThemeCubit>().select(spec.id);

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(side, AppSpacing.xs, side, 0),
              sliver: SliverToBoxAdapter(child: _Intro(active: active)),
            ),
            ..._section('Oscuros', dark, active, side, select),
            ..._section('Claros', light, active, side, select),
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
              ),
            ),
          ],
        );
      },
    ),
  );

  List<Widget> _section(
    String title,
    List<NexoThemeSpec> themes,
    NexoThemeSpec active,
    double side,
    void Function(NexoThemeSpec) onSelect,
  ) => [
    SliverPadding(
      padding: EdgeInsets.fromLTRB(side, AppSpacing.lg, side, AppSpacing.sm),
      sliver: SliverToBoxAdapter(
        child: SectionHeader(title: title, hint: '${themes.length}'),
      ),
    ),
    SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: side),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 230,
          mainAxisExtent: ThemePreviewCard.extent,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
        ),
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final spec = themes[index];
          return ThemePreviewCard(
            key: Key('theme-${spec.id}'),
            spec: spec,
            selected: spec.id == active.id,
            onTap: () => onSelect(spec),
          );
        },
      ),
    ),
  ];
}

/// El tema en uso y qué pasa al tocar otro.
class _Intro extends StatelessWidget {
  const _Intro({required this.active});

  final NexoThemeSpec active;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: 'Estás usando ',
            children: [
              TextSpan(
                text: active.name,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          style: text.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Toca un tema para aplicarlo. El cambio es inmediato y queda '
          'guardado en este dispositivo.',
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
