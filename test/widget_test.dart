import 'package:flutter_test/flutter_test.dart';

import 'package:vsarts/main.dart';

void main() {
  testWidgets('Invoice creator smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our invoice screen starts with "Create Invoice" title.
    expect(find.text('Create Invoice'), findsOneWidget);
    
    // Verify that we have Customer Information section or fields.
    expect(find.text('Client Name'), findsOneWidget);
  });
}
