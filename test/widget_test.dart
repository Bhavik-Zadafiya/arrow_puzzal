import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_pussal/app/app.dart';

void main() {
  testWidgets('Splash screen shows app name', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pump();
    expect(find.text('Arrow Pussal'), findsOneWidget);
  });
}
