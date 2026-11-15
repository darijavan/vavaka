import 'package:flutter/material.dart';

import '../theme.dart';

class VavakaTab {
  const VavakaTab(this.label, this.icon);

  final String label;
  final IconData icon;
}

const vavakaTabs = [
  VavakaTab('Vavaka', Icons.menu_book_outlined),
  VavakaTab('Tiana', Icons.star_border),
  VavakaTab('Vao haingana', Icons.schedule),
  VavakaTab('Tsiahy', Icons.notifications_none),
];

/// Floating pill tab bar from the Figma "TabBar" component.
class VavakaTabBar extends StatelessWidget {
  const VavakaTabBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    this.inPane = false,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// In the tablet master pane the pill sits on the pane surface instead.
  final bool inPane;

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    return ColoredBox(
      color: inPane ? colors.surface : colors.background,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Material(
            color: inPane ? colors.background : colors.surface,
            borderRadius: BorderRadius.circular(39),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  for (var index = 0; index < vavakaTabs.length; index++)
                    Expanded(
                      child: _TabButton(
                        tab: vavakaTabs[index],
                        selected: index == currentIndex,
                        onTap: () => onSelected(index),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final VavakaTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = VavakaColors.of(context);
    final color = selected ? colors.tabSelected : colors.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.tabSelectedBackground : Colors.transparent,
        borderRadius: BorderRadius.circular(27),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(27),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(tab.icon, size: 22, color: color),
                const SizedBox(height: 4),
                Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.1,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
