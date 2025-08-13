import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? lottieAsset;
  final IconData? icon;
  final VoidCallback? onActionPressed;
  final String? actionLabel;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.lottieAsset,
    this.icon,
    this.onActionPressed,
    this.actionLabel,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lottieAsset != null) ...[
              SizedBox(
                height: 200,
                child: Lottie.asset(
                  lottieAsset!,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      icon ?? Icons.inbox_rounded,
                      size: 80,
                      color: iconColor ?? theme.colorScheme.primary.withValues(alpha: 0.3),
                    );
                  },
                ),
              ),
            ] else ...[
              Icon(
                icon ?? Icons.inbox_rounded,
                size: 80,
                color: iconColor ?? theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}