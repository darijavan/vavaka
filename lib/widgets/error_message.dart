import 'package:flutter/material.dart';

import '../copy.dart';

class ErrorMessage extends StatelessWidget {
  const ErrorMessage({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(Copy.loadFailed, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text(Copy.retry)),
            ],
          ],
        ),
      ),
    );
  }
}
