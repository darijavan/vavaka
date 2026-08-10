import 'package:flutter_test/flutter_test.dart';
import 'package:vavaka/app.dart';

void main() {
  testWidgets('shows the prayer category list on launch', (tester) async {
    await tester.pumpWidget(const MyApp());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Vavaka'), findsWidgets);
    expect(find.text('Andro manelanelana'), findsOneWidget);
    expect(find.text('Ankizy'), findsOneWidget);
  });
}
