// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [BookPage]
class BookRoute extends PageRouteInfo<BookRouteArgs> {
  BookRoute({Key? key, required int bookId, List<PageRouteInfo>? children})
    : super(
        BookRoute.name,
        args: BookRouteArgs(key: key, bookId: bookId),
        rawPathParams: {'bookId': bookId},
        initialChildren: children,
      );

  static const String name = 'BookRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<BookRouteArgs>(
        orElse: () => BookRouteArgs(bookId: pathParams.getInt('bookId')),
      );
      return BookPage(key: args.key, bookId: args.bookId);
    },
  );
}

class BookRouteArgs {
  const BookRouteArgs({this.key, required this.bookId});

  final Key? key;

  final int bookId;

  @override
  String toString() {
    return 'BookRouteArgs{key: $key, bookId: $bookId}';
  }
}

/// generated route for
/// [BooksPage]
class BooksRoute extends PageRouteInfo<void> {
  const BooksRoute({List<PageRouteInfo>? children})
    : super(BooksRoute.name, initialChildren: children);

  static const String name = 'BooksRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const BooksPage();
    },
  );
}

/// generated route for
/// [BooksWrapperPage]
class BooksWrapperRoute extends PageRouteInfo<void> {
  const BooksWrapperRoute({List<PageRouteInfo>? children})
    : super(BooksWrapperRoute.name, initialChildren: children);

  static const String name = 'BooksWrapperRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return WrappedRoute(child: const BooksWrapperPage());
    },
  );
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomePage();
    },
  );
}
