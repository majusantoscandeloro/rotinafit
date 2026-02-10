import 'package:flutter_test/flutter_test.dart';
import 'package:rotinafit/main.dart';

void main() {
  testWidgets('App mounts and shows RotinaFit after load', (WidgetTester tester) async {
    await tester.pumpWidget(const RotinaFitApp());
    await tester.pump();
    // Wait for async load (AppProvider.load)
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('RotinaFit'), findsOneWidget);
  });
}
