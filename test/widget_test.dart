import 'package:flutter_test/flutter_test.dart';

import 'package:lipidlog/main.dart';

void main() {
  testWidgets('StartupErrorApp renders fallback message',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const StartupErrorApp(
        error: 'Test startup error',
        stackTrace: null,
      ),
    );

    expect(find.text('LipidLog'), findsOneWidget);
    expect(find.text('The app failed to start correctly.'), findsOneWidget);
    expect(find.textContaining('Test startup error'), findsOneWidget);
  });
}
