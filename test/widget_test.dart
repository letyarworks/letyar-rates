import 'package:flutter_test/flutter_test.dart';
import 'package:letyar_rates/main.dart';

void main() {
  testWidgets('Letyar Rates app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const LetyarRatesApp());

    expect(find.text('Letyar Rates'), findsOneWidget);
    expect(find.text('USD / MMK'), findsOneWidget);
    expect(find.text('Gold'), findsOneWidget);
    expect(find.text('Price History'), findsOneWidget);
  });
}
