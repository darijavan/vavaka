import 'package:flutter/material.dart';

/// Vavaka design tokens from the Figma "Foundations" frame.
@immutable
class VavakaColors extends ThemeExtension<VavakaColors> {
  const VavakaColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.text,
    required this.readerText,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.divider,
    required this.dividerStrong,
    required this.border,
    required this.tabSelected,
    required this.tabSelectedBackground,
  });

  static const light = VavakaColors(
    background: Color(0xFFF4ECDA),
    surface: Color(0xFFFBF6EA),
    surfaceRaised: Color(0xFFEFE3CC),
    text: Color(0xFF2A1B16),
    readerText: Color(0xFF1C1A29),
    textSecondary: Color(0xFF6E5B4C),
    textMuted: Color(0xFF807061),
    accent: Color(0xFFA9781F),
    divider: Color(0xFFE4D6BD),
    dividerStrong: Color(0xFFD3C09F),
    border: Color(0xFF3A2C34),
    tabSelected: Color(0xFF8B5E3C),
    tabSelectedBackground: Color(0x1F8B5E3C),
  );

  static const dark = VavakaColors(
    background: Color(0xFF140E12),
    surface: Color(0xFF1E151B),
    surfaceRaised: Color(0xFF2A1F27),
    text: Color(0xFFF3EBDC),
    readerText: Color(0xFFDACEBA),
    textSecondary: Color(0xFFA99B8A),
    textMuted: Color(0xFF7A6C60),
    accent: Color(0xFFE3B24A),
    divider: Color(0xFF2C2127),
    dividerStrong: Color(0xFF3A2C34),
    border: Color(0xFF3A2C34),
    tabSelected: Color(0xFFE3B24A),
    tabSelectedBackground: Color(0x1FE3B24A),
  );

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color text;
  final Color readerText;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color divider;
  final Color dividerStrong;
  final Color border;
  final Color tabSelected;
  final Color tabSelectedBackground;

  static VavakaColors of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<VavakaColors>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  VavakaColors copyWith() => this;

  @override
  VavakaColors lerp(VavakaColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

const readingFont = 'Spectral';
const uiFont = 'HankenGrotesk';

ThemeData buildVavakaTheme(Brightness brightness) {
  final colors = brightness == Brightness.dark
      ? VavakaColors.dark
      : VavakaColors.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: colors.accent,
        brightness: brightness,
      ).copyWith(
        primary: colors.accent,
        onPrimary: colors.background,
        surface: colors.background,
        onSurface: colors.text,
        onSurfaceVariant: colors.textSecondary,
        outline: colors.divider,
        outlineVariant: colors.divider,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: uiFont,
    scaffoldBackgroundColor: colors.background,
    extensions: [colors],
    dividerTheme: DividerThemeData(color: colors.divider, thickness: 1),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      foregroundColor: colors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 52,
      shape: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(colors.background),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.accent
            : colors.surfaceRaised,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: colors.accent,
      inactiveTrackColor: colors.surfaceRaised,
      thumbColor: colors.text,
      activeTickMarkColor: Colors.transparent,
      inactiveTickMarkColor: Colors.transparent,
      trackHeight: 4,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Text styles from the Figma "Typography" frame. Colors come from
/// [VavakaColors] at the call site.
abstract final class VavakaText {
  static const title = TextStyle(
    fontFamily: readingFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
  );
  static const rowTitle = TextStyle(
    fontFamily: readingFont,
    fontSize: 17,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
  static const attribution = TextStyle(
    fontFamily: readingFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
  );
  static const brand = TextStyle(
    fontFamily: uiFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const callout = TextStyle(
    fontFamily: uiFont,
    fontSize: 15,
    height: 22 / 15,
  );
  static const action = TextStyle(
    fontFamily: uiFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  static const footnote = TextStyle(
    fontFamily: uiFont,
    fontSize: 13,
    height: 19 / 13,
  );
  static const caption = TextStyle(
    fontFamily: uiFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  static const overline = TextStyle(
    fontFamily: uiFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.88,
  );
}
