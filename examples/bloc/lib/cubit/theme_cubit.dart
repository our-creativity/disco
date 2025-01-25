import 'package:flutter_bloc/flutter_bloc.dart';

/// ThemeCubit manages the light/dark theme state
class ThemeCubit extends Cubit<bool> {
  ThemeCubit() : super(false); // false means light, true means dark theme

  void toggleTheme() => emit(!state);
}
