import 'package:auto_route/auto_route.dart';
import 'package:auto_route_example/controllers/books/controller.dart';
import 'package:auto_route_example/router.dart';
import 'package:disco/disco.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BooksWrapperPage extends StatelessWidget implements AutoRouteWrapper {
  const BooksWrapperPage({super.key});
  @override
  Widget wrappedRoute(BuildContext context) {
    return ProviderScope(
      providers: [booksControllerProvider],
      child: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const AutoRouter();
  }
}

@RoutePage()
class BooksPage extends StatelessWidget {
  const BooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final booksBloc = booksControllerProvider.of(context);
    final books = booksBloc.books;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Books'),
        leading: BackButton(
          onPressed: () => const HomeRoute().navigate(context),
        ),
      ),
      body: ListView.separated(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return ListTile(
            title: Text(book.name),
            onTap: () => BookRoute(bookId: book.id).navigate(context),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 8),
      ),
    );
  }
}
