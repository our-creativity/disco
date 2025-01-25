import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

// ThemeCubit manages the light/dark theme state
class ThemeCubit extends Cubit<bool> {
  // false means Light theme, true means Dark theme
  ThemeCubit() : super(false);

  static final themeProvider = Provider((_) => ThemeCubit());

  void toggleTheme() => emit(!state);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: [ThemeCubit.themeProvider],
      child: Builder(
        builder: (context) => BlocBuilder(
          // NB: When injecting the cubit, the context has to be a descendant
          // of ProviderScope (and not what MyApp.build provides).
          bloc: ThemeCubit.themeProvider.of(context),
          builder: (context, bool isDarkMode) {
            return MaterialApp(
              theme: isDarkMode
                  ? ThemeData.dark().copyWith(primaryColor: Colors.blueGrey)
                  : ThemeData.light().copyWith(primaryColor: Colors.lightBlue),
              home: const ThemeSwitcherPage(),
            );
          },
        ),
      ),
    );
  }
}

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

class ThemedButton extends StatelessWidget {
  const ThemedButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = ThemeCubit.themeProvider.of(context);
    return BlocBuilder(
      bloc: themeCubit,
      builder: (context, bool isDarkMode) => ElevatedButton(
        onPressed: themeCubit.toggleTheme,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.lightBlue,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
