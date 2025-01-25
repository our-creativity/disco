import 'package:bloc_example/ui/widgets/themed_button.dart';
import 'package:flutter/material.dart';

class ThemeSwitcherPage extends StatelessWidget {
  const ThemeSwitcherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cubit Theme Example')),
      body: const Center(
        child: ThemedButton(),
      ),
    );
  }
}
