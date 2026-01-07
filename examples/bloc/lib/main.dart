import 'package:bloc_example/di/providers.dart';
import 'package:bloc_example/ui/screens/theme_switcher_page.dart';
import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: [themeProvider],
      child: Builder(
        builder: (context) {
          return BlocBuilder(
            // NB: When injecting the cubit, the context has to be a descendant
            // of ProviderScope (and not what MyApp.build provides).
            bloc: themeProvider.of(context),
            builder: (context, bool isDarkMode) {
              return MaterialApp(
                theme: isDarkMode
                    ? ThemeData.dark().copyWith(primaryColor: Colors.blueGrey)
                    : ThemeData.light().copyWith(
                        primaryColor: Colors.lightBlue,
                      ),
                home: const ThemeSwitcherPage(),
              );
            },
          );
        },
      ),
    );
  }
}
