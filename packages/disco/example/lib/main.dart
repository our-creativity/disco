import 'package:disco/disco.dart';
import 'package:example/model.dart';
import 'package:flutter/material.dart';

final modelProvider = Provider<Model>((context) => ModelImplementation());

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // todo: replace with more meaningful example
    return MaterialApp(
      title: 'Disco Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: [modelProvider],
      // This builder gives a descendant context, only descendants can access
      // this scope
      child: Builder(
        builder: (context) {
          // retrieve the model
          final model = modelProvider.get(context);
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'You have pushed the button this many times:',
                  ),
                  ListenableBuilder(
                    listenable: model,
                    builder: (context, child) {
                      return Text(model.counter.toString());
                    },
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: model.incrementCounter,
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
