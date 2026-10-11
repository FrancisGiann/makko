import 'dart:async';

import 'package:flutter/material.dart';

class RefreshErrorBanner extends StatelessWidget {
  final String message;
  final Future<void> Function()? onRetry;

  const RefreshErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: () => unawaited(onRetry!()),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
