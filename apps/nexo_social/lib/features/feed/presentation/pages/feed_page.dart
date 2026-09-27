import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../domain/entities/post.dart';
import '../bloc/feed_cubit.dart';
import '../widgets/post_card.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<FeedCubit>()..load(),
    child: const _FeedView(),
  );
}

class _FeedView extends StatelessWidget {
  const _FeedView();
  @override
  Widget build(BuildContext context) => BlocBuilder<FeedCubit, FeedState>(
    builder: (context, state) {
      if (state is FeedLoading) {
        return const FeedSkeleton();
      }
      if (state is FeedFailure) {
        return AppErrorView(onRetry: () => context.read<FeedCubit>().load());
      }
      if (state is FeedLoaded && state.posts.isEmpty) {
        return AppEmptyView(
          title: 'Tu feed está esperando por ti',
          message: 'Sigue creadores y temas para llenar este espacio.',
          actionLabel: 'Explorar creadores',
          onAction: () {},
        );
      }
      final List<Post> posts = state is FeedLoaded ? state.posts : const [];
      return ListView(
        children: [
          Text('Para ti', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.sm),
          const Wrap(
            spacing: AppSpacing.xs,
            children: [
              Chip(label: Text('Para ti')),
              Chip(label: Text('Siguiendo')),
              Chip(label: Text('En vivo')),
              Chip(label: Text('Comunidades')),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...posts.map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: PostCard(
                post: post,
                onLike: () => context.read<FeedCubit>().toggleLike(post.id),
                onSave: () => context.read<FeedCubit>().toggleSave(post.id),
              ),
            ),
          ),
        ],
      );
    },
  );
}
