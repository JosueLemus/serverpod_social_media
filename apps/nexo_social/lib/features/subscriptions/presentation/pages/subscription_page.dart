import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/injection.dart';
import '../bloc/subscription_cubit.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SubscriptionCubit(sl(), 'elena_ux')..load(),
    child: BlocBuilder<SubscriptionCubit, SubscriptionState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Pase Creador VIP')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Acceso a directos privados, replays y recursos.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.entitlement.active
                  ? null
                  : context.read<SubscriptionCubit>().subscribe,
              child: Text(
                state.entitlement.active
                    ? 'Membresía activa'
                    : 'Suscribirme · 4.99 USD/mes',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              state.entitlement.active
                  ? 'Contenido premium desbloqueado: Plantilla de comunidad 2026'
                  : 'Contenido premium bloqueado',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            const Text('Apoyo directo'),
            Wrap(
              spacing: 8,
              children: [2, 5, 10]
                  .map(
                    (amount) => OutlinedButton(
                      onPressed: () =>
                          context.read<SubscriptionCubit>().donate(amount),
                      child: Text('$amount USD'),
                    ),
                  )
                  .toList(),
            ),
            if (state.donationTotal > 0)
              Text('Donación mock acumulada: ${state.donationTotal} USD'),
          ],
        ),
      ),
    ),
  );
}
