import 'package:disco/disco.dart';
import 'package:flutter/material.dart';

abstract class Model extends ChangeNotifier {
  void incrementCounter();

  int get counter;
}

class ModelImplementation extends Model {
  int _counter = 0;

  @override
  int get counter => _counter;

  @override
  void incrementCounter() {
    _counter++;
    notifyListeners();
  }
}

final modelProvider = Provider<Model>((context) => ModelImplementation());

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
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
    // Provide the modelProvider to descendants
    return ProviderScope(
      providers: [modelProvider],
      // This builder gives a descendant context, only descendants can access
      // this scope
      child: Builder(
        builder: (context) {
          // retrieve the model
          final model = modelProvider.of(context);
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'You have pushed the button this many times:',
                  ),
                  // Rebuilds this widget when the model changes
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
              // increment the counter when the button is pressed
              onPressed: model.incrementCounter,
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }
}
