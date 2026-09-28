import 'package:flutter/material.dart';

import '../theme.dart';

/// App bar from the Figma "AppBar" component: an optional leading control,
/// the brand lockup (or a custom [title]), and optional trailing actions.
class VavakaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const VavakaAppBar({
    super.key,
    this.leading,
    this.title = const BrandLockup(),
    this.actions = const [],
  });

  final Widget? leading;
  final Widget title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 140,
      leading: leading == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Align(alignment: Alignment.centerLeft, child: leading),
            ),
      titleSpacing: 16,
      title: title,
      actions: [...actions, const SizedBox(width: 8)],
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Image.asset('assets/images/logo.png', width: 22, height: 22),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Vavaka',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VavakaText.brand.copyWith(
              color: VavakaColors.of(context).text,
            ),
          ),
        ),
      ],
    );
  }
}

/// Back chevron with an optional context label, e.g. the category name.
class BackAction extends StatelessWidget {
  const BackAction({super.key, required this.onPressed, this.label});

  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = VavakaColors.of(context).text;
    return Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, size: 24, color: color),
              if (label != null) ...[
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: Text(
                    label!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VavakaText.action.copyWith(color: color),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
