import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/constants/environment.dart';
import '../../../../core/mock/demo_accounts.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../bloc/auth_cubit.dart';

/// Entrar con una cuenta sembrada de un toque. **Sólo en modo mock**: con
/// `AUTH_SOURCE=serverpod` no se dibuja, porque en producción no hay cuentas de
/// demo y un atajo de login es exactamente lo que no tiene que existir.
class DemoAccountButton extends StatelessWidget {
  const DemoAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (Environment.authSourceMode != AuthSourceMode.mock) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: FilledButton.tonalIcon(
        key: const Key('demo-accounts'),
        onPressed: () => _showPicker(context),
        icon: const Icon(Icons.switch_account_outlined, size: 18),
        label: const Text('Elegir cuenta de demo (operador, moderador…)'),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    // Capturado mientras el context vive: la hoja lo sobrevive.
    final auth = context.read<AuthCubit>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cuentas de demo',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              Text(
                'Datos simulados. Cada cuenta tiene el rol que tendría en '
                'el backend.',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final account in DemoAccounts.all)
                ListTile(
                  key: Key('demo-${account.username}'),
                  contentPadding: EdgeInsets.zero,
                  leading: UserAvatar(name: account.name, size: 36),
                  title: Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    account.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    auth.signIn(account.email, 'demo');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
