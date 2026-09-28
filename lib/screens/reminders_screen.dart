import 'package:flutter/material.dart';

import '../widgets/empty_state.dart';
import '../widgets/vavaka_app_bar.dart';

/// "Tsiahy" tab. The Figma file only defines the empty state so far.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: VavakaAppBar(),
      body: EmptyState(
        icon: Icons.notifications_none,
        message: 'Mametraha fampahatsiahivana mba hivavaka isan’andro.',
      ),
    );
  }
}
