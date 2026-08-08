// The example catches an Error on purpose, in order to show the message of a
// ProviderWithoutScopeError in the UI (see ErrorsPage).
// ignore_for_file: avoid_catching_errors

import 'package:disco/disco.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/// Collects the messages logged while the values of the providers get created
/// and disposed, so that their lifecycle is visible in the UI.
class Logger extends ChangeNotifier {
  final List<String> _messages = [];
  bool _disposed = false;

  List<String> get messages => List.unmodifiable(_messages);

  void log(String message) {
    _messages.add(message);
    // The value of a lazy provider is created while the widget tree is being
    // built, and disposed while it is being unmounted. Notifying the listeners
    // right away would rebuild widgets during a build, which is not allowed by
    // Flutter. Therefore, the notification is postponed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) notifyListeners();
    });
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

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

/// A value built out of an argument (see [userProvider]).
class User {
  const User({required this.id, required this.name});

  final String id;
  final String name;
}

/// A value which needs an argument, another provider and a disposal
/// (see [cartProvider]).
class Cart extends ChangeNotifier {
  Cart({required Logger logger, required int itemCount})
    : _logger = logger,
      _itemCount = itemCount;

  final Logger _logger;
  int _itemCount;

  int get itemCount => _itemCount;

  void addItem() {
    _itemCount++;
    _logger.log('Cart: item added, $_itemCount in total');
    notifyListeners();
  }

  @override
  void dispose() {
    _logger.log('Cart disposed');
    super.dispose();
  }
}

/// A value which depends on another provider of the same scope
/// (see [analyticsProvider]).
class Analytics {
  const Analytics(this._logger);

  final Logger _logger;

  void track(String event) => _logger.log('Analytics: $event');
}

// ---------------------------------------------------------------------------
// Providers
//
// Providers are declared at the top level, but they do not hold any state:
// they are only used as type-safe identifiers. The values are created and
// stored by the ProviderScope which provides them.
// ---------------------------------------------------------------------------

/// A plain provider. Its value is created lazily, i.e. the first time it gets
/// injected.
final modelProvider = Provider<Model>(
  (context) => ModelImplementation(),
  debugName: 'model',
);

/// A provider with a `dispose` callback: its value is disposed when the
/// ProviderScope providing it is unmounted.
///
/// See [MainApp] for how its value is created as soon as the app starts.
final loggerProvider = Provider<Logger>(
  (context) => Logger()..log('Logger created'),
  dispose: (logger) => logger.dispose(),
  debugName: 'logger',
);

/// A provider depending on another provider of the **same** scope. The order in
/// which the two are declared in the `providers` list does not matter, as long
/// as they do not depend on each other (which would be a
/// `ProviderCircularDependencyError`).
final analyticsProvider = Provider<Analytics>(
  (context) {
    final logger = loggerProvider.of(context);
    logger.log('Analytics created lazily');
    return Analytics(logger);
  },
  debugName: 'analytics',
);

/// A provider which needs an argument.
final userProvider = Provider.withArgument<User, String>(
  (context, id) {
    loggerProvider.of(context).log('User $id created');
    return User(id: id, name: 'User $id');
  },
  debugName: 'user',
);

/// An argument provider which injects a provider of an **ancestor** scope and
/// disposes its value.
final cartProvider = Provider.withArgument<Cart, int>(
  (context, initialItemCount) {
    final logger = loggerProvider.of(context);
    logger.log('Cart created with $initialItemCount item(s)');
    return Cart(logger: logger, itemCount: initialItemCount);
  },
  dispose: (cart) => cart.dispose(),
  debugName: 'cart',
);

/// Provided by two nested scopes with different arguments, to show that the
/// nearest scope wins.
// ignore: specify_nonobvious_property_types
final labelProvider = Provider.withArgument<String, String>(
  (context, label) => label,
  debugName: 'label',
);

/// Deliberately never inserted into any ProviderScope, to show the difference
/// between `of` and `maybeOf`.
final missingProvider = Provider<String>(
  (context) => 'unreachable',
  debugName: 'missing',
);

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Application-wide scope: the logger, and the analytics depending on it,
    // live as long as the app does.
    return ProviderScope(
      providers: [
        loggerProvider(),
        // NB: `analyticsProvider` injects `loggerProvider`, therefore it has
        // to be declared after it.
        analyticsProvider(),
      ],
      // The values of the providers are always created lazily. Injecting the
      // logger right below the scope creates it as soon as the app starts:
      // this is the recommended way of initializing a value eagerly.
      child: Builder(
        builder: (context) {
          loggerProvider.of(context);
          return MaterialApp(
            title: 'Disco Example',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}

/// Shows a counter provided by a page-scoped provider, plus a list of the
/// other demos.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // The counter is scoped to this page: it is created when the page is
    // shown and disposed when the page is removed.
    return ProviderScope(
      providers: [modelProvider()],
      // This builder gives a descendant context, only descendants can access
      // this scope
      child: Builder(
        builder: (context) {
          // retrieve the model
          final model = modelProvider.of(context);
          return Scaffold(
            appBar: AppBar(title: const Text('Disco example')),
            body: Column(
              children: [
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      _DemoTile(
                        title: 'Providers with arguments',
                        subtitle: 'Provider.withArgument and dispose',
                        pageBuilder: (context) => const ArgumentsPage(),
                      ),
                      _DemoTile(
                        title: 'Nested scopes',
                        subtitle: 'The nearest scope wins',
                        pageBuilder: (context) => const NestedScopesPage(),
                      ),
                      _DemoTile(
                        title: 'Modals',
                        subtitle: 'ProviderScopePortal',
                        pageBuilder: (context) => const ModalsPage(),
                      ),
                      _DemoTile(
                        title: 'Lazy creation',
                        subtitle: 'When the values get created',
                        pageBuilder: (context) => const LazinessPage(),
                      ),
                      _DemoTile(
                        title: 'Recreating a scope',
                        subtitle: 'Changing the key of a ProviderScope',
                        pageBuilder: (context) => const ScopeKeyPage(),
                      ),
                      _DemoTile(
                        title: 'Missing providers',
                        subtitle: 'of versus maybeOf',
                        pageBuilder: (context) => const ErrorsPage(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 140, child: LogPanel()),
              ],
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

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.title,
    required this.subtitle,
    required this.pageBuilder,
  });

  final String title;
  final String subtitle;
  final WidgetBuilder pageBuilder;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // `analyticsProvider` is lazy: its value is created here, the very
        // first time it gets injected.
        analyticsProvider.of(context).track('opened "$title"');
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: pageBuilder),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Demos
// ---------------------------------------------------------------------------

/// Shows two argument providers, one of which injects a provider of an
/// ancestor scope and gets disposed together with this page.
class ArgumentsPage extends StatelessWidget {
  const ArgumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      // The argument is given where the provider is inserted into the tree.
      providers: [
        userProvider('42'),
        cartProvider(2),
      ],
      child: Builder(
        builder: (context) {
          final user = userProvider.of(context);
          final cart = cartProvider.of(context);
          return Scaffold(
            appBar: AppBar(
              title: const Text('Providers with arguments'),
            ),
            body: Column(
              children: [
                ListTile(
                  title: const Text('Injected user'),
                  subtitle: Text('${user.name}, id ${user.id}'),
                ),
                ListenableBuilder(
                  listenable: cart,
                  builder: (context, child) {
                    return ListTile(
                      title: const Text('Items in the cart'),
                      subtitle: Text(cart.itemCount.toString()),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: cart.addItem,
                    child: const Text('Add an item'),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Go back: the cart is disposed together with this page, '
                    'while the logger of the app-wide scope survives.',
                  ),
                ),
                const Divider(height: 1),
                const Expanded(child: LogPanel()),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shows that, when two scopes provide the same provider, the nearest one
/// wins.
class NestedScopesPage extends StatelessWidget {
  const NestedScopesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nested scopes')),
      body: ProviderScope(
        providers: [labelProvider('outer scope')],
        child: Column(
          children: [
            Builder(
              builder: (context) {
                return ListTile(
                  title: const Text('Injected between the two scopes'),
                  subtitle: Text(labelProvider.of(context)),
                );
              },
            ),
            ProviderScope(
              providers: [labelProvider('inner scope')],
              child: Builder(
                builder: (context) {
                  return ListTile(
                    title: const Text('Injected below the inner scope'),
                    subtitle: Text(labelProvider.of(context)),
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'The injection walks up the widget tree and stops at the '
                'first ProviderScope providing the requested provider.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows that a modal is spawned in a new widget tree, and how
/// [ProviderScopePortal] gives it access to the providers of the main tree.
class ModalsPage extends StatelessWidget {
  const ModalsPage({super.key});

  Future<void> _showDialogWithPortal(BuildContext mainContext) {
    return showDialog<void>(
      context: mainContext,
      builder: (dialogContext) {
        return ProviderScopePortal(
          // The context of the main tree, i.e. a descendant of the scope
          // providing `userProvider`.
          mainContext: mainContext,
          child: Builder(
            builder: (context) {
              final user = userProvider.of(context);
              return _DemoDialog(
                title: 'With ProviderScopePortal',
                content: 'Injected: ${user.name}',
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showDialogWithoutPortal(BuildContext mainContext) {
    return showDialog<void>(
      context: mainContext,
      builder: (dialogContext) {
        // `maybeOf` returns null: the scope of this page is not an ancestor of
        // the dialog. Note that `of` would throw a ProviderWithoutScopeError.
        final user = userProvider.maybeOf(dialogContext);
        return _DemoDialog(
          title: 'Without ProviderScopePortal',
          content: 'Injected: ${user?.name ?? 'null'}',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: [userProvider('7')],
      child: Scaffold(
        appBar: AppBar(title: const Text('Modals')),
        body: Builder(
          builder: (context) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'A modal is spawned in a new widget tree: only the '
                    'Navigator is a common ancestor. The providers of this '
                    'page are therefore not reachable from a dialog, unless a '
                    'ProviderScopePortal is used.',
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showDialogWithPortal(context),
                  child: const Text('Show a dialog with the portal'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showDialogWithoutPortal(context),
                  child: const Text('Show a dialog without the portal'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DemoDialog extends StatelessWidget {
  const _DemoDialog({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Shows when the value of a provider gets created.
class LazinessPage extends StatelessWidget {
  const LazinessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lazy creation')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'The value of a provider is created the first time it gets '
              'injected, and never before. The logger was created at startup '
              'only because MainApp injects it right below the app-wide '
              'scope. The analytics were created later, the first time a demo '
              'was opened from the list.',
            ),
          ),
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  analyticsProvider.of(context).track('button pressed');
                },
                child: const Text('Inject the analytics again'),
              );
            },
          ),
          const Divider(height: 1),
          const Expanded(child: LogPanel()),
        ],
      ),
    );
  }
}

/// Shows how to force the recreation of the value of a provider, by changing
/// the key of the [ProviderScope] providing it.
class ScopeKeyPage extends StatefulWidget {
  const ScopeKeyPage({super.key});

  @override
  State<ScopeKeyPage> createState() => _ScopeKeyPageState();
}

class _ScopeKeyPageState extends State<ScopeKeyPage> {
  int _initialItemCount = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recreating a scope')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'The value of a provider is created once per scope: passing a '
              'different argument alone changes nothing. Changing the key of '
              'the ProviderScope recreates the whole subtree, and therefore '
              'the value too. This is possible, but discouraged.',
            ),
          ),
          ProviderScope(
            key: ValueKey(_initialItemCount),
            providers: [cartProvider(_initialItemCount)],
            child: Builder(
              builder: (context) {
                final cart = cartProvider.of(context);
                return ListenableBuilder(
                  listenable: cart,
                  builder: (context, child) {
                    return ListTile(
                      title: const Text('Items in the cart'),
                      subtitle: Text(cart.itemCount.toString()),
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _initialItemCount++);
            },
            child: const Text('Recreate the scope with one more item'),
          ),
          const Divider(height: 1),
          const Expanded(child: LogPanel()),
        ],
      ),
    );
  }
}

/// Shows the difference between `of` and `maybeOf` for a provider which is not
/// provided by any scope.
class ErrorsPage extends StatefulWidget {
  const ErrorsPage({super.key});

  @override
  State<ErrorsPage> createState() => _ErrorsPageState();
}

class _ErrorsPageState extends State<ErrorsPage> {
  String? _error;

  void _injectMissingProvider() {
    try {
      missingProvider.of(context);
    } on ProviderWithoutScopeError catch (error) {
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final maybeValue = missingProvider.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Missing providers')),
      body: Column(
        children: [
          ListTile(
            title: const Text('missingProvider.maybeOf(context)'),
            subtitle: Text(maybeValue ?? 'null'),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _injectMissingProvider,
              child: const Text('missingProvider.of(context)'),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!),
            ),
        ],
      ),
    );
  }
}

/// Displays the messages of the [Logger] of the app-wide scope.
class LogPanel extends StatelessWidget {
  const LogPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // The app-wide scope is an ancestor of every page, therefore the logger is
    // reachable from anywhere.
    final logger = loggerProvider.of(context);
    return ListenableBuilder(
      listenable: logger,
      builder: (context, child) {
        final messages = logger.messages;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text('Lifecycle log'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: logger.clear,
                  child: const Text('Clear'),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return Text(
                    messages[index],
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
