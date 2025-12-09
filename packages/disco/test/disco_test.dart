// NB: by importing disco/src/disco_internal.dart instead of disco/disco.dart,
// we can test components that are not exported.
import 'package:disco/src/disco_internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

abstract class NameContainer {
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
    final numberContainer2Provider =
        Provider((_) => const NumberContainer(100));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              numberContainer1Provider,
              numberContainer2Provider,
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
    final doubleCountProvider =
        Provider.withArgument((context, int arg) => arg * 2);

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

  testWidgets('Test Provider.withArgument not lazy', (tester) async {
    var fired = false;

    final doubleCountProvider = Provider.withArgument(
      (context, int arg) {
        fired = true;
        return arg * 2;
      },
      lazy: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [doubleCountProvider(3)],
            child: const Text('hello'),
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
            providers: [numberProvider],
            child: ProviderScope(
              providers: [doubleNumberProvider],
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

  testWidgets('Test ProviderScope throws an error for a not found provider',
      (tester) async {
    final zeroProvider = Provider((_) => 0);
    final tenProvider = Provider((_) => 10);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [zeroProvider],
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
  });

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
  });

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
            providers: [nameContainerProvider],
            child: Builder(
              builder: (context) {
                final numberContainer =
                    numberContainerProvider.maybeOf(context);
                return Text(numberContainer.toString());
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('null'), findsOneWidget);
  });

  testWidgets(
      '''Test ProviderScope throws if the same provider is provided multiple times''',
      (tester) async {
    final numberContainerProvider = Provider((_) => const NumberContainer(1));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              numberContainerProvider,
              numberContainerProvider,
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
  });

  testWidgets('Test provider injection', (tester) async {
    final NameContainer nameContainer = MockNameContainer('Ale');

    var fullNameContainerProviderDisposed = false;

    final numberContainer1Provider = Provider(
      (_) => const NumberContainer(1),
      lazy: false,
    );
    final numberContainer2Provider = Provider(
      (_) => const NumberContainer(100),
      lazy: false,
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
              nameContainerProvider,
              numberContainer1Provider,
              numberContainer2Provider,
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
            String value1, int value2, int value3, String value4) =>
        find.text('$value1 $value2 $value3 $value4');

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
                final numberContainer =
                    numberContainerProvider.of(innerContext);
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
            providers: [numberContainerProvider],
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
    final nameContainerProvider =
        Provider<NameContainer>((_) => MockNameContainer('name'));

    Future<void> showNumberDialog({required BuildContext context}) {
      return showDialog(
        context: context,
        builder: (dialogContext) {
          return ProviderScopePortal(
            mainContext: context,
            child: Builder(
              builder: (innerContext) {
                final numberContainer =
                    numberContainerProvider.of(innerContext);
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
            providers: [nameContainerProvider],
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
    final buttonFinder = find.text('show dialog');
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      const TypeMatcher<ProviderWithoutScopeError>(),
    );
  });

  testWidgets('Test ProviderScope inside ProviderScopePortal works',
      (tester) async {
    final numberContainerProvider = Provider(
      (_) => const NumberContainer(1),
    );

    final secondNumberContainerProvider = Provider(
      (_) => const NumberContainer(2),
    );

    final doubleCountProvider =
        Provider.withArgument((context, int arg) => arg * 2);

    Future<void> showNumberDialog({required BuildContext context}) {
      return showDialog(
        context: context,
        builder: (dialogContext) {
          return ProviderScopePortal(
            mainContext: context,
            child: ProviderScope(
              providers: [
                secondNumberContainerProvider,
                doubleCountProvider(3),
              ],
              child: Builder(
                builder: (innerContext) {
                  final numberContainer =
                      numberContainerProvider.of(innerContext);
                  final secondNumberContainer =
                      secondNumberContainerProvider.of(innerContext);
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
            providers: [numberContainerProvider],
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
    Finder number3Finder(int value, int value2, int value3) =>
        find.text('$value $value2 $value3');

    final buttonFinder = find.text('show dialog');
    expect(buttonFinder, findsOneWidget);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(number3Finder(1, 2, 6), findsOneWidget);
  });

  testWidgets(
      'ProviderScopePortal with lazy providers accessing '
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
            providers: [baseProvider, doubleProvider],
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

    final buttonFinder = find.text('show dialog');
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('Test key change in ProviderScope (with Provider)',
      (tester) async {
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
                providers: [numberProvider],
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

  testWidgets('Test key change in ProviderScope (with ArgProvider)',
      (tester) async {
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

  testWidgets('''ProviderScopeOverride should override providers''',
      (tester) async {
    final numberProvider = Provider<int>((_) => 0);
    await tester.pumpWidget(
      ProviderScopeOverride(
        overrides: [
          numberProvider.overrideWithValue(100),
        ],
        child: MaterialApp(
          home: ProviderScope(
            providers: [
              numberProvider,
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

  testWidgets('''ProviderScopeOverride should override argument providers''',
      (tester) async {
    final numberProvider = Provider.withArgument((_, int arg) => arg);
    await tester.pumpWidget(
      ProviderScopeOverride(
        overrides: [
          numberProvider.overrideWithValue(16),
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
    await tester.pumpWidget(
      ProviderScopeOverride(
        overrides: [
          numberProvider.overrideWithValue(100),
        ],
        child: MaterialApp(
          home: ProviderScopeOverride(
            overrides: [
              numberProvider.overrideWithValue(200),
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
  });

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
  });
  testWidgets(
      '''ProviderScopeOverride must throw a MultipleProviderOverrideOfSameProviderInstance for duplicated providers''',
      (tester) async {
    final numberProvider = Provider<int>((context) => 0);
    await tester.pumpWidget(
      ProviderScopeOverride(
        overrides: [
          numberProvider.overrideWithValue(1),
          numberProvider.overrideWithValue(2),
        ],
        child: const Text('hello'),
      ),
    );

    expect(
      tester.takeException(),
      const TypeMatcher<MultipleProviderOverrideOfSameInstance>(),
    );
  });

  testWidgets(
      '''Test ProviderScopeOverride throws MultipleProviderOfSameInstance for multiple instances of ArgProvider''',
      (tester) async {
    final numberProvider = Provider.withArgument((context, int arg) => arg);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScopeOverride(
            overrides: [
              numberProvider.overrideWithValue(1),
              numberProvider.overrideWithValue(2),
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
      const TypeMatcher<MultipleProviderOfSameInstance>(),
    );
  });

  // Same-scope provider access tests
  testWidgets('Provider can access earlier provider in same scope (non-lazy)',
      (tester) async {
    final numberProvider = Provider((_) => 5, lazy: false);
    final doubleProvider = Provider((context) {
      final number = numberProvider.of(context);
      return number * 2;
    }, lazy: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [numberProvider, doubleProvider],
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

  testWidgets('Throws ProviderForwardReferenceError on forward reference',
      (tester) async {
    final numberProvider = Provider<int>((_) => 5, lazy: false);
    final doubleProvider = Provider<int>((context) {
      final number = numberProvider.of(context); // Forward reference!
      return number * 2;
    }, lazy: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            // Wrong order: doubleProvider depends on numberProvider
            // but comes first
            providers: [doubleProvider, numberProvider],
            child: Container(),
          ),
        ),
      ),
    );

    expect(
      tester.takeException(),
      const TypeMatcher<ProviderForwardReferenceError>(),
    );
  });

  testWidgets('Lazy provider can access earlier lazy provider', (tester) async {
    final numberProvider = Provider((_) => 5);
    final doubleProvider = Provider((context) {
      final number = numberProvider.of(context);
      return number * 2;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [numberProvider, doubleProvider],
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

  testWidgets('Non-lazy provider can access lazy earlier provider',
      (tester) async {
    final numberProvider = Provider((_) => 5);
    final doubleProvider = Provider((context) {
      final number = numberProvider.of(context);
      return number * 2;
    }, lazy: false); // non-lazy

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [numberProvider, doubleProvider],
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

    // doubleProvider's creation should trigger numberProvider's creation
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('ArgProvider can access earlier provider in same scope',
      (tester) async {
    final numberProvider = Provider((_) => 5, lazy: false);
    final multiplierProvider = Provider.withArgument(
      (context, int multiplier) {
        final number = numberProvider.of(context);
        return number * multiplier;
      },
      lazy: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [numberProvider, multiplierProvider(3)],
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
    final aProvider = Provider((_) => 1, lazy: false);
    final bProvider =
        Provider((context) => aProvider.of(context) + 1, lazy: false);
    final cProvider =
        Provider((context) => bProvider.of(context) + 1, lazy: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [aProvider, bProvider, cProvider],
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

  testWidgets(
      'Multiple lazy providers accessing same earlier provider '
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
            providers: [aProvider, bProvider, cProvider],
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
    final numberProvider = Provider((_) => 5, lazy: false);
    final argProvider = Provider.withArgument(
      (context, String prefix) {
        final number = numberProvider.of(context);
        return '$prefix$number';
      },
      lazy: false,
    );
    final combineProvider = Provider((context) {
      final str = argProvider.of(context);
      return '$str!';
    }, lazy: false);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              numberProvider, // index 0
              argProvider('num:'), // index 1
              combineProvider, // index 2
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

  testWidgets(
      'Throws ProviderForwardReferenceError when ArgProvider '
      'accesses later Provider', (tester) async {
    final numberProvider = Provider<int>((_) => 5, lazy: false);
    final multiplierProvider = Provider.withArgument<int, int>(
      (context, int multiplier) {
        final number = numberProvider.of(context); // Forward reference!
        return number * multiplier;
      },
      lazy: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            // Wrong order: multiplierProvider depends on numberProvider
            // but comes first
            providers: [multiplierProvider(3), numberProvider],
            child: Container(),
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

  testWidgets(
      'Multiple lazy ArgProviders accessing same earlier provider '
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

  testWidgets(
      'Throws ProviderForwardReferenceError when accessing '
      'later ArgProvider', (tester) async {
    final secondArgProvider = Provider.withArgument<int, int>(
      (context, int arg) => arg * 2,
      lazy: false,
    );
    final firstArgProvider = Provider.withArgument<int, int>(
      (context, int arg) {
        final second = secondArgProvider.of(context); // Forward reference!
        return arg + second;
      },
      lazy: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            // Wrong order: firstArgProvider depends on secondArgProvider
            // but comes first
            providers: [firstArgProvider(5), secondArgProvider(3)],
            child: Container(),
          ),
        ),
      ),
    );

    expect(
      tester.takeException(),
      const TypeMatcher<ProviderForwardReferenceError>(),
    );
  });
}
