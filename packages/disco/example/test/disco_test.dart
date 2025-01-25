import 'package:disco/src/disco_internal.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockModel extends Model {
  int _counter = 5;

  @override
  int get counter => _counter;

  @override
  void incrementCounter() {
    _counter += 2;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'Counter increments when FAB is pressed',
    (WidgetTester tester) async {
      // Build the app and trigger a frame.
      await tester.pumpWidget(const MainApp());

      // Verify that the initial counter value is 0.
      expect(
        find.text('You have pushed the button this many times:'),
        findsOneWidget,
      );
      expect(find.text('0'), findsOneWidget);

      // Tap the floating action button to increment the counter.
      await tester.tap(find.byType(FloatingActionButton));
      // Rebuild the widget after the state has changed.
      await tester.pump();

      // Verify that the counter has incremented to 1.
      expect(find.text('1'), findsOneWidget);
    },
  );
  testWidgets('Counter displays mocked value', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScopeOverride(
        overrides: [
          modelProvider.overrideWithValue(MockModel()),
        ],
        child: const MainApp(),
      ),
    );

    // Verify that the initial counter value is the mocked value (5).
    expect(
      find.text('You have pushed the button this many times:'),
      findsOneWidget,
    );
    expect(find.text('5'), findsOneWidget);

    // Tap the floating action button to increment the counter.
    await tester.tap(find.byType(FloatingActionButton));
    // Rebuild the widget after the state has changed.
    await tester.pump();

    // Verify that the counter has incremented to 7.
    expect(find.text('7'), findsOneWidget);
  });
}
