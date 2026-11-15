import 'package:flutter/material.dart';

import '../theme.dart';

/// Upper-case overline used above lists, e.g. "5 VAVAKA".
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: VavakaText.overline.copyWith(
        color: VavakaColors.of(context).textSecondary,
      ),
    );
  }
}
