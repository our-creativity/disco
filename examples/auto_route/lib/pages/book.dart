import 'package:auto_route/annotations.dart';
import 'package:auto_route_example/blocs/books/bloc.dart';
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
    final booksBloc = booksBlocProvider.of(context);
    final book = booksBloc.book(bookId);
    return Scaffold(
      appBar: AppBar(title: Text(book.name)),
      body: Center(
        child: Text(booksBloc.book(bookId).description),
      ),
    );
  }
}
