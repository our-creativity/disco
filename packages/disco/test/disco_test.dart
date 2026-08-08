// NB: by importing disco/src/disco_internal.dart instead of disco/disco.dart,
// we can test components that are not exported.
// ignore_for_file: document_ignores

import 'package:disco/src/disco_internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

abstract class NameContainer {
  // ignore: unreachable_from_main
  const NameContainer(this.name);

  final String name;

  void dispose();
}

class MockNameContainer extends Mock implements NameContainer {
  MockNameContainer(this.name);

  @override
  final String name;
}

@immutable
class NumberContainer {
  const NumberContainer(this.number);

  final int number;
}

void main() {
  testWidgets('Test multiple ProviderScope in tree', (tester) async {
    final numberContainer1Provider = Provider((_) => const NumberContainer(1));
    final numberContainer2Provider = Provider(
      (_) => const NumberContainer(100),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              numberContainer1Provider(),
              numberContainer2Provider(),
            ],
            child: Builder(
              builder: (context) {
                final numberProvider1 = numberContainer1Provider.of(context);
                final numberProvider2 = numberContainer2Provider.of(context);
                return Text(
                  '''${numberProvider1.number} ${numberProvider2.number}''',
                );
              },
            ),
          ),
        ),
      ),
    );
    Finder providerFinder(int value1, int value2) =>
        find.text('$value1 $value2');

    expect(providerFinder(1, 100), findsOneWidget);
  });
  testWidgets('Test Provider.withArgument', (tester) async {
    final doubleCountProvider = Provider.withArgument(
      (context, int arg) => arg * 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [doubleCountProvider(3)],
            child: Builder(
              builder: (context) {
                final doubleCount = doubleCountProvider.of(context);
                return Text(doubleCount.toString());
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('The value of a provider is not created until it is injected', (
    tester,
  ) async {
    var fired = false;

    final doubleCountProvider = Provider.withArgument((context, int arg) {
      fired = true;
      return arg * 2;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [doubleCountProvider(3)],
            // Nothing injects the provider.
            child: const Text('hello'),
          ),
        ),
      ),
    );

    expect(fired, false);
  });

  testWidgets('''A value can be created as soon as its scope is mounted, by injecting it right below the scope''', (
    tester,
  ) async {
    var fired = false;

    final doubleCountProvider = Provider.withArgument((context, int arg) {
      fired = true;
      return arg * 2;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [doubleCountProvider(3)],
            // This is the recommended way of creating a value eagerly.
            child: Builder(
              builder: (context) {
                doubleCountProvider.of(context);
                return const Text('hello');
              },
            ),
          ),
        ),
      ),
    );

    expect(fired, true);
  });

  testWidgets('Test Provider.of within Provider create fn', (tester) async {
    final numberProvider = Provider((_) => 5);

    final doubleNumberProvider = Provider((context) {
      final number = numberProvider.of(context);
      return number * 2;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [numberProvider()],
            child: ProviderScope(
              providers: [doubleNumberProvider()],
              child: Builder(
                builder: (context) {
                  final number = numberProvider.of(context);
                  final doubleNumber = doubleNumberProvider.of(context);
                  return Text('$number $doubleNumber');
                },
              ),
            ),
          ),
        ),
      ),
    );
    Finder numberFinder(int value1, int value2) => find.text('$value1 $value2');
    expect(numberFinder(5, 10), findsOneWidget);
  });

  testWidgets('Test ProviderScope throws an error for a not found provider', (
    tester,
  ) async {
    final zeroProvider = Provider((_) => 0);
    final tenProvider = Provider((_) => 10);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [zeroProvider()],
            child: Builder(
              builder: (context) {
                final ten = tenProvider.of(context);
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

  testWidgets(
    '''Test ProviderScope throws ProviderWithoutScopeError for a not found ArgProvider''',
    (tester) async {
      final numberProvider = Provider.withArgument((context, int arg) => arg);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final ten = numberProvider.of(context);
                return Text(ten.toString());
              },
            ),
          ),
        ),
      );
      expect(
        tester.takeException(),
        const TypeMatcher<ProviderWithoutScopeError>().having(
          (error) => error.provider,
          'Matching the wrong ID should result in a ProviderError.',
          equals(numberProvider),
        ),
      );
    },
  );

  testWidgets(
    '''Test ProviderScope throws MultipleProviderOfSameInstance for multiple instances of ArgProvider''',
    (tester) async {
      final numberProvider = Provider.withArgument((context, int arg) => arg);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              providers: [numberProvider(1), numberProvider(2)],
              child: Builder(
                builder: (context) {
                  final ten = numberProvider.of(context);
                  return Text(ten.toString());
                },
              ),
            ),
          ),
        ),
      );
      expect(
        tester.takeException(),
        const TypeMatcher<MultipleProviderOfSameInstance>(),
      );
    },
  );

  testWidgets(
    'Test ProviderScope returns null for a not found provider (maybeOf)',
    (tester) async {
      final numberContainerProvider = Provider((_) => const NumberContainer(0));
      final nameContainerProvider = Provider<NameContainer>(
        (_) => MockNameContainer('name'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              providers: [nameContainerProvider()],
              child: Builder(
                builder: (context) {
                  final numberContainer = numberContainerProvider.maybeOf(
                    context,
                  );
                  return Text(numberContainer.toString());
                },
              ),
            ),
          ),
        ),
      );
      expect(find.text('null'), findsOneWidget);
    },
  );

  testWidgets(
    '''Test ProviderScope throws if the same provider is provided multiple times''',
    (tester) async {
      final numberContainerProvider = Provider((_) => const NumberContainer(1));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScope(
              providers: [
                numberContainerProvider(),
                numberContainerProvider(),
              ],
              child: const SizedBox(),
            ),
          ),
        ),
      );
      expect(
        tester.takeException(),
        const TypeMatcher<MultipleProviderOfSameInstance>(),
      );
    },
  );

  testWidgets('Test provider injection', (tester) async {
    final NameContainer nameContainer = MockNameContainer('Ale');

    var fullNameContainerProviderDisposed = false;

    final numberContainer1Provider = Provider(
      (_) => const NumberContainer(1),
    );
    final numberContainer2Provider = Provider(
      (_) => const NumberContainer(100),
    );
    final nameContainerProvider = Provider(
      (_) => nameContainer,
      dispose: (provider) => provider.dispose(),
    );
    final fullNameContainerProvider = Provider.withArgument(
      (_, String surname) => MockNameContainer('John $surname'),
      dispose: (provider) {
        fullNameContainerProviderDisposed = true;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              nameContainerProvider(),
              numberContainer1Provider(),
              numberContainer2Provider(),
              fullNameContainerProvider('Smith'),
            ],
            child: Builder(
              builder: (context) {
                final nameContainer = nameContainerProvider.of(context);
                final numberContainer1 = numberContainer1Provider.of(context);
                final numberContainer2 = numberContainer2Provider.of(context);
                final fullNameContainer = fullNameContainerProvider.of(context);
                return Text(
                  '''${nameContainer.name} ${numberContainer1.number} ${numberContainer2.number} ${fullNameContainer.name}''',
                );
              },
            ),
          ),
        ),
      ),
    );
    Finder providerFinder(
      String value1,
      int value2,
      int value3,
      String value4,
    ) => find.text('$value1 $value2 $value3 $value4');

    expect(providerFinder('Ale', 1, 100, 'John Smith'), findsOneWidget);

    // mock NameProvider dispose method
    when(nameContainer.dispose()).thenReturn(null);
    // Check that the dispose method in the provider with argument is not called
    expect(fullNameContainerProviderDisposed, false);
    // Push a different widget
    await tester.pumpWidget(Container());
    // check dispose has been called on NameProvider
    verify(nameContainer.dispose()).called(1);
    // check that the dispose method in the provider with argument is called
    expect(fullNameContainerProviderDisposed, true);
  });

  testWidgets('Test ProviderScopePortal works', (tester) async {
    final numberContainerProvider = Provider(
      (_) => const NumberContainer(1),
    );

    Future<void> showNumberDialog({required BuildContext context}) {
      return showDialog(
        context: context,
        builder: (dialogContext) {
          return ProviderScopePortal(
            mainContext: context,
            child: Builder(
              builder: (innerContext) {
                final numberContainer = numberContainerProvider.of(
                  innerContext,
                );
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
            providers: [numberContainerProvider()],
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showNumberDialog(context: context).ignore();
                  },
                  child: const Text('show dialog'),
                );
              },
            ),
          ),
        ),
      ),
    );
    Finder numberFinder(int value) => find.text('$value');

    final buttonFinder = find.text('show dialog');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(numberFinder(1), findsOneWidget);
  });

  testWidgets(
    'Test ProviderScopePortal throws an error for a not found provider',
    (tester) async {
      final numberContainerProvider = Provider((_) => const NumberContainer(0));
      final nameContainerProvider = Provider<NameContainer>(
        (_) => MockNameContainer('name'),
      );

      Future<void> showNumberDialog({required BuildContext context}) {
        return showDialog(
          context: context,
          builder: (dialogContext) {
            return ProviderScopePortal(
              mainContext: context,
              child: Builder(
                builder: (innerContext) {
                  final numberContainer = numberContainerProvider.of(
                    innerContext,
                  );
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
              providers: [nameContainerProvider()],
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showNumberDialog(context: context).ignore();
                    },
                    child: const Text('show dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      final buttonFinder = find.text('show dialog');
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        const TypeMatcher<ProviderWithoutScopeError>(),
      );
    },
  );

  testWidgets('Test ProviderScope inside ProviderScopePortal works', (
    tester,
  ) async {
    final numberContainerProvider = Provider(
      (_) => const NumberContainer(1),
    );

    final secondNumberContainerProvider = Provider(
      (_) => const NumberContainer(2),
    );

    final doubleCountProvider = Provider.withArgument(
      (context, int arg) => arg * 2,
    );

    Future<void> showNumberDialog({required BuildContext context}) {
      return showDialog(
        context: context,
        builder: (dialogContext) {
          return ProviderScopePortal(
            mainContext: context,
            child: ProviderScope(
              providers: [
                secondNumberContainerProvider(),
                doubleCountProvider(3),
              ],
              child: Builder(
                builder: (innerContext) {
                  final numberContainer = numberContainerProvider.of(
                    innerContext,
                  );
                  final secondNumberContainer = secondNumberContainerProvider
                      .of(innerContext);
                  final doubleCount = doubleCountProvider.of(innerContext);
                  return Text(
                    '''${numberContainer.number} ${secondNumberContainer.number} $doubleCount''',
                  );
                },
              ),
            ),
          );
        },
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [numberContainerProvider()],
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showNumberDialog(context: context).ignore();
                  },
                  child: const Text('show dialog'),
                );
              },
            ),
          ),
        ),
      ),
    );
    Finder number3Finder(int value, int value2, int value3) =>
        find.text('$value $value2 $value3');

    final buttonFinder = find.text('show dialog');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(number3Finder(1, 2, 6), findsOneWidget);
  });

  testWidgets('ProviderScopePortal with lazy providers accessing '
      'same-scope providers', (tester) async {
    // This test covers the ProviderScopePortal path where lazy providers
    // access other providers in the same scope, testing the cached value
    // return and portal context navigation.
    final baseProvider = Provider((_) => 10);
    final doubleProvider = Provider((context) {
      final base = baseProvider.of(context);
      return base * 2;
    });

    Future<void> showNumberDialog({required BuildContext context}) {
      return showDialog(
        context: context,
        builder: (dialogContext) {
          return ProviderScopePortal(
            mainContext: context,
            child: Builder(
              builder: (portalContext) {
                final double = doubleProvider.of(portalContext);
                return Text(double.toString());
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
            providers: [baseProvider(), doubleProvider()],
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showNumberDialog(context: context).ignore();
                  },
                  child: const Text('show dialog'),
                );
              },
            ),
          ),
        ),
      ),
    );

    final buttonFinder = find.text('show dialog');
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('Test key change in ProviderScope (with Provider)', (
    tester,
  ) async {
    var count = 0;
    final numberProvider = Provider((_) => count);

    final keyNotifier = ValueNotifier<Key>(const Key('initial'));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder(
            valueListenable: keyNotifier,
            builder: (BuildContext context, Key key, Widget? child) {
              return ProviderScope(
                key: key,
                providers: [numberProvider()],
                child: Builder(
                  builder: (context) {
                    final number = numberProvider.of(context);
                    return Column(
                      children: [
                        Text('number: $number'),
                        ElevatedButton(
                          onPressed: () {
                            count = 1;
                            keyNotifier.value = const Key('changed');
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
    expect(textFinder('number: 0'), findsOneWidget);

    final buttonFinder = find.text('change key');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(textFinder('number: 1'), findsOneWidget);
  });

  testWidgets('Test key change in ProviderScope (with ArgProvider)', (
    tester,
  ) async {
    final numberProvider = Provider.withArgument((_, int arg) => arg);

    const initialKey = Key('initial');

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
                    final number = numberProvider.of(context);
                    return Column(
                      children: [
                        Text('number: $number'),
                        ElevatedButton(
                          onPressed: () {
                            keyNotifier.value = const Key('changed');
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
    expect(textFinder('number: 0'), findsOneWidget);

    final buttonFinder = find.text('change key');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(textFinder('number: 1'), findsOneWidget);
  });

  testWidgets('''ProviderScopeOverride should override providers''', (
    tester,
  ) async {
    final numberProvider = Provider<int>((_) => 0);
    final mockNumberProvider = Provider<int>((_) => 9);
    await tester.pumpWidget(
      ProviderScopeOverride(
        overrides: [
          numberProvider.overrideWith(mockNumberProvider),
        ],
        child: MaterialApp(
          home: ProviderScope(
            providers: [
              numberProvider(),
            ],
            child: Builder(
              builder: (context) {
                final number = numberProvider.of(context);
                return Text(number.toString());
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('''ProviderScopeOverride should override providers''', (
    tester,
  ) async {
    final numberProvider = Provider<int>((_) => 0);
    final number100Provider = Provider<int>((_) => 100);

    await tester.pumpWidget(
      ProviderScopeOverride(
        overrides: [
          numberProvider.overrideWith(number100Provider),
        ],
        child: MaterialApp(
          home: ProviderScope(
            providers: [
              numberProvider(),
            ],
            child: Builder(
              builder: (context) {
                final number = numberProvider.of(context);
                return Text(number.toString());
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('''ProviderScopeOverride should override argument providers''', (
    tester,
  ) async {
    final numberProvider = Provider.withArgument((_, int arg) => arg);
    final mockNumberProvider = Provider.withArgument((_, int arg) => 16);
    await tester.pumpWidget(
      ProviderScopeOverride(
        overrides: [
          numberProvider.overrideWith(mockNumberProvider),
        ],
        child: MaterialApp(
          home: ProviderScope(
            providers: [
              numberProvider(1),
            ],
            child: Builder(
              builder: (context) {
                final number = numberProvider.of(context);
                return Text(number.toString());
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('16'), findsOneWidget);
  });

  testWidgets('Only one ProviderScopeOverride can be present', (tester) async {
    final numberProvider = Provider<int>((_) => 0);
    final number100Provider = Provider<int>((_) => 100);
    final number200Provider = Provider<int>((_) => 200);

    await tester.pumpWidget(
      ProviderScopeOverride(
        overrides: [
          numberProvider.overrideWith(number100Provider),
        ],
        child: MaterialApp(
          home: ProviderScopeOverride(
            overrides: [
              numberProvider.overrideWith(number200Provider),
            ],
            child: Builder(
              builder: (context) {
                final number = numberProvider.of(context);
                return Text(number.toString());
              },
            ),
          ),
        ),
      ),
    );
    expect(
      tester.takeException(),
      const TypeMatcher<MultipleProviderScopeOverrideError>(),
    );
  });

  testWidgets(
    '''ProviderScopeOverrideState.maybeOf(context) returns null if no ProviderScopeOverride is found in the widget tree''',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final isNull =
                    ProviderScopeOverrideState.maybeOf(context) == null;
                return Text('maybeOf returns null: $isNull');
              },
            ),
          ),
        ),
      );
      Finder textFinder(String value) => find.text(value);

      await tester.pumpAndSettle();
      expect(textFinder('maybeOf returns null: true'), findsOneWidget);
    },
  );

  testWidgets(
    '''ProviderScopeOverrideState.maybeOf(context) returns a ProviderScopeOverrideState if a ProviderScopeOverride is found in the widget tree''',
    (tester) async {
      await tester.pumpWidget(
        ProviderScopeOverride(
          overrides: const [],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  final isState =
                      ProviderScopeOverrideState.maybeOf(context) != null;
                  return Text(
                    'maybeOf returns ProviderScopeOverrideState: $isState',
                  );
                },
              ),
            ),
          ),
        ),
      );
      Finder textFinder(String value) => find.text(value);

      await tester.pumpAndSettle();
      expect(
        textFinder('maybeOf returns ProviderScopeOverrideState: true'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    '''ProviderScopeOverride must throw a MultipleProviderOverrideOfSameInstance for duplicated providers''',
    (tester) async {
      final number0Provider = Provider<int>((context) => 0);
      final number1Provider = Provider<int>((context) => 1);
      final number2Provider = Provider<int>((context) => 2);

      await tester.pumpWidget(
        ProviderScopeOverride(
          overrides: [
            number0Provider.overrideWith(number1Provider),
            number0Provider.overrideWith(number2Provider),
          ],
          child: const Text('hello'),
        ),
      );

      expect(
        tester.takeException(),
        const TypeMatcher<MultipleProviderOverrideOfSameInstance>(),
      );
    },
  );

  testWidgets(
    '''Test ProviderScopeOverride throws MultipleProviderOverrideOfSameInstance for multiple instances of ArgProvider''',
    (tester) async {
      final numberProvider = Provider.withArgument((context, int arg) => arg);
      final numberPlusOneProvider = Provider.withArgument(
        (context, int arg) => arg + 1,
      );
      final numberPlusTwoProvider = Provider.withArgument(
        (context, int arg) => arg + 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProviderScopeOverride(
              overrides: [
                numberProvider.overrideWith(numberPlusOneProvider),
                numberProvider.overrideWith(numberPlusTwoProvider),
              ],
              child: Builder(
                builder: (context) {
                  final ten = numberProvider.of(context);
                  return Text(ten.toString());
                },
              ),
            ),
          ),
        ),
      );
      expect(
        tester.takeException(),
        const TypeMatcher<MultipleProviderOverrideOfSameInstance>(),
      );
    },
  );

  // Same-scope provider access tests
  testWidgets('Provider can access earlier provider in same scope', (
    tester,
  ) async {
    final numberProvider = Provider((_) => 5);
    final doubleProvider = Provider((context) {
      final number = numberProvider.of(context);
      return number * 2;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [numberProvider(), doubleProvider()],
            child: Builder(
              builder: (context) {
                final double = doubleProvider.of(context);
                return Text(double.toString());
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('Throws ProviderForwardReferenceError on forward reference', (
    tester,
  ) async {
    final numberProvider = Provider<int>((_) => 5);
    final doubleProvider = Provider<int>((context) {
      final number = numberProvider.of(context); // Forward reference!
      return number * 2;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            // Wrong order: doubleProvider depends on numberProvider
            // but comes first
            providers: [doubleProvider(), numberProvider()],
            // The error is thrown while the value of `doubleProvider` is
            // created, i.e. the first time it is injected.
            child: Builder(
              builder: (context) {
                doubleProvider.of(context);
                return Container();
              },
            ),
          ),
        ),
      ),
    );

    expect(
      tester.takeException(),
      const TypeMatcher<ProviderForwardReferenceError>(),
    );
  });

  testWidgets('ArgProvider can access earlier provider in same scope', (
    tester,
  ) async {
    final numberProvider = Provider((_) => 5);
    final multiplierProvider = Provider.withArgument(
      (context, int multiplier) {
        final number = numberProvider.of(context);
        return number * multiplier;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [numberProvider(), multiplierProvider(3)],
            child: Builder(
              builder: (context) {
                final result = multiplierProvider.of(context);
                return Text(result.toString());
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('Nested provider dependencies work (A→B→C)', (tester) async {
    final aProvider = Provider((_) => 1);
    final bProvider = Provider(
      (context) => aProvider.of(context) + 1,
    );
    final cProvider = Provider(
      (context) => bProvider.of(context) + 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [aProvider(), bProvider(), cProvider()],
            child: Builder(
              builder: (context) {
                final c = cProvider.of(context);
                return Text(c.toString());
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('Multiple lazy providers accessing same earlier provider '
      'reuses created value', (tester) async {
    // This test ensures that when provider A is created lazily by provider B,
    // and then provider C also accesses provider A, the already-created value
    // is returned (testing the cached value path in same-scope access).
    var creationCount = 0;
    final aProvider = Provider((_) {
      creationCount++;
      return 1;
    });

    final bProvider = Provider((context) {
      return aProvider.of(context) + 1;
    });

    final cProvider = Provider((context) {
      return aProvider.of(context) + 2;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [aProvider(), bProvider(), cProvider()],
            child: Builder(
              builder: (context) {
                // Access B first, which will create A
                final b = bProvider.of(context);
                // Then access C, which should reuse A
                final c = cProvider.of(context);
                return Text('$b,$c');
              },
            ),
          ),
        ),
      ),
    );

    // Verify both providers work
    expect(find.text('2,3'), findsOneWidget);
    // Verify A was only created once (not twice)
    expect(creationCount, 1);
  });

  testWidgets('Mixed Provider and ArgProvider respect order', (tester) async {
    final numberProvider = Provider((_) => 5);
    final argProvider = Provider.withArgument(
      (context, String prefix) {
        final number = numberProvider.of(context);
        return '$prefix$number';
      },
    );
    final combineProvider = Provider((context) {
      final str = argProvider.of(context);
      return '$str!';
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              numberProvider(), // index 0
              argProvider('num:'), // index 1
              combineProvider(), // index 2
            ],
            child: Builder(
              builder: (context) {
                final result = combineProvider.of(context);
                return Text(result);
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('num:5!'), findsOneWidget);
  });

  testWidgets('Throws ProviderForwardReferenceError when ArgProvider '
      'accesses later Provider', (tester) async {
    final numberProvider = Provider<int>((_) => 5);
    final multiplierProvider = Provider.withArgument<int, int>(
      (context, int multiplier) {
        final number = numberProvider.of(context); // Forward reference!
        return number * multiplier;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            // Wrong order: multiplierProvider depends on numberProvider
            // but comes first
            providers: [multiplierProvider(3), numberProvider()],
            child: Builder(
              builder: (context) {
                multiplierProvider.of(context);
                return Container();
              },
            ),
          ),
        ),
      ),
    );

    // ArgProvider accessing a regular Provider throws
    // ProviderForwardReferenceError
    expect(
      tester.takeException(),
      const TypeMatcher<ProviderForwardReferenceError>(),
    );
  });

  testWidgets('Multiple lazy ArgProviders accessing same earlier provider '
      'reuses created value', (tester) async {
    // Similar to the Provider test, but for ArgProvider to ensure the
    // cached value path works for ArgProviders too.
    var creationCount = 0;
    final baseProvider = Provider.withArgument<int, int>((_, int arg) {
      creationCount++;
      return arg;
    });

    final doubleProvider = Provider.withArgument<int, int>((context, int arg) {
      final base = baseProvider.of(context);
      return base * 2;
    });

    final tripleProvider = Provider.withArgument<int, int>((context, int arg) {
      final base = baseProvider.of(context);
      return base * 3;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              baseProvider(5),
              doubleProvider(0),
              tripleProvider(0),
            ],
            child: Builder(
              builder: (context) {
                // Access double first, which will create base
                final double = doubleProvider.of(context);
                // Then access triple, which should reuse base
                final triple = tripleProvider.of(context);
                return Text('$double,$triple');
              },
            ),
          ),
        ),
      ),
    );

    // Verify both providers work
    expect(find.text('10,15'), findsOneWidget);
    // Verify base was only created once (not twice)
    expect(creationCount, 1);
  });

  testWidgets('Throws ProviderForwardReferenceError when accessing '
      'later ArgProvider', (tester) async {
    final secondArgProvider = Provider.withArgument<int, int>(
      (context, int arg) => arg * 2,
    );
    final firstArgProvider = Provider.withArgument<int, int>(
      (context, int arg) {
        final second = secondArgProvider.of(context); // Forward reference!
        return arg + second;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            // Wrong order: firstArgProvider depends on secondArgProvider
            // but comes first
            providers: [firstArgProvider(5), secondArgProvider(3)],
            child: Builder(
              builder: (context) {
                firstArgProvider.of(context);
                return Container();
              },
            ),
          ),
        ),
      ),
    );

    expect(
      tester.takeException(),
      const TypeMatcher<ProviderForwardReferenceError>(),
    );
  });

  // Circular dependency tests
  group('Circular dependency prevention', () {
    testWidgets(
      'Impossible: Direct circular dependency in same scope (A→B, B→A)',
      (tester) async {
        // This test demonstrates that circular dependencies are impossible
        // within the same scope due to forward reference errors.
        // Provider A tries to access Provider B, which comes later in the list,
        // resulting in a forward reference error.
        late final Provider<int> providerA;
        late final Provider<int> providerB;

        providerA = Provider<int>((context) {
          final b = providerB.of(context); // Forward reference to B!
          return b + 1;
        });

        providerB = Provider<int>((context) {
          // In a circular dependency, B would try to access A, but A comes
          // first so this wouldn't be a forward reference. However, A accessing
          // B is already a forward reference, so we never get here.
          return 10;
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProviderScope(
                providers: [providerA(), providerB()],
                child: Builder(
                  builder: (context) {
                    providerA.of(context);
                    return Container();
                  },
                ),
              ),
            ),
          ),
        );

        // A accessing B (which comes later) throws
        // ProviderForwardReferenceError
        expect(
          tester.takeException(),
          const TypeMatcher<ProviderForwardReferenceError>(),
        );
      },
    );

    testWidgets(
      'Impossible: ArgProvider circular dependency with regular Provider',
      (tester) async {
        // This test demonstrates that circular dependencies are also impossible
        // when mixing ArgProvider and regular Provider.
        late final Provider<int> providerA;
        late final ArgProvider<int, String> argProviderB;

        providerA = Provider<int>((context) {
          final b = argProviderB.of(context); // Forward reference!
          return b + 1;
        });

        argProviderB = Provider.withArgument<int, String>(
          (context, String arg) {
            // In a circular dependency, B would try to access A
            // But we never get here because A accessing B is already
            // a forward reference error.
            return 10;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProviderScope(
                providers: [providerA(), argProviderB('test')],
                child: Builder(
                  builder: (context) {
                    providerA.of(context);
                    return Container();
                  },
                ),
              ),
            ),
          ),
        );

        // A accessing B (which comes later) throws
        // ProviderForwardReferenceError
        expect(
          tester.takeException(),
          const TypeMatcher<ProviderForwardReferenceError>(),
        );
      },
    );
  });

  // Lifecycle and precedence of the overrides
  group('Overrides', () {
    testWidgets(
      '''The dispose of an overridden provider is the one of the mock''',
      (tester) async {
        var originalDisposed = false;
        var mockDisposed = false;

        final numberProvider = Provider<int>(
          (_) => 0,
          dispose: (_) {
            originalDisposed = true;
          },
        );
        final mockNumberProvider = Provider<int>(
          (_) => 9,
          dispose: (_) {
            mockDisposed = true;
          },
        );

        await tester.pumpWidget(
          ProviderScopeOverride(
            overrides: [
              numberProvider.overrideWith(mockNumberProvider),
            ],
            child: MaterialApp(
              home: ProviderScope(
                providers: [
                  numberProvider(),
                ],
                child: Builder(
                  builder: (context) {
                    return Text(numberProvider.of(context).toString());
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('9'), findsOneWidget);
        expect(mockDisposed, false);

        // Dispose the whole tree
        await tester.pumpWidget(Container());

        expect(mockDisposed, true);
        // The value of the original provider has never been created, therefore
        // its dispose is never called.
        expect(originalDisposed, false);
      },
    );

    testWidgets(
      '''An overridden argument provider is disposed by the ProviderScope providing it''',
      (tester) async {
        var originalDisposed = false;
        final disposedMockValues = <int>[];

        final numberProvider = Provider.withArgument<int, int>(
          (_, arg) => arg,
          dispose: (_) {
            originalDisposed = true;
          },
        );
        final mockNumberProvider = Provider.withArgument<int, int>(
          (_, arg) => arg + 100,
          dispose: disposedMockValues.add,
        );

        await tester.pumpWidget(
          ProviderScopeOverride(
            overrides: [
              numberProvider.overrideWith(mockNumberProvider),
            ],
            child: MaterialApp(
              home: ProviderScope(
                providers: [
                  numberProvider(1),
                ],
                child: Builder(
                  builder: (context) {
                    return Text(numberProvider.of(context).toString());
                  },
                ),
              ),
            ),
          ),
        );

        // The mock receives the argument specified in the widget tree.
        expect(find.text('101'), findsOneWidget);
        expect(disposedMockValues, isEmpty);

        // Dispose the whole tree
        await tester.pumpWidget(Container());

        expect(disposedMockValues, [101]);
        expect(originalDisposed, false);
      },
    );

    testWidgets(
      '''The value of an overridden provider is never created''',
      (tester) async {
        var originalCreated = false;

        final numberProvider = Provider<int>((_) {
          originalCreated = true;
          return 1;
        });
        final mockNumberProvider = Provider<int>((_) => 10);

        await tester.pumpWidget(
          ProviderScopeOverride(
            overrides: [
              numberProvider.overrideWith(mockNumberProvider),
            ],
            child: MaterialApp(
              home: ProviderScope(
                providers: [
                  numberProvider(),
                ],
                child: Builder(
                  builder: (context) {
                    return Text(numberProvider.of(context).toString());
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('10'), findsOneWidget);
        // Since every value is created lazily, and every injection resolves to
        // the mock, the original provider is never created at all.
        expect(originalCreated, false);
      },
    );

    testWidgets(
      '''A mock can inject the other providers of the widget tree''',
      (tester) async {
        final numberProvider = Provider<int>((_) => 1);
        final baseProvider = Provider<int>((_) => 100);
        // The mock is created lazily, therefore it can inject the providers
        // available where the overridden provider is injected.
        final mockNumberProvider = Provider<int>(
          (context) => baseProvider.of(context) + 5,
        );

        await tester.pumpWidget(
          ProviderScopeOverride(
            overrides: [
              numberProvider.overrideWith(mockNumberProvider),
            ],
            child: MaterialApp(
              home: ProviderScope(
                providers: [
                  baseProvider(),
                  numberProvider(),
                ],
                child: Builder(
                  builder: (context) {
                    return Text(numberProvider.of(context).toString());
                  },
                ),
              ),
            ),
          ),
        );

        expect(find.text('105'), findsOneWidget);
      },
    );

    testWidgets(
      '''An argument provider override does not affect the ProviderScopes above the ProviderScopeOverride''',
      (tester) async {
        final numberProvider = Provider<int>((_) => 0);
        final mockNumberProvider = Provider<int>((_) => 9);
        final numberArgProvider = Provider.withArgument<int, int>(
          (_, arg) => arg,
        );
        final mockNumberArgProvider = Provider.withArgument<int, int>(
          (_, arg) => arg + 100,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ProviderScope(
              providers: [
                numberProvider(),
                numberArgProvider(1),
              ],
              child: ProviderScopeOverride(
                overrides: [
                  numberProvider.overrideWith(mockNumberProvider),
                  numberArgProvider.overrideWith(mockNumberArgProvider),
                ],
                child: Builder(
                  builder: (context) {
                    final number = numberProvider.of(context);
                    final numberArg = numberArgProvider.of(context);
                    return Text('$number $numberArg');
                  },
                ),
              ),
            ),
          ),
        );

        // The provider without argument is overridden, since its value is
        // created and stored by the ProviderScope of the ProviderScopeOverride
        // itself, which always takes precedence.
        //
        // The argument provider is NOT overridden, since its intermediate
        // provider is generated by the ProviderScope providing it (the only
        // place where the argument is known), and that scope is an ancestor of
        // the ProviderScopeOverride, i.e. it cannot know about the overrides.
        expect(find.text('9 1'), findsOneWidget);
      },
    );
  });

  // Regression tests: when a provider is overridden, the providers *depending*
  // on it get the override as well, no matter which scope declares them.
  group('Overrides of dependencies', () {
    testWidgets(
      '''A provider injecting an overridden provider of the same scope gets the override''',
      (tester) async {
        final numberProvider = Provider<int>(
          (_) => 1,
          debugName: 'number',
        );
        final doubleNumberProvider = Provider<int>(
          (context) => numberProvider.of(context) * 2,
          debugName: 'doubleNumber',
        );
        final mockNumberProvider = Provider<int>((_) => 10);

        await tester.pumpWidget(
          ProviderScopeOverride(
            overrides: [
              numberProvider.overrideWith(mockNumberProvider),
            ],
            child: MaterialApp(
              home: ProviderScope(
                providers: [
                  numberProvider(),
                  doubleNumberProvider(),
                ],
                child: Builder(
                  builder: (context) {
                    final number = numberProvider.of(context);
                    final doubleNumber = doubleNumberProvider.of(context);
                    return Text('$number $doubleNumber');
                  },
                ),
              ),
            ),
          ),
        );

        // The widget gets the override (10), therefore the provider depending
        // on it gets 20 and not 2, i.e. it is created out of the override and
        // not out of the original provider.
        expect(find.text('10 20'), findsOneWidget);
      },
    );

    testWidgets(
      '''A provider injecting an overridden provider of an ANCESTOR scope gets the override''',
      (tester) async {
        final numberProvider = Provider<int>(
          (_) => 1,
          debugName: 'number',
        );
        final doubleNumberProvider = Provider<int>(
          (context) => numberProvider.of(context) * 2,
          debugName: 'doubleNumber',
        );
        final mockNumberProvider = Provider<int>((_) => 10);

        await tester.pumpWidget(
          ProviderScopeOverride(
            overrides: [
              numberProvider.overrideWith(mockNumberProvider),
            ],
            child: MaterialApp(
              home: ProviderScope(
                providers: [
                  numberProvider(),
                ],
                // The dependent provider is provided by another scope,
                // therefore the dependency is not resolved within the scope
                // creating it.
                child: ProviderScope(
                  providers: [
                    doubleNumberProvider(),
                  ],
                  child: Builder(
                    builder: (context) {
                      final number = numberProvider.of(context);
                      final doubleNumber = doubleNumberProvider.of(context);
                      return Text('$number $doubleNumber');
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        // The dependency belongs to another scope, which has always been
        // resolved through the widget tree.
        expect(find.text('10 20'), findsOneWidget);
      },
    );
  });
}
