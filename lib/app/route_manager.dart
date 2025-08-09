import 'package:flutter/material.dart';
import '../auth/auth_provider.dart';
import '../pages/app/parking_page.dart';
import '../pages/app/process_parking_page.dart';
import '../pages/app/admin/user_page.dart';
import '../pages/app/admin/qr_upload_page.dart';
import '../pages/app/admin/parking_sessions_page.dart';
import '../widgets/app/content_page.dart';
import '../pages/app/profile_page.dart';
import '../pages/app/settings_page.dart';
import 'user_role.dart';

/// Handles navigation with access control and route generation
class RouteManager {
  static const defaultRoute = '/parking';

  final AuthProvider authProvider;
  final GlobalKey<NavigatorState> navigatorKey;
  final ValueNotifier<String> currentRoute = ValueNotifier(defaultRoute);

  RouteManager({
    required this.authProvider,
    required this.navigatorKey,
  });

  /// Checks route accessibility
  bool canAccess(String? route) {
    final routePermissions = {
      '/dashboard': [UserRole.admin, UserRole.lecturer, UserRole.student],
      '/parking': UserRole.values,
      '/process-parking': UserRole.values,
      '/admin/users': [UserRole.admin],
      '/admin/qr-upload': [UserRole.admin],
      '/admin/parking-sessions': [UserRole.admin],
      '/profile': UserRole.values,
      '/settings': UserRole.values,
    };
    return routePermissions[route]?.contains(authProvider.role) ?? false;
  }

  /// Navigates to route if accessible
  Future<void> navigateTo(String route,[Object? arguments]) async {
    if (canAccess(route) && currentRoute.value != route) {
      currentRoute.value = route;
      navigatorKey.currentState!.pushReplacementNamed(route,arguments: arguments);
    }
  }

  static const Map<String, ContentPage> routeMap = {
    '/parking': ParkingPage(),
    '/process-parking': ProcessParkingPage(),
    '/profile': ProfilePage(),
    '/settings': SettingsPage(),
    '/admin/users': UserPage(),
    '/admin/qr-upload': QRUploadPage(),
    '/admin/parking-sessions': ParkingSessionsPage(),
  };

  ContentPage currentPage = routeMap[defaultRoute]!;

  /// Generates routes based on route settings
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final route = settings.name;
    final type = canAccess(route)
      ? routeMap[route]
      : routeMap[defaultRoute];
    currentPage = type!;
    return MaterialPageRoute(
      builder: (_) => currentPage,
      settings: settings,
    );
  }
}