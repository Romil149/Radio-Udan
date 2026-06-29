import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';

/// Centered empty / error placeholder with optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BrandTokens.screenPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Icon(
                icon,
                size: 56,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: message,
              liveRegion: true,
              child: ExcludeSemantics(
                child: Text(                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              Semantics(
                button: true,
                label: actionLabel,
                child: ExcludeSemantics(
                  child: FilledButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
