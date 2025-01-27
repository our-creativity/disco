import 'package:auto_route/auto_route.dart';
import 'package:auto_route_example/router.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Go to books'),
          onPressed: () => context.router.root.navigate(const BooksRoute()),
        ),
      ),
    );
  }
}
