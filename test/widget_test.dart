import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etqab/main.dart';

void main() {
  testWidgets('HomePage displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(homePage: MyHomePage()));

    // Verify that specific widgets are displayed. Adjust the following lines based on actual widgets in MyHomePage.
    expect(find.text('Hello, Guest'), findsOneWidget);
    expect(find.byIcon(Icons.login), findsOneWidget);

    // Tap a specific widget if necessary (adjust the selector and action according to your widget structure)
    await tester.tap(find.byIcon(Icons.login));
    await tester.pump();

    // Verify results after interaction (this depends on what you expect to happen)
    // Adjust the following lines based on expected changes.
    // Example: Check if a new widget is displayed after the tap.
    // expect(find.text('New Widget Text'), findsOneWidget);
  });
}
