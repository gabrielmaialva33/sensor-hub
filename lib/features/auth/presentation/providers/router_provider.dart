import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_router.dart';

/// Provider for GoRouter instance with authentication integration
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});

/// Router delegate provider for direct access to router functionality
final routerDelegateProvider = Provider<GoRouterDelegate>((ref) {
  return ref.watch(routerProvider).routerDelegate;
});

/// Route information provider for accessing current route data
final routeInformationProvider = Provider<GoRouteInformationProvider>((ref) {
  return ref.watch(routerProvider).routeInformationProvider;
});

/// Route information parser provider
final routeInformationParserProvider = Provider<GoRouteInformationParser>((ref) {
  return ref.watch(routerProvider).routeInformationParser;
});