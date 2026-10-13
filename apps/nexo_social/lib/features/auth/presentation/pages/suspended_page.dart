import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../domain/entities/app_user.dart';
import '../bloc/auth_cubit.dart';

/// Donde queda una sesión revocada por una sanción.
///
/// Dice qué pasó y por qué. Mandar al login sin explicación se lee como un
/// fallo de la app, y lo primero que hace la persona es volver a intentar
/// entrar — con una cuenta que el servidor ya no acepta.
class SuspendedPage extends StatelessWidget {
  const SuspendedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;
    final suspended = state is AuthSuspended ? state : null;
    final status = suspended?.status;
    final reason = suspended?.reason;
    // Tres copys y no dos: si el servidor no dijo cuál sanción fue, decir
    // "suspendida" le promete un final a una cuenta que quizá no lo tiene.
    final (title, consequence) = switch (status) {
      AccountStatus.banned => (
        'Tu cuenta fue dada de baja',
        'La decisión es permanente.',
      ),
      AccountStatus.suspended => (
        'Tu cuenta está suspendida',
        'Mientras dure la suspensión no puedes iniciar sesión, publicar ni '
            'comentar.',
      ),
      AccountStatus.active || null => (
        'Tu cuenta no está activa',
        'Una sanción impide usar esta cuenta. Si crees que es un error, '
            'escríbenos.',
      ),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // El sticker "dado vuelta": el gato con el candado dice
                  // que la cuenta está cerrada sin pintar la pantalla de
                  // alarma, que haría pensar que la app se rompió.
                  const Enter(child: MascotIllustration(NexoMascot.lock)),
                  const SizedBox(height: AppSpacing.md),
                  Enter(
                    index: 1,
                    child: Text(
                      title,
                      key: const Key('suspended-title'),
                      style: Theme.of(context).textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Enter(
                    index: 2,
                    child: Text(
                      [
                        if (reason != null) 'Motivo: ${reason.label}.',
                        consequence,
                      ].join(' '),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  EnterStatic(
                    index: 3,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('suspended-ack'),
                        // Sin navegar a mano: el cambio de estado mueve al
                        // usuario, como al cerrar sesión.
                        onPressed: context
                            .read<AuthCubit>()
                            .acknowledgeSuspension,
                        child: const Text('Entendido'),
                      ),
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
