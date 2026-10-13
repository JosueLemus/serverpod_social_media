import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../live/presentation/utils/live_navigation.dart';
import '../../../live/presentation/widgets/live_card.dart';
import '../../../profile/domain/entities/follow.dart';
import '../bloc/search_cubit.dart';

/// Lo que Explorar muestra mientras hay algo escrito en el buscador.
///
/// [onTag] reemplaza el texto del buscador por la etiqueta: es la View la que
/// es dueña del campo, no el cubit.
class SearchResultsView extends StatelessWidget {
  const SearchResultsView({
    super.key,
    required this.state,
    required this.onTag,
    required this.onClear,
  });

  final SearchState state;
  final ValueChanged<String> onTag;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final results = state.results;
    final cubit = context.read<SearchCubit>();

    if (state.status == SearchStatus.failed && results == null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: AppErrorView(onRetry: () => unawaited(cubit.retry())),
      );
    }
    if (results == null) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.md),
        child: FeedSkeleton(count: 2),
      );
    }
    if (results.isEmpty && state.status != SearchStatus.loading) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: AppEmptyView(
          key: const Key('search-empty'),
          mascot: NexoMascot.search,
          title: 'Sin resultados para “${results.query}”',
          message: 'Prueba con otro nombre, un tema o una etiqueta.',
          actionLabel: 'Borrar búsqueda',
          onAction: onClear,
        ),
      );
    }

    var index = 0;
    // Sólo aparecen: todo se toca, y una traslación correría el hit test.
    Widget enter(Widget child) => EnterStatic(index: index++, child: child);

    return Column(
      key: const Key('search-results'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.status == SearchStatus.loading)
          const LinearProgressIndicator(minHeight: 2),
        if (results.accounts.isNotEmpty) ...[
          const SectionHeader(title: 'Cuentas'),
          for (final account in results.accounts)
            enter(_AccountRow(account: account)),
        ],
        if (results.lives.isNotEmpty) ...[
          const SectionHeader(title: 'Vivos'),
          for (final session in results.lives)
            enter(
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: LiveCard(
                  session: session,
                  onTap: () => openLive(context, session),
                ),
              ),
            ),
        ],
        if (results.posts.isNotEmpty) ...[
          const SectionHeader(title: 'Publicaciones'),
          for (final post in results.posts) enter(_PostRow(post: post)),
        ],
        if (results.tags.isNotEmpty) ...[
          const SectionHeader(title: 'Etiquetas'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final tag in results.tags)
                FilterPill(
                  key: Key('search-tag-$tag'),
                  label: '#$tag',
                  selected: false,
                  onTap: () => onTag('#$tag'),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});

  final ProfileSummary account;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final auth = context.watch<AuthCubit>().state;
    // Seguir pide sesión, y nadie se sigue a sí mismo: el botón no se ofrece
    // en vez de ofrecer algo que el servidor rechaza.
    final canFollow =
        auth is AuthAuthenticated &&
        auth.user.role != UserRole.visitor &&
        auth.user.id != account.id;
    final followers = account.followerCount;
    return InkWell(
      key: Key('search-account-${account.username}'),
      borderRadius: AppRadii.medium,
      onTap: () =>
          unawaited(context.push(AppRoutes.profileOf(account.username))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            UserAvatar(
              name: account.name,
              imageUrl: account.avatarUrl,
              size: 44,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium,
                        ),
                      ),
                      if (account.isVerified) ...[
                        const SizedBox(width: 4),
                        const NexoIcon(
                          NexoGlyph.verified,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    followers == null
                        ? '@${account.username}'
                        : '@${account.username} · '
                              '$followers ${followers == 1 ? 'seguidor' : 'seguidores'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (canFollow) ...[
              const SizedBox(width: AppSpacing.xs),
              _FollowButton(account: account),
            ],
          ],
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.account});

  final ProfileSummary account;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    void toggle() => unawaited(cubit.toggleFollow(account));
    const size = Size(0, AppSizes.buttonHeightDense);
    return account.viewerFollows
        ? OutlinedButton(
            key: Key('search-follow-${account.username}'),
            onPressed: toggle,
            style: OutlinedButton.styleFrom(minimumSize: size),
            child: const Text('Siguiendo'),
          )
        : FilledButton(
            key: Key('search-follow-${account.username}'),
            onPressed: toggle,
            style: FilledButton.styleFrom(minimumSize: size),
            child: const Text('Seguir'),
          );
  }
}

class _PostRow extends StatelessWidget {
  const _PostRow({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      key: Key('search-post-${post.id}'),
      borderRadius: AppRadii.medium,
      onTap: () => unawaited(context.push(AppRoutes.post(post.id))),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              name: post.name,
              imageUrl: post.authorAvatarUrl,
              size: 36,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${post.name} · @${post.author}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    post.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
                  if (post.tags.isNotEmpty)
                    Text(
                      post.tags.map((tag) => '#$tag').join(' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: AppColors.primary),
                    ),
                ],
              ),
            ),
            if (post.mediaUrl != null) ...[
              const SizedBox(width: AppSpacing.sm),
              ClipRRect(
                borderRadius: AppRadii.small,
                child: Image.network(
                  post.mediaUrl!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  cacheWidth: 168,
                  errorBuilder: (_, _, _) =>
                      const SizedBox(width: 56, height: 56),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
