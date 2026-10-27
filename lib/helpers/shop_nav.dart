import 'package:flutter/material.dart';

import 'navigation_service.dart';

NavigatorState get _nav => NavigationService.navigatorKey.currentState!;

Future<T?> push<T>(Widget page) => _nav.push<T>(MaterialPageRoute(builder: (_) => page));

Future<T?> pushReplace<T>(Widget page) => _nav.pushReplacement<T, dynamic>(MaterialPageRoute(builder: (_) => page));

Future<T?> pushAndClear<T>(Widget page) =>
    _nav.pushAndRemoveUntil<T>(MaterialPageRoute(builder: (_) => page), (_) => false);

void pop<T>([T? result]) => _nav.pop<T>(result);
