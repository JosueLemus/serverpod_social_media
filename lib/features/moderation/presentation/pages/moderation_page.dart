import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../domain/entities/moderation_action.dart';
import '../bloc/moderation_cubit.dart';

class ModerationPage extends StatelessWidget {
  const ModerationPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ModerationCubit>()..load(),
    child: BlocBuilder<ModerationCubit, ModerationState>(
      builder: (context, state) {
        final actions = state is ModerationLoaded
            ? state.actions
            : const <ModerationAction>[];
        return ListView(
          children: [
            Text('Moderación', style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: ListTile(
                title: const Text('Comentario reportado'),
                subtitle: const Text('“Esto no aporta a la conversación”'),
                trailing: Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    TextButton(
                      onPressed: () => context.read<ModerationCubit>().act(
                        ModerationType.hideComment,
                        'comentario-demo',
                      ),
                      child: const Text('Ocultar'),
                    ),
                    TextButton(
                      onPressed: () => context.read<ModerationCubit>().act(
                        ModerationType.muteUser,
                        '@usuario-demo',
                      ),
                      child: const Text('Silenciar'),
                    ),
                  ],
                ),
              ),
            ),
            Text('Audit trail', style: Theme.of(context).textTheme.titleLarge),
            if (actions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('No hay acciones registradas todavía.'),
              ),
            ...actions.map(
              (action) => ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text('${action.type.name}: ${action.target}'),
                subtitle: Text('${action.actor} · ${action.reason}'),
              ),
            ),
          ],
        );
      },
    ),
  );
}
