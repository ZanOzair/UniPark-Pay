import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/route_manager.dart';
import '../../auth/auth_provider.dart';
import '../../widgets/navigation/navigation_scaffold.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late RouteManager _routeManager;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _routeManager = RouteManager(
      authProvider: authProvider,
      navigatorKey: _navigatorKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationScaffold(
      routeManager: _routeManager,
    );
  }
}