import 'package:disco/disco.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const InitializationPage());
}

final sharedPreferencesProvider = Provider.withArgument(
  (context, SharedPreferences prefs) => prefs,
);

class InitializationPage extends StatefulWidget {
  const InitializationPage({super.key});

  @override
  State<InitializationPage> createState() => _InitializationPageState();
}

class _InitializationPageState extends State<InitializationPage> {
  late final initialization = Future(() async {
    // Artificial delay to simulate loading
    await Future.delayed(Duration(seconds: 3));
    // Initialize shared preferences
    final prefs = await SharedPreferences.getInstance();
    return (preferences: prefs);
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }
        final data = snapshot.data!;
        return ProviderScope(
          providers: [
            sharedPreferencesProvider(data.preferences),
          ],
          child: MyApp(),
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final sharedPreferences = sharedPreferencesProvider.of(context);
    final counter = sharedPreferences.getInt('counter') ?? 0;
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Center(
          child: Text("The counter is $counter"),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              sharedPreferences.setInt('counter', counter + 1);
            });
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
