import 'package:auto_route/auto_route.dart';
import 'package:auto_route_example/pages/book.dart';
import 'package:auto_route_example/pages/books.dart';
import 'package:auto_route_example/pages/home.dart';
import 'package:flutter/foundation.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: HomeRoute.page,
        ),
        AutoRoute(
          path: '/books',
          page: BooksWrapperRoute.page,
          children: [
            AutoRoute(path: '', page: BooksRoute.page, initial: true),
            AutoRoute(path: ':bookId', page: BookRoute.page),
          ],
        ),
      ];
}
