import 'package:auto_route/annotations.dart';
import 'package:auto_route_example/controllers/books/controller.dart';
import 'package:flutter/material.dart';

@RoutePage()
class BookPage extends StatelessWidget {
  const BookPage({
    super.key,
    @PathParam() required this.bookId,
  });

  final int bookId;

  @override
  Widget build(BuildContext context) {
    final booksController = booksControllerProvider.of(context);
    final book = booksController.book(bookId);
    return Scaffold(
      appBar: AppBar(title: Text(book.name)),
      body: Center(
        child: Text(booksController.book(bookId).description),
      ),
    );
  }
}
