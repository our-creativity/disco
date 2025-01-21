import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

abstract class NameContainer {
  const NameContainer(this.name);

  final String name;

  void dispose();
}

@immutable
class NumberContainer {
  const NumberContainer(this.number);

  final int number;
}

void main() {
  testWidgets('Test ProviderScope throws an error for a not found provider',
      (tester) async {
    final zeroProvider = Provider((_) => 0);
    final tenProvider = Provider((_) => 10);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              zeroProvider,
            ],
            child: Builder(
              builder: (context) {
                final ten = tenProvider.get(context);
                return Text(ten.toString());
              },
            ),
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<ProviderWithoutScopeError>().having(
        (error) => error.provider,
        'Matching the wrong ID should result in a ProviderError.',
        equals(tenProvider),
      ),
    );
  });

  testWidgets('Test ProviderScopePortal works', (tester) async {
    final numberContainerProvider = Provider((_) => const NumberContainer(1));

    Future<void> showNumberDialog({required BuildContext context}) {
      return showDialog(
        context: context,
        builder: (dialogContext) {
          return ProviderScopePortal(
            mainContext: context,
            child: Builder(
              builder: (innerContext) {
                final numberContainer =
                    numberContainerProvider.get(innerContext);
                return Text('${numberContainer.number}');
              },
            ),
          );
        },
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              numberContainerProvider,
            ],
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showNumberDialog(context: context);
                  },
                  child: const Text('show dialog'),
                );
              },
            ),
          ),
        ),
      ),
    );
    Finder counterFinder(int value) => find.text('$value');

    final buttonFinder = find.text('show dialog');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(counterFinder(1), findsOneWidget);
  });
}
