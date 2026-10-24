import 'package:flutter_test/flutter_test.dart';
import 'package:stokesu/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SetokeApp());
    expect(find.byType(SetokeApp), findsOneWidget);
  });
}
