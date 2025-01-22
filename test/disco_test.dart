import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('Test key change in ProviderScope (with Provider)',
      (tester) async {
    var count = 0;
    final numberProvider = Provider((_) => count);

    final keyNotifier = ValueNotifier<Key>(Key("initial"));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: keyNotifier,
            builder: (BuildContext context, Key key, Widget? child) {
              return ProviderScope(
                key: key,
                providers: [
                  numberProvider,
                ],
                child: Builder(
                  builder: (context) {
                    final number = numberProvider.get(context);
                    return Column(
                      children: [
                        Text("number: ${number.toString()}"),
                        ElevatedButton(
                          onPressed: () {
                            count = 1;
                            keyNotifier.value = Key("changed");
                          },
                          child: const Text('change key'),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    Finder textFinder(String value) => find.textContaining(value);

    await tester.pumpAndSettle();
    expect(textFinder("number: 0"), findsOneWidget);

    final buttonFinder = find.text('change key');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(textFinder("number: 1"), findsOneWidget);
  });

  testWidgets('Test key change in ProviderScope (with ArgProvider)',
      (tester) async {
    final numberProvider = Provider.withArgument((_, int arg) => arg);

    final initialKey = Key("initial");

    final keyNotifier = ValueNotifier<Key>(initialKey);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: keyNotifier,
            builder: (BuildContext context, Key key, Widget? child) {
              return ProviderScope(
                key: key,
                providers: [
                  numberProvider(key == initialKey ? 0 : 1),
                ],
                child: Builder(
                  builder: (context) {
                    final number = numberProvider.get(context);
                    return Column(
                      children: [
                        Text("number: ${number.toString()}"),
                        ElevatedButton(
                          onPressed: () {
                            keyNotifier.value = Key("changed");
                          },
                          child: const Text('change key'),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
    Finder textFinder(String value) => find.text(value);

    await tester.pumpAndSettle();
    expect(textFinder("number: 0"), findsOneWidget);

    final buttonFinder = find.text('change key');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(textFinder("number: 1"), findsOneWidget);
  });
}
