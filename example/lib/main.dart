import 'package:disco/disco.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const _MainApp());
}

class _MainApp extends StatelessWidget {
  const _MainApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body:
            ProviderScopeOverride(overrides: const [], child: const Text('hi')),
      ),
    );
  }
}
