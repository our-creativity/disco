import 'package:bloc_example/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemedButton extends StatelessWidget {
  const ThemedButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = themeProvider.of(context);
    return BlocBuilder(
      bloc: themeCubit,
      builder: (context, bool isDarkMode) {
        return ElevatedButton(
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
        );
      },
    );
  }
}
