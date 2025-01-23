import 'package:disco/disco.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

final a = Provider((context) => 9);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // todo: replace with more meaningful example
    return MaterialApp(
      home: Scaffold(
        body: ProviderScopeOverride(
          overrides: [
            a.overrideWith(lazy: true),
          ],
          child: const Text('hi'),
        ),
      ),
    );
  }
}
