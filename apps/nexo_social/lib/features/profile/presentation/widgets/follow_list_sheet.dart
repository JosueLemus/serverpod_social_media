import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/follow.dart';
import '../bloc/follow_cubit.dart';
import '../bloc/follow_list_cubit.dart';
import '../utils/profile_notice_ui.dart';

/// Seguidores o seguidos de [userId], en una hoja. Tocar una cuenta abre su
/// perfil encima del shell, igual que desde el feed.
Future<void> showFollowListSheet(
  BuildContext context, {
  required String userId,
  required FollowListKind kind,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => BlocProvider(
    create: (_) => sl<FollowListCubit>(param1: userId, param2: kind)..load(),
    child: _FollowListSheet(kind: kind),
  ),
);

extension FollowListKindUI on FollowListKind {
  String get title => switch (this) {
    FollowListKind.followers => 'Seguidores',
    FollowListKind.following => 'Siguiendo',
  };

  String get emptyMessage => switch (this) {
    FollowListKind.followers => 'Todavía nadie sigue esta cuenta.',
    FollowListKind.following => 'Esta cuenta todavía no sigue a nadie.',
  };
}

class _FollowListSheet extends StatelessWidget {
  const _FollowListSheet({required this.kind});

  final FollowListKind kind;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              kind.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: BlocBuilder<FollowListCubit, FollowListState>(
              builder: (context, state) => switch (state) {
                FollowListLoading() => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                FollowListFailure(:final offline) => SingleChildScrollView(
                  child: AppErrorView(
                    isOffline: offline,
                    onRetry: () =>
                        unawaited(context.read<FollowListCubit>().load()),
                  ),
                ),
                FollowListLoaded(:final items) when items.isEmpty => _EmptyList(
                  kind: kind,
                ),
                FollowListLoaded() => _List(state: state),
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Una lista vacía también lleva al gato.
class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.kind});

  final FollowListKind kind;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.xs,
      AppSpacing.md,
      AppSpacing.lg,
    ),
    child: Center(
      child: Column(
        children: [
          const MascotIllustration(NexoMascot.peek, size: 112),
          const SizedBox(height: AppSpacing.sm),
          Text(
            kind.emptyMessage,
            key: const Key('follow-list-empty'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    ),
  );
}

class _List extends StatelessWidget {
  const _List({required this.state});

  final FollowListLoaded state;

  @override
  Widget build(BuildContext context) {
    // Seguir es de una cuenta: un visitante mira la lista pero no sigue, y
    // nadie se sigue a sí mismo.
    final auth = context.watch<AuthCubit>().state;
    final viewer =
        auth is AuthAuthenticated && auth.user.role != UserRole.visitor
        ? auth.user.username
        : null;
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return Center(
            child: state.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: CircularProgressIndicator(),
                  )
                : TextButton(
                    onPressed: () =>
                        unawaited(context.read<FollowListCubit>().loadMore()),
                    child: const Text('Ver más'),
                  ),
          );
        }
        final account = state.items[index];
        return ListTile(
          key: Key('follow-list-${account.username}'),
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          minVerticalPadding: AppSpacing.xs,
          leading: UserAvatar(
            name: account.name,
            imageUrl: account.avatarUrl,
            size: 44,
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (account.isVerified) ...[
                const SizedBox(width: AppSpacing.xxs),
                const NexoIcon(
                  NexoGlyph.verified,
                  size: 15,
                  color: AppColors.primary,
                  semanticLabel: 'Cuenta verificada',
                ),
              ],
            ],
          ),
          subtitle: Text(
            '@${account.username}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: viewer == null || viewer == account.username
              ? null
              : _FollowButton(username: account.username),
          // El router se toma antes de cerrar la hoja: después del pop este
          // context ya no está montado.
          onTap: () {
            final router = GoRouter.of(context);
            Navigator.of(context).pop();
            unawaited(router.push(AppRoutes.profileOf(account.username)));
          },
        );
      },
    );
  }
}

/// Seguir a una cuenta desde la lista, con el mismo cubit que el botón de la
/// sala en vivo: optimista y con vuelta atrás si el servidor lo rechaza.
///
/// El cubit lee el perfil antes de ofrecer el botón (un "Seguir" que después
/// resulta "Siguiendo" se lee como un tap que no anduvo). La lista sólo
/// construye las filas visibles, así que son las lecturas de lo que se ve.
class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.username});

  final String username;

  /// Ancho fijo: "Seguir" y "Siguiendo" ocupan lo mismo, y la fila no salta
  /// cuando el botón aparece o cambia.
  static const _width = 112.0;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<FollowCubit>(param1: username)..load(),
    child: BlocConsumer<FollowCubit, FollowButtonState>(
      listenWhen: (previous, current) =>
          current.notice != null &&
          previous.noticeSerial != current.noticeSerial,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.notice!.message))),
      builder: (context, state) {
        if (!state.isReady) return const SizedBox(width: _width);
        void toggle() => unawaited(context.read<FollowCubit>().toggle());
        const size = Size(_width, AppSizes.buttonHeightDense);
        const padding = EdgeInsets.symmetric(horizontal: AppSpacing.sm);
        return state.following
            ? OutlinedButton(
                key: Key('follow-list-follow-$username'),
                onPressed: toggle,
                style: OutlinedButton.styleFrom(
                  minimumSize: size,
                  maximumSize: size,
                  padding: padding,
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Siguiendo', maxLines: 1),
                ),
              )
            : FilledButton(
                key: Key('follow-list-follow-$username'),
                onPressed: toggle,
                style: FilledButton.styleFrom(
                  minimumSize: size,
                  maximumSize: size,
                  padding: padding,
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Seguir', maxLines: 1),
                ),
              );
      },
    ),
  );
}
