import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../data/font_size_store.dart';

class SettingsScreen extends HookWidget {
  const SettingsScreen({
    super.key,
    required this.fontSizeStore,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final FontSizeStore fontSizeStore;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final fontSize = useState<double?>(null);
    final selectedThemeMode = useState(themeMode);
    useEffect(() {
      var active = true;
      fontSizeStore.loadFontSize().then((value) {
        if (active) {
          fontSize.value = value;
        }
      });
      return () => active = false;
    }, [fontSizeStore]);
    useEffect(() {
      selectedThemeMode.value = themeMode;
      return null;
    }, [themeMode]);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: fontSize.value == null
          ? const Center(child: Text('Loading…'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark theme'),
                  value: selectedThemeMode.value == ThemeMode.dark,
                  onChanged: (value) {
                    final newThemeMode = value
                        ? ThemeMode.dark
                        : ThemeMode.light;
                    selectedThemeMode.value = newThemeMode;
                    onThemeModeChanged(newThemeMode);
                  },
                ),
                const Text('Reader font size'),
                Text(fontSize.value!.round().toString()),
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
                    if (value == fontSize.value) {
                      return;
                    }
                    fontSize.value = value;
                    fontSizeStore.saveFontSize(value);
                  },
                ),
              ],
            ),
    );
  }
}
