import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test improved error messages
final Provider<int> counterProvider = Provider((_) => 5, lazy: false);
final Provider<int> doubleCounterProvider = Provider(
  (context) => counterProvider.of(context) * 2,
  lazy: false,
);

void main() {
  testWidgets('Show improved error message', (WidgetTester tester) async {
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: [
              doubleCounterProvider,  // Wrong order!
              counterProvider,
            ],
            child: Container(),
          ),
        ),
      );
    } catch (e) {
      print('\n========== ERROR MESSAGE ==========');
      print(e);
      print('===================================\n');
    }

    final exception = tester.takeException();
    expect(exception, isA<ProviderForwardReferenceError>());
  });
}
