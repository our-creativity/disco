import 'package:auto_route_example/router.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

final _appRouter = AppRouter();

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _appRouter.config(
        includePrefixMatches: true,
      ),
    );
  }
}
