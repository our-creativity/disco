// ignore_for_file: avoid_print, cascade_invocations, lines_longer_than_80_chars, document_ignores

import 'dart:io';
import 'package:disco/disco.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Comprehensive benchmark suite for provider performance testing.
///
/// This benchmark tests various scenarios:
/// - Creating N simple providers (lazy and eager)
/// - Creating N providers with dependencies
/// - Retrieving provider values
/// - ArgProviders performance
/// - Nested scope performance

// Global map to store benchmark results
final Map<String, int> _benchmarkResults = {};

void main() {
  // Write results to file after all tests complete
  tearDownAll(_writeBenchmarkResults);

  group('Provider Benchmark', () {
    testWidgets('Benchmark: Create 100 simple eager providers', (tester) async {
      final stopwatch = Stopwatch()..start();

      final providers = List.generate(
        100,
        (i) => Provider(
          (_) => 'Value$i',
          lazy: false,
          debugName: 'provider$i',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: Container(),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Create 100 simple eager providers'] = time;
      print('Create 100 simple eager providers: ${time}ms');
    });

    testWidgets('Benchmark: Create 100 simple lazy providers', (tester) async {
      final stopwatch = Stopwatch()..start();

      final providers = List.generate(
        100,
        (i) => Provider(
          (_) => 'Value$i',
          lazy: true,
          debugName: 'provider$i',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: Container(),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Create 100 simple lazy providers'] = time;
      print('Create 100 simple lazy providers: ${time}ms');
    });

    testWidgets('Benchmark: Create 50 providers with dependencies',
        (tester) async {
      // Create a chain of providers where each depends on the previous one
      final providers = <Provider>[];

      // First provider has no dependencies
      providers.add(
        Provider(
          (_) => 0,
          lazy: false,
          debugName: 'provider0',
        ),
      );

      // Each subsequent provider depends on the previous one
      for (var i = 1; i < 50; i++) {
        providers.add(
          Provider(
            (context) {
              final prev = providers[i - 1].of(context) as int;
              return prev + 1;
            },
            lazy: false,
            debugName: 'provider$i',
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: Container(),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Create 50 providers with dependencies'] = time;
      print('Create 50 providers with dependencies: ${time}ms');
    });

    testWidgets('Benchmark: Retrieve 100 lazy provider values', (tester) async {
      final providers = List.generate(
        100,
        (i) => Provider(
          (_) => 'Value$i',
          lazy: true,
          debugName: 'provider$i',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: Builder(
              builder: (context) {
                final stopwatch = Stopwatch()..start();

                // Access all lazy providers to trigger creation
                for (final provider in providers) {
                  provider.of(context);
                }

                stopwatch.stop();
                final time = stopwatch.elapsedMilliseconds;
                _benchmarkResults['Retrieve 100 lazy provider values'] = time;
                print('Retrieve 100 lazy provider values: ${time}ms');

                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Benchmark: Create 100 ArgProviders', (tester) async {
      final argProviders = List.generate(
        100,
        (i) => Provider.withArgument<String, int>(
          (_, arg) => 'Value$i-$arg',
          lazy: false,
          debugName: 'argProvider$i',
        ),
      );

      final instantiated = argProviders.map((ap) => ap.call(42)).toList();

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: instantiated,
            child: Container(),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Create 100 ArgProviders'] = time;
      print('Create 100 ArgProviders: ${time}ms');
    });

    testWidgets('Benchmark: Access providers in nested scopes', (tester) async {
      final outerProviders = List.generate(
        50,
        (i) => Provider(
          (_) => 'Outer$i',
          lazy: false,
          debugName: 'outerProvider$i',
        ),
      );

      final innerProviders = List.generate(
        50,
        (i) => Provider(
          (_) => 'Inner$i',
          lazy: false,
          debugName: 'innerProvider$i',
        ),
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: outerProviders,
            child: ProviderScope(
              providers: innerProviders,
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

    testWidgets('Benchmark: Complex dependency chain with 30 providers',
        (tester) async {
      final providers = <Provider>[];

      // Create a more complex dependency pattern
      // Base providers (0-9)
      for (var i = 0; i < 10; i++) {
        providers.add(
          Provider(
            (_) => i,
            lazy: false,
            debugName: 'base$i',
          ),
        );
      }

      // Mid-level providers (10-19) - depend on base providers
      for (var i = 10; i < 20; i++) {
        providers.add(
          Provider(
            (context) {
              final base1 = providers[i - 10].of(context) as int;
              final base2 = providers[i - 9].of(context) as int;
              return base1 + base2;
            },
            lazy: false,
            debugName: 'mid$i',
          ),
        );
      }

      // Top-level providers (20-29) - depend on mid-level providers
      for (var i = 20; i < 30; i++) {
        providers.add(
          Provider(
            (context) {
              final mid1 = providers[i - 10].of(context) as int;
              final mid2 = providers[i - 9].of(context) as int;
              return mid1 + mid2;
            },
            lazy: false,
            debugName: 'top$i',
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: Container(),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Complex dependency chain (30 providers)'] = time;
      print('Complex dependency chain with 30 providers: ${time}ms');
    });

    testWidgets('Benchmark: Mixed lazy and eager providers (100 total)',
        (tester) async {
      final providers = <Provider>[];

      // 50 eager providers
      for (var i = 0; i < 50; i++) {
        providers.add(
          Provider(
            (_) => 'Eager$i',
            lazy: false,
            debugName: 'eager$i',
          ),
        );
      }

      // 50 lazy providers
      for (var i = 50; i < 100; i++) {
        providers.add(
          Provider(
            (_) => 'Lazy$i',
            lazy: true,
            debugName: 'lazy$i',
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: Container(),
          ),
        ),
      );

      stopwatch.stop();
      final time = stopwatch.elapsedMilliseconds;
      _benchmarkResults['Mixed lazy and eager (100 total)'] = time;
      print('Mixed lazy and eager providers (100 total): ${time}ms');
    });

    testWidgets('Benchmark: ArgProviders with dependencies', (tester) async {
      final providers = <InstantiableProvider>[];

      // Base provider
      final baseProvider = Provider<int>(
        (_) => 10,
        lazy: false,
        debugName: 'base',
      );
      providers.add(baseProvider);

      // ArgProviders that depend on base
      for (var i = 0; i < 50; i++) {
        final argProvider = Provider.withArgument<int, int>(
          (context, arg) {
            final base = baseProvider.of(context);
            return base + arg + i;
          },
          lazy: false,
          debugName: 'argProvider$i',
        );
        providers.add(argProvider.call(i));
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: Container(),
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
          lazy: i.isOdd, // Alternate between lazy and eager
          debugName: 'provider$i',
        ),
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: Container(),
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
      final providers = <Provider>[];

      providers.add(
        Provider(
          (_) => 0,
          lazy: false,
          debugName: 'provider0',
        ),
      );

      for (var i = 1; i < 100; i++) {
        providers.add(
          Provider(
            (context) {
              final prev = providers[i - 1].of(context) as int;
              return prev + 1;
            },
            lazy: false,
            debugName: 'provider$i',
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: Container(),
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
            providers: providers,
            child: Builder(
              builder: (context) {
                final lastValue = providers.last.of(context) as int;
                expect(lastValue, 99);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('Stress: Wide dependency tree (base + 100 dependents)',
        (tester) async {
      final providers = <Provider>[];

      final baseProvider = Provider<int>(
        (_) => 42,
        lazy: false,
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
            lazy: false,
            debugName: 'dependent$i',
          ),
        );
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: Container(),
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
          lazy: false,
          debugName: 'provider$i',
        ),
      );

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            providers: providers,
            child: ProviderScope(
              providers: providers,
              child: ProviderScope(
                providers: providers,
                child: ProviderScope(
                  providers: providers,
                  child: ProviderScope(
                    providers: providers,
                    child: Container(),
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
      '**Date**: ${DateTime.now().toUtc().toString().split('.')[0]} UTC');
  buffer.writeln();
  buffer.writeln('## Results');
  buffer.writeln();
  buffer.writeln('| Benchmark | Time (ms) |');
  buffer.writeln('|-----------|-----------|');

  // Write results in the expected order
  final orderedKeys = [
    'Create 100 simple eager providers',
    'Create 100 simple lazy providers',
    'Create 50 providers with dependencies',
    'Retrieve 100 lazy provider values',
    'Create 100 ArgProviders',
    'Access 100 providers in nested scopes',
    'Complex dependency chain (30 providers)',
    'Mixed lazy and eager (100 total)',
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
