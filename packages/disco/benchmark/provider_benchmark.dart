// ignore_for_file: avoid_print, cascade_invocations, lines_longer_than_80_chars, document_ignores

import 'dart:io';
import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Comprehensive benchmark suite for provider performance testing.
///
/// The value of a provider is always created lazily, i.e. the first time it is
/// injected. Therefore the benchmarks distinguish between:
/// - registering the providers, which is what mounting a ProviderScope does;
/// - creating their values, which is what injecting them does.
///
/// This benchmark tests various scenarios:
/// - Registering N providers
/// - Creating the values of N providers
/// - Creating N values with dependencies
/// - ArgProviders performance
/// - Nested scope performance

// Global map to store benchmark results
final Map<String, int> _benchmarkResults = {};

/// Instantiates all the [providers], so that they can be inserted into a
/// [ProviderScope].
List<ValueBinding> _instantiateAll(
  Iterable<Provider<Object>> providers,
) => [for (final provider in providers) provider()];

/// A widget which injects all the [providers], so that their values are
/// created.
class _InjectAll extends StatelessWidget {
  const _InjectAll(this.providers);

  final Iterable<Provider<Object>> providers;

  @override
  Widget build(BuildContext context) {
    for (final provider in providers) {
      provider.of(context);
    }
    return Container();
  }
}

void main() {
  // Write results to file after all tests complete
  tearDownAll(_writeBenchmarkResults);

  group('Provider Benchmark', () {
    testWidgets('Benchmark: Register 100 providers', (tester) async {
      final stopwatch = Stopwatch()..start();

      final providers = List.generate(
        100,
        (i) => Provider(
          (_) => 'Value$i',
          debugName: 'provider$i',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: _instantiateAll(providers),
            // No value is created, since nothing is injected.
            child: Container(),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Register 100 providers'] = time;
      print('Register 100 providers: ${time}ms');
    });

    testWidgets('Benchmark: Create 100 provider values', (tester) async {
      final stopwatch = Stopwatch()..start();

      final providers = List.generate(
        100,
        (i) => Provider(
          (_) => 'Value$i',
          debugName: 'provider$i',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: _instantiateAll(providers),
            child: _InjectAll(providers),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Create 100 provider values'] = time;
      print('Create 100 provider values: ${time}ms');
    });

    testWidgets('Benchmark: Create 50 values with dependencies', (
      tester,
    ) async {
      // Create a chain of providers where each depends on the previous one
      final providers = <Provider<int>>[];

      // First provider has no dependencies
      providers.add(
        Provider(
          (_) => 0,
          debugName: 'provider0',
        ),
      );

      // Each subsequent provider depends on the previous one
      for (var i = 1; i < 50; i++) {
        providers.add(
          Provider(
            (context) {
              final prev = providers[i - 1].of(context);
              return prev + 1;
            },
            debugName: 'provider$i',
          ),
        );
      }

      final instantiatedProviders = _instantiateAll(providers);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: instantiatedProviders,
            // Injecting the last provider creates the whole chain.
            child: _InjectAll([providers.last]),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Create 50 values with dependencies'] = time;
      print('Create 50 values with dependencies: ${time}ms');
    });

    testWidgets('Benchmark: Retrieve 100 provider values', (tester) async {
      final providers = List.generate(
        100,
        (i) => Provider(
          (_) => 'Value$i',
          debugName: 'provider$i',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: _instantiateAll(providers),
            child: Builder(
              builder: (context) {
                final stopwatch = Stopwatch()..start();

                // Access all providers to trigger creation
                for (final provider in providers) {
                  provider.of(context);
                }

                stopwatch.stop();
                final time = stopwatch.elapsedMilliseconds;
                _benchmarkResults['Retrieve 100 provider values'] = time;
                print('Retrieve 100 provider values: ${time}ms');

                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Benchmark: Create 100 ArgProvider values', (tester) async {
      final argProviders = List.generate(
        100,
        (i) => Provider.withArgument<String, int>(
          (_, arg) => 'Value$i-$arg',
          debugName: 'argProvider$i',
        ),
      );

      final instantiated = argProviders.map((ap) => ap.call(42)).toList();

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: instantiated,
            child: Builder(
              builder: (context) {
                for (final argProvider in argProviders) {
                  argProvider.of(context);
                }
                return Container();
              },
            ),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Create 100 ArgProvider values'] = time;
      print('Create 100 ArgProvider values: ${time}ms');
    });

    testWidgets('Benchmark: Access providers in nested scopes', (tester) async {
      final outerProviders = List.generate(
        50,
        (i) => Provider(
          (_) => 'Outer$i',
          debugName: 'outerProvider$i',
        ),
      );

      final innerProviders = List.generate(
        50,
        (i) => Provider(
          (_) => 'Inner$i',
          debugName: 'innerProvider$i',
        ),
      );

      final instantiatedOuterProviders = _instantiateAll(outerProviders);
      final instantiatedInnerProviders = _instantiateAll(innerProviders);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: instantiatedOuterProviders,
            child: ProviderScope(
              providers: instantiatedInnerProviders,
              child: Builder(
                builder: (context) {
                  // Access outer providers from inner scope
                  for (final provider in outerProviders) {
                    provider.of(context);
                  }
                  // Access inner providers
                  for (final provider in innerProviders) {
                    provider.of(context);
                  }
                  return Container();
                },
              ),
            ),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Access 100 providers in nested scopes'] = time;
      print('Access 100 providers in nested scopes: ${time}ms');
    });

    testWidgets('Benchmark: Complex dependency chain with 30 providers', (
      tester,
    ) async {
      final providers = <Provider<int>>[];

      // Create a more complex dependency pattern
      // Base providers (0-9)
      for (var i = 0; i < 10; i++) {
        providers.add(
          Provider(
            (_) => i,
            debugName: 'base$i',
          ),
        );
      }

      // Mid-level providers (10-19) - depend on base providers
      for (var i = 10; i < 20; i++) {
        providers.add(
          Provider(
            (context) {
              final base1 = providers[i - 10].of(context);
              final base2 = providers[i - 9].of(context);
              return base1 + base2;
            },
            debugName: 'mid$i',
          ),
        );
      }

      // Top-level providers (20-29) - depend on mid-level providers
      for (var i = 20; i < 30; i++) {
        providers.add(
          Provider(
            (context) {
              final mid1 = providers[i - 10].of(context);
              final mid2 = providers[i - 9].of(context);
              return mid1 + mid2;
            },
            debugName: 'top$i',
          ),
        );
      }

      final instantiatedProviders = _instantiateAll(providers);
      // Injecting the top-level providers creates all the others.
      final topProviders = providers.sublist(20);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: instantiatedProviders,
            child: _InjectAll(topProviders),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Complex dependency chain (30 providers)'] = time;
      print('Complex dependency chain with 30 providers: ${time}ms');
    });

    testWidgets('Benchmark: ArgProviders with dependencies', (tester) async {
      final providers = <ValueBinding>[];
      final argProviders = <ArgProvider<int, int>>[];

      // Base provider
      final baseProvider = Provider<int>(
        (_) => 10,
        debugName: 'base',
      );
      providers.add(baseProvider());

      // ArgProviders that depend on base
      for (var i = 0; i < 50; i++) {
        final argProvider = Provider.withArgument<int, int>(
          (context, arg) {
            final base = baseProvider.of(context);
            return base + arg + i;
          },
          debugName: 'argProvider$i',
        );
        argProviders.add(argProvider);
        providers.add(argProvider.call(i));
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: Builder(
              builder: (context) {
                for (final argProvider in argProviders) {
                  argProvider.of(context);
                }
                return Container();
              },
            ),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['ArgProviders with dependencies (50)'] = time;
      print('ArgProviders with dependencies (50): ${time}ms');
    });

    testWidgets('Benchmark: Large scale - 500 providers', (tester) async {
      final providers = List.generate(
        500,
        (i) => Provider(
          (_) => 'Value$i',
          debugName: 'provider$i',
        ),
      );

      final instantiatedProviders = _instantiateAll(providers);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: instantiatedProviders,
            child: _InjectAll(providers),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Large scale (500 providers)'] = time;
      print('Large scale - 500 providers: ${time}ms');
    });
  });

  group('Provider Benchmark - Stress Tests', () {
    testWidgets('Stress: Deep dependency chain (100 levels)', (tester) async {
      final providers = <Provider<int>>[];

      providers.add(
        Provider(
          (_) => 0,
          debugName: 'provider0',
        ),
      );

      for (var i = 1; i < 100; i++) {
        providers.add(
          Provider(
            (context) {
              final prev = providers[i - 1].of(context);
              return prev + 1;
            },
            debugName: 'provider$i',
          ),
        );
      }

      final instantiatedProviders = _instantiateAll(providers);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: instantiatedProviders,
            child: _InjectAll([providers.last]),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Deep dependency chain (100 levels)'] = time;
      print('Deep dependency chain (100 levels): ${time}ms');

      // Verify the final value is correct
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: instantiatedProviders,
            child: Builder(
              builder: (context) {
                final lastValue = providers.last.of(context);
                expect(lastValue, 99);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Stress: Wide dependency tree (base + 100 dependents)', (
      tester,
    ) async {
      final providers = <Provider<int>>[];

      final baseProvider = Provider<int>(
        (_) => 42,
        debugName: 'base',
      );
      providers.add(baseProvider);

      for (var i = 1; i <= 100; i++) {
        providers.add(
          Provider(
            (context) {
              final base = baseProvider.of(context);
              return base + i;
            },
            debugName: 'dependent$i',
          ),
        );
      }

      final instantiatedProviders = _instantiateAll(providers);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: instantiatedProviders,
            child: _InjectAll(providers),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Wide dependency tree (100 dependents)'] = time;
      print('Wide dependency tree (base + 100 dependents): ${time}ms');
    });

    testWidgets('Stress: Multiple nested scopes (5 levels)', (tester) async {
      final providers = List.generate(
        20,
        (i) => Provider(
          (_) => 'Value$i',
          debugName: 'provider$i',
        ),
      );

      final instantiatedProviders = _instantiateAll(providers);

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: instantiatedProviders,
            child: ProviderScope(
              providers: instantiatedProviders,
              child: ProviderScope(
                providers: instantiatedProviders,
                child: ProviderScope(
                  providers: instantiatedProviders,
                  child: ProviderScope(
                    providers: instantiatedProviders,
                    child: _InjectAll(providers),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Multiple nested scopes (5 levels)'] = time;
      print('Multiple nested scopes (5 levels, 20 providers each): ${time}ms');
    });
  });
}

/// Writes benchmark results to a markdown file
void _writeBenchmarkResults() {
  final buffer = StringBuffer();

  buffer.writeln('# Provider Benchmark Results');
  buffer.writeln();
  buffer.writeln(
    '**Date**: ${DateTime.now().toUtc().toString().split('.')[0]} UTC',
  );
  buffer.writeln();
  buffer.writeln('## Results');
  buffer.writeln();
  buffer.writeln('| Benchmark | Time (ms) |');
  buffer.writeln('|-----------|-----------|');

  // Write results in the expected order
  final orderedKeys = [
    'Register 100 providers',
    'Create 100 provider values',
    'Create 50 values with dependencies',
    'Retrieve 100 provider values',
    'Create 100 ArgProvider values',
    'Access 100 providers in nested scopes',
    'Complex dependency chain (30 providers)',
    'ArgProviders with dependencies (50)',
    'Large scale (500 providers)',
    'Deep dependency chain (100 levels)',
    'Wide dependency tree (100 dependents)',
    'Multiple nested scopes (5 levels)',
  ];

  for (final key in orderedKeys) {
    final time = _benchmarkResults[key];
    buffer.writeln('| $key | ${time ?? 'N/A'} |');
  }

  // Write to file
  final file = File('benchmark_results.md');
  file.writeAsStringSync(buffer.toString());
  print('\n✓ Benchmark results written to: ${file.absolute.path}');
}
