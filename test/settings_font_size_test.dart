import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vavaka/copy.dart';
import 'package:vavaka/app.dart';
import 'package:vavaka/data/font_size_store.dart';

class _MemoryFontSizeStore implements FontSizeStore {
  _MemoryFontSizeStore(this.fontSize);

  double fontSize;
  final savedValues = <double>[];

  @override
  Future<double> loadFontSize() async => fontSize;

  @override
  Future<void> saveFontSize(double value) async {
    fontSize = value;
    savedValues.add(value);
  }
}

void main() {
  testWidgets('opens settings and persists a changed reader font size', (
    tester,
  ) async {
    final store = _MemoryFontSizeStore(24);
    await tester.pumpWidget(MyApp(fontSizeStore: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(Copy.settings));
    await tester.pumpAndSettle();

    expect(find.text('Haben’ny soratra'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    final preview = find.text('Ry Andriamanitro!');
    expect(tester.widget<Text>(preview).style?.fontSize, 24);

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, FontSizeStore.minimumFontSize);
    expect(slider.max, FontSizeStore.maximumFontSize);

    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pumpAndSettle();

    expect(store.savedValues, isNotEmpty);
    expect(store.savedValues.last, isNot(24));
    expect(
      tester.widget<Text>(preview).style?.fontSize,
      store.savedValues.last,
    );
    expect(
      find.text(store.savedValues.last.round().toString()),
      findsOneWidget,
    );
  });
}
