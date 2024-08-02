import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:Etqan/main.dart';

void main() {
  testWidgets('HomePage displays correctly', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp(homePage: MyHomePage()));

    // Verify that the text "Hello, Guest" and the login icon are displayed
    expect(find.text('Hello, Guest'), findsOneWidget);
    expect(find.byIcon(Icons.login), findsOneWidget);

    // If tapping the login icon should trigger a change, you can test that as well
    await tester.tap(find.byIcon(Icons.login));
    await tester.pump(); // Rebuild the widget after the tap

    // Verify the result after interaction (adjust this based on expected changes)
    // For example, if tapping the login icon shows a new widget, you might test it here
    // expect(find.text('New Widget Text'), findsOneWidget);
  });
}
