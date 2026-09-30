import 'package:flutter/material.dart';

import '../../../../../../../app/theme/app_tokens.dart';

class ShowSection extends StatelessWidget {
  const ShowSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryDeep),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      child,
    ],
  );
}

class ShowCard extends StatelessWidget {
  const ShowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.medium,
      border: Border.all(color: AppColors.border),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class ShowFieldLabel extends StatelessWidget {
  const ShowFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: .6,
      color: AppColors.textSecondary,
    ),
  );
}

class ShowHintPill extends StatelessWidget {
  const ShowHintPill({
    super.key,
    required this.label,
    this.icon,
    this.tinted = false,
  });

  final String label;
  final IconData? icon;

  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final foreground = tinted
        ? AppColors.textOnBrandSurface
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: tinted ? AppColors.primarySurface : AppColors.background,
        borderRadius: AppRadii.pill,
        border: tinted ? null : Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
