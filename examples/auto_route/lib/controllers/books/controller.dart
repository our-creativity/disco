import 'package:auto_route_example/controllers/books/model.dart';
import 'package:disco/disco.dart';

final booksControllerProvider = Provider((context) => BooksBloc());

class BooksBloc {
  final _books = List.generate(
    10,
    (index) => Book(
      id: index,
      name: 'Book $index',
      description: 'Description for book $index',
    ),
  );

  /// Returns a list of all books.
  List<Book> get books {
    return _books;
  }

  /// Returns a book by its [id].
  Book book(int id) {
    return _books.firstWhere((book) => book.id == id);
  }
}
