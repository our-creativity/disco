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
