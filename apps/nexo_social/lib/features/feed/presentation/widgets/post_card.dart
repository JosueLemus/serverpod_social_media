import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../domain/entities/post.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onSave,
  });
  final Post post;
  final VoidCallback onLike;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) => Card(
    key: Key('post-${post.id}'),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(child: Text(post.name[0])),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: InkWell(
                  onTap: () => context.go('/profile/${post.author}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '@${post.author} · hace 25 min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              if (post.isLive)
                const Chip(
                  label: Text('EN VIVO'),
                  avatar: Icon(Icons.sensors, size: 16),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(post.body),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: post.tags
                .map((tag) => Chip(label: Text('#$tag')))
                .toList(),
          ),
          const Divider(),
          Row(
            children: [
              IconButton(
                key: Key('like-${post.id}'),
                onPressed: onLike,
                icon: Icon(
                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: post.isLiked ? AppColors.error : null,
                ),
              ),
              Text('${post.likes + (post.isLiked ? 1 : 0)}'),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.chat_bubble_outline, size: 20),
              Text(' ${post.comments}'),
              const Spacer(),
              IconButton(
                key: Key('save-${post.id}'),
                onPressed: onSave,
                icon: Icon(
                  post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
