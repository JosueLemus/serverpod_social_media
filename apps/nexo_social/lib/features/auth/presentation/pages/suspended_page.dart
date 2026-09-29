import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
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
    final banned = suspended?.status == AccountStatus.banned;
    final reason = suspended?.reason;

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
                  const Enter(
                    child: Icon(
                      Icons.gpp_bad_outlined,
                      size: 64,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Enter(
                    index: 1,
                    child: Text(
                      banned
                          ? 'Tu cuenta fue dada de baja'
                          : 'Tu cuenta está suspendida',
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
                        banned
                            ? 'La decisión es permanente.'
                            : 'Mientras dure la suspensión no puedes iniciar '
                                  'sesión, publicar ni comentar.',
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
