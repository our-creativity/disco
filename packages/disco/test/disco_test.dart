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
      '''Test ProviderScope throws ArgProviderWithoutScopeError for a not found ArgProvider''',
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
      const TypeMatcher<ArgProviderWithoutScopeError>().having(
        (error) => error.argProvider,
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProviderScope(
            providers: [
              nameContainerProvider,
              numberContainer1Provider,
              numberContainer2Provider,
            ],
            child: Builder(
              builder: (context) {
                final nameContainer = nameContainerProvider.of(context);
                final numberContainer1 = numberContainer1Provider.of(context);
                final numberContainer2 = numberContainer2Provider.of(context);
                return Text(
                  '''${nameContainer.name} ${numberContainer1.number} ${numberContainer2.number}''',
                );
              },
            ),
          ),
        ),
      ),
    );
    Finder providerFinder(String value1, int value2, int value3) =>
        find.text('$value1 $value2 $value3');

    expect(providerFinder('Ale', 1, 100), findsOneWidget);

    // mock NameProvider dispose method
    when(nameContainer.dispose()).thenReturn(null);
    // Push a different widget
    await tester.pumpWidget(Container());
    // check dispose has been called on NameProvider
    verify(nameContainer.dispose()).called(1);
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

  testWidgets(
      '''ProviderScopeOverride should override providers regardless of the hierarchy''',
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

  testWidgets(
      '''ProviderScopeOverride should override argument providers regardless of the hierarchy''',
      (tester) async {
    final numberProvider = Provider.withArgument((_, int arg) => arg);
    await tester.pumpWidget(
      ProviderScopeOverride(
        overrides: [
          numberProvider.overrideWithValue(8 * 2),
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
      const TypeMatcher<MultipleProviderOverrideOfSameProviderInstance>(),
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
}
