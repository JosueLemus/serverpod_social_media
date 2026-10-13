import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/sticker.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../bloc/subscription_cubit.dart';

/// El muro de membresía de un creador. Ruta empujada, así que lleva Scaffold
/// propio y un botón de cerrar.
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key, this.creator = 'elena_ux'});

  final String creator;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SubscriptionCubit(sl(), creator)..load(),
    child: const _SubscriptionView(),
  );
}

class _SubscriptionView extends StatelessWidget {
  const _SubscriptionView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SubscriptionCubit, SubscriptionState>(
        builder: (context, state) {
          final active = state.entitlement.active;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: 'Cerrar',
                onPressed: context.pop,
                icon: const NexoIcon(NexoGlyph.close, size: 20),
              ),
              title: const Text('Premium'),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                    children: [
                      const Enter(child: _CreatorHero()),
                      const SizedBox(height: AppSpacing.lg),
                      Enter(index: 1, child: _LockedPreview(unlocked: active)),
                      const SizedBox(height: AppSpacing.lg),
                      Enter(index: 2, child: _PlanSection(active: active)),
                      const _DonationSection(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

/// El gato con la corona, en vez de un banner en degradado: la membresía es
/// lo que se colecciona, no un anuncio.
class _CreatorHero extends StatelessWidget {
  const _CreatorHero();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        const MascotIllustration(NexoMascot.crown, size: 140),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const UserAvatar(name: 'Elena Vega', size: 30),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                'Elena Vega',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.headlineMedium,
              ),
            ),
            const SizedBox(width: 6),
            NexoIcon(NexoGlyph.verified, size: 18, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '@elena_ux · 42.8k miembros activos',
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        StatusBadge(
          label: 'Top 1%',
          color: AppColors.vinylLime,
          foreground: AppColors.ink,
        ),
      ],
    );
  }
}

/// El contenido que la membresía abre.
///
/// Se muestra bloqueado, no escondido: esconderlo no vende nada, y mostrarlo
/// entero regalaría justo lo que el pase cobra.
class _LockedPreview extends StatelessWidget {
  const _LockedPreview({required this.unlocked});

  final bool unlocked;

  /// Cuánto asoma la insignia por encima del borde.
  static const _badgeOverhang = 10.0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: _badgeOverhang),
          child: StickerFrame(
            radius: 22,
            fill: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: unlocked
                              ? AppColors.tertiary
                              : AppColors.linerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: NexoIcon(
                          unlocked ? NexoGlyph.play : NexoGlyph.lock,
                          filled: true,
                          size: 20,
                          color: unlocked
                              ? AppColors.ink
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Guía completa de monetización y diseño de '
                          'micro-interacciones',
                          style: text.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      NexoIcon(
                        NexoGlyph.clock,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Taller de 45 min · Figma + Flutter Code',
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Aprende a estructurar tokens de diseño para producción, '
                    'conectarlos con Flutter y cobrar por el sistema, no por '
                    'la pantalla.',
                    style: text.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // El estado pegado en el borde, no como una línea encima del título.
        Positioned(
          top: 0,
          right: AppSpacing.md,
          child: StatusBadge(
            key: const Key('premium-content-state'),
            label: unlocked ? 'Desbloqueado' : 'Solo miembros',
            color: unlocked ? AppColors.tertiary : AppColors.vinylLime,
            foreground: AppColors.ink,
            tilt: .05,
          ),
        ),
      ],
    );
  }
}

class _PlanSection extends StatelessWidget {
  const _PlanSection({required this.active});

  final bool active;

  static const _perks = [
    'Acceso a todos los directos grabados y transmisiones exclusivas',
    'Descarga de archivos fuente (UI kits y snippets de código)',
    'Acceso al chat privado y Q&A prioritario semanal',
    'Insignia dorada de suscriptor en comentarios y directos',
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PlanTile(),
        const SizedBox(height: AppSpacing.md),
        for (final perk in _perks)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: NexoIcon(
                    NexoGlyph.star,
                    size: 16,
                    color: AppColors.vinylLime,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    perk,
                    style: text.bodyMedium?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        // Sólo opacidad: es el botón por el que existe la pantalla, así que
        // tiene que ser tocable en el frame en que aparece.
        EnterStatic(
          index: 3,
          child: FilledButton.icon(
            key: const Key('subscribe-button'),
            onPressed: active
                ? null
                : context.read<SubscriptionCubit>().subscribe,
            iconAlignment: IconAlignment.end,
            // Con la membresía activa el botón queda apagado, pero en verde
            // de confirmación: gris diría que algo falta.
            style: FilledButton.styleFrom(
              disabledBackgroundColor: AppColors.tertiary,
              disabledForegroundColor: AppColors.ink,
            ),
            icon: NexoIcon(
              active ? NexoGlyph.verified : NexoGlyph.forward,
              size: 18,
            ),
            label: Text(active ? 'Membresía activa' : 'Suscribirme ahora'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _SimulatedPaymentNotice(),
      ],
    );
  }
}

/// El plan, como sticker elegido: el corte del logo, con su marca de
/// selección en tinta. Hoy hay un solo plan, así que es el seleccionado.
class _PlanTile extends StatelessWidget {
  const _PlanTile();

  @override
  Widget build(BuildContext context) => Semantics(
    selected: true,
    container: true,
    child: const StickerCard(child: _PlanBody()),
  );
}

/// Aparte para leer el tema **dentro** de la [StickerCard], que lo invierte a
/// tinta.
class _PlanBody extends StatelessWidget {
  const _PlanBody();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pase Nexo Creador Pro', style: text.titleLarge),
              const SizedBox(height: AppSpacing.xxs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '\$4.99',
                    style: text.displaySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(child: Text('USD / mes', style: text.bodySmall)),
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Cancela sin compromiso cuando quieras',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // No hay glifo de "check" en el set de Nexo: el tilde de Material va
        // dentro de un disco de tinta.
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: NexoIcon(
            NexoGlyph.check,
            filled: true,
            size: 18,
            color: AppColors.sticker,
          ),
        ),
      ],
    );
  }
}

/// Dicho con todas las letras y junto al botón que cobra. Una demo de pagos
/// que parece un cobro real es lo único que un mock de pagos no puede hacer.
class _SimulatedPaymentNotice extends StatelessWidget {
  const _SimulatedPaymentNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.linerHigh,
      borderRadius: AppRadii.medium,
    ),
    child: Row(
      children: [
        StatusBadge(
          label: 'Demo',
          color: AppColors.warning,
          foreground: AppColors.ink,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Pago simulado para la demo. No se cobra nada.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    ),
  );
}

class _DonationSection extends StatefulWidget {
  const _DonationSection();

  @override
  State<_DonationSection> createState() => _DonationSectionState();
}

class _DonationSectionState extends State<_DonationSection> {
  final _message = TextEditingController();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SubscriptionCubit, SubscriptionState>(
        builder: (context, state) {
          final cubit = context.read<SubscriptionCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Apoyo y donación rápida'),
              Text(
                'Envía una propina directa para apoyar su contenido '
                'independiente y acelerar la publicación del próximo curso.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (final (index, amount)
                      in SubscriptionCubit.donationAmounts.indexed) ...[
                    if (index > 0) const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: FilterPill(
                        key: Key('donate-$amount'),
                        label: '\$$amount USD',
                        selected: state.selectedDonation == amount,
                        onTap: () => cubit.selectDonation(amount),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _message,
                maxLength: 140,
                decoration: const InputDecoration(
                  hintText: 'Escribe un mensaje de aliento (opcional)',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Contorno y no sticker blanco: la acción de esta pantalla es
              // suscribirse, y dos CTA blancos se pelean el mismo lugar.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('donate-send'),
                  onPressed: () {
                    cubit.donate();
                    _message.clear();
                  },
                  icon: NexoIcon(
                    NexoGlyph.heart,
                    filled: true,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                  label: Text(
                    'Enviar donación de \$${state.selectedDonation} USD',
                  ),
                ),
              ),
              if (state.lastDonation != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Has apoyado con \$${state.donationTotal} USD en esta sesión '
                  '(simulado).',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          );
        },
      );
}
