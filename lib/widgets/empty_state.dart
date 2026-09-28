import 'package:flutter/material.dart';

import '../theme.dart';

/// Centred icon bubble with a short message, used by empty tabs.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, this.message});

  final IconData icon;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: colors.surfaceRaised,
              child: Icon(icon, size: 28, color: colors.accent),
            ),
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: VavakaText.footnote.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
