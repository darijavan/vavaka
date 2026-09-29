import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import 'vavaka_tab_bar.dart';

/// Width from which the app switches to the iPad master–detail layout.
const splitViewBreakpoint = 720.0;
const _masterPaneWidth = 384.0;

/// The prayer shown in the detail pane. Only present in the split layout, so
/// its presence also tells widgets they are rendered inside the master pane.
class PrayerSelection extends InheritedNotifier<ValueNotifier<String?>> {
  const PrayerSelection({
    super.key,
    required ValueNotifier<String?> super.notifier,
    required super.child,
  });

  static ValueNotifier<String?>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PrayerSelection>()?.notifier;
}

bool isInMasterPane(BuildContext context) =>
    PrayerSelection.maybeOf(context) != null;

/// Opens a prayer in the detail pane when there is one, else in the reader.
void openPrayer(BuildContext context, String prayerId) {
  final selection = PrayerSelection.maybeOf(context);
  if (selection != null) {
    selection.value = prayerId;
  } else {
    context.push('/prayers/$prayerId');
  }
}

/// Tab shell: bottom tab bar on phones; master pane + detail pane on tablets.
class AdaptiveShell extends HookWidget {
  const AdaptiveShell({
    super.key,
    required this.shell,
    required this.readerBuilder,
  });

  final StatefulNavigationShell shell;
  final Widget Function(String prayerId) readerBuilder;

  @override
  Widget build(BuildContext context) {
    final selection = useState<String?>(null);
    final tabBar = VavakaTabBar(
      currentIndex: shell.currentIndex,
      inPane: MediaQuery.sizeOf(context).width >= splitViewBreakpoint,
      onSelected: (index) =>
          shell.goBranch(index, initialLocation: index == shell.currentIndex),
    );

    if (MediaQuery.sizeOf(context).width < splitViewBreakpoint) {
      return Scaffold(body: shell, bottomNavigationBar: tabBar);
    }

    final theme = Theme.of(context);
    final colors = VavakaColors.of(context);
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _masterPaneWidth,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(right: BorderSide(color: colors.divider)),
              ),
              child: Theme(
                data: theme.copyWith(
                  scaffoldBackgroundColor: colors.surface,
                  appBarTheme: theme.appBarTheme.copyWith(
                    centerTitle: false,
                    shape: Border(bottom: BorderSide(color: colors.divider)),
                  ),
                ),
                child: PrayerSelection(
                  notifier: selection,
                  child: Column(
                    children: [
                      Expanded(child: shell),
                      tabBar,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: selection.value == null
                ? const _Welcome()
                : readerBuilder(selection.value!),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    return SafeArea(
      child: Center(
        child: SizedBox(
          width: 160,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NinePointedStar(size: 40, color: colors.accent),
              const SizedBox(height: 24),
              Text(
                'Vavaka Baháʼí',
                textAlign: TextAlign.center,
                style: VavakaText.title.copyWith(color: colors.text),
              ),
              const SizedBox(height: 20),
              Text(
                "Safidio ny sokajy iray eo amin'ny ankavia mba hamakiana ireo "
                'vavaka misy ao aminy.',
                textAlign: TextAlign.center,
                style: VavakaText.callout.copyWith(
                  color: colors.textSecondary,
                  height: 24 / 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Outlined nine-pointed star, the symbol used on the tablet welcome pane.
class NinePointedStar extends StatelessWidget {
  const NinePointedStar({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _StarPainter(color));
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.width / 2;
    final inner = outer * 0.84;
    final path = Path();
    for (var i = 0; i < 18; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 9;
      final point =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      i == 0
          ? path.moveTo(point.dx, point.dy)
          : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path..close(),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color;
}
