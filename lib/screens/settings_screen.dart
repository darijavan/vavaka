import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../data/font_size_store.dart';
import '../theme.dart';
import '../widgets/section_label.dart';
import '../widgets/vavaka_app_bar.dart';

/// Keep in sync with `version` in pubspec.yaml (guarded by a test).
const appVersion = '1.0.0';

class SettingsScreen extends HookWidget {
  const SettingsScreen({
    super.key,
    required this.fontSizeStore,
    this.sharedFontSize,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final FontSizeStore fontSizeStore;
  final ValueNotifier<double?>? sharedFontSize;
  final ValueListenable<ThemeMode> themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final localFontSize = useState<double?>(null);
    final fontSize = sharedFontSize ?? localFontSize;
    useValueListenable(fontSize);
    useEffect(() {
      if (sharedFontSize != null) return null;
      var active = true;
      fontSizeStore.loadFontSize().then((value) {
        if (active) fontSize.value = value;
      });
      return () => active = false;
    }, [fontSizeStore, sharedFontSize]);
    final isDark = useValueListenable(themeMode) == ThemeMode.dark;
    final colors = VavakaColors.of(context);
    final rowStyle = VavakaText.callout.copyWith(color: colors.text);

    return Scaffold(
      appBar: VavakaAppBar(
        actions: [
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            style: TextButton.styleFrom(foregroundColor: colors.text),
            child: const Text('Vita', style: VavakaText.action),
          ),
        ],
      ),
      body: fontSize.value == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.only(top: 16),
              children: [
                const _SectionHeader('Fisehoana', top: 0),
                Material(
                  color: colors.surface,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('Endrika maizina', style: rowStyle),
                        value: isDark,
                        onChanged: (value) => onThemeModeChanged(
                          value ? ThemeMode.dark : ThemeMode.light,
                        ),
                      ),
                      const Divider(height: 1, indent: 8, endIndent: 8),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('Haben’ny soratra', style: rowStyle),
                            ),
                            Text(
                              fontSize.value!.round().toString(),
                              style: VavakaText.footnote.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Slider(
                        value: fontSize.value!,
                        min: FontSizeStore.minimumFontSize,
                        max: FontSizeStore.maximumFontSize,
                        divisions:
                            (FontSizeStore.maximumFontSize -
                                    FontSizeStore.minimumFontSize)
                                .round(),
                        label: fontSize.value!.round().toString(),
                        onChanged: (value) {
                          if (value == fontSize.value) return;
                          fontSize.value = value;
                          fontSizeStore.saveFontSize(value);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Text(
                          'Ry Andriamanitro!',
                          style: TextStyle(
                            fontFamily: readingFont,
                            fontSize: fontSize.value!,
                            color: colors.readerText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const _SectionHeader('App', top: 24),
                Material(
                  color: colors.surface,
                  child: ListTile(
                    title: Text('Dikan-teny', style: rowStyle),
                    trailing: Text(
                      appVersion,
                      style: VavakaText.footnote.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {required this.top});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top, 16, 8),
      child: SectionLabel(text),
    );
  }
}
