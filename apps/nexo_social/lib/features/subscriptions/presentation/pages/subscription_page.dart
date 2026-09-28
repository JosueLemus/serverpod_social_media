import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/section_header.dart';
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
                icon: const Icon(Icons.close_rounded),
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
                      const Enter(child: _CreatorHeader()),
                      const SizedBox(height: AppSpacing.md),
                      Enter(index: 1, child: _LockedPreview(unlocked: active)),
                      const SizedBox(height: AppSpacing.md),
                      Enter(index: 2, child: _PlanCard(active: active)),
                      const _DonationSection(),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              // Dicho con todas las letras. Una demo de pagos
                              // que parece un cobro real es lo único que un
                              // mock de pagos no puede hacer.
                              'Pago simulado para la demo. No se cobra nada.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _CreatorHeader extends StatelessWidget {
  const _CreatorHeader();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          const UserAvatar(name: 'Elena Vega', size: 44),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Elena Vega',
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                Text(
                  '@elena_ux · 42.8k miembros activos',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const StatusBadge(
            label: 'Top 1%',
            color: AppColors.primarySurface,
            foreground: AppColors.textOnBrandSurface,
            icon: Icons.trending_up_rounded,
          ),
        ],
      ),
    ),
  );
}

/// El contenido que la membresía abre.
///
/// Se muestra bloqueado, no escondido: esconderlo no vende nada, y mostrarlo
/// entero regalaría justo lo que el pase cobra.
class _LockedPreview extends StatelessWidget {
  const _LockedPreview({required this.unlocked});

  final bool unlocked;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: AppRadii.medium,
        child: AspectRatio(
          aspectRatio: 16 / 8,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDeep, AppColors.stageDark],
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      unlocked
                          ? 'DESBLOQUEADO · VER AHORA'
                          : 'CONTENIDO EXCLUSIVO PARA MIEMBROS',
                      key: const Key('premium-content-state'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              'Taller de 45 min · Figma + Flutter Code',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Guía completa de monetización y diseño de micro-interacciones',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17),
      ),
      const SizedBox(height: AppSpacing.xxs),
      Text(
        'Aprende a estructurar tokens de diseño para producción, conectarlos '
        'con Flutter y cobrar por el sistema, no por la pantalla.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
    ],
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.active});

  final bool active;

  static const _perks = [
    'Acceso a todos los directos grabados y transmisiones exclusivas',
    'Descarga de archivos fuente (UI kits y snippets de código)',
    'Acceso al chat privado y Q&A prioritario semanal',
    'Insignia dorada de suscriptor en comentarios y directos',
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: AppRadii.medium,
      border: Border.all(color: AppColors.primarySurfaceDeep),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StatusBadge(
          label: 'Plan recomendado',
          color: AppColors.primaryDeep,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pase Nexo Creador Pro',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '\$4.99',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.textOnBrandSurface,
              ),
            ),
            const SizedBox(width: 5),
            Text('USD / mes', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 14,
              color: AppColors.tertiary,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                'Cancela sin compromiso cuando quieras',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final perk in _perks)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 15,
                  color: AppColors.tertiary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    perk,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
        // Sólo opacidad: es el botón por el que existe la pantalla, así que
        // tiene que ser tocable en el frame en que aparece.
        EnterStatic(
          index: 3,
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('subscribe-button'),
              onPressed: active
                  ? null
                  : context.read<SubscriptionCubit>().subscribe,
              iconAlignment: IconAlignment.end,
              icon: Icon(
                active ? Icons.check_rounded : Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: Text(active ? 'Membresía activa' : 'Suscribirme ahora'),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 13,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Procesado de forma segura mediante Stripe & Apple Pay',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
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
              const SectionHeader(
                title: 'Apoyo y donación rápida',
                hint: 'Nexo Tip Directo',
                icon: Icons.volunteer_activism_outlined,
              ),
              Text(
                'Envía una propina directa para apoyar su contenido '
                'independiente y acelerar la publicación del próximo curso.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (final amount in SubscriptionCubit.donationAmounts) ...[
                    Expanded(
                      child: FilterPill(
                        key: Key('donate-$amount'),
                        label: '\$$amount USD',
                        selected: state.selectedDonation == amount,
                        onTap: () => cubit.selectDonation(amount),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('donate-send'),
                  onPressed: () {
                    cubit.donate();
                    _message.clear();
                  },
                  icon: const Icon(Icons.favorite_rounded, size: 17),
                  label: Text(
                    'Enviar donación de \$${state.selectedDonation} USD',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
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
