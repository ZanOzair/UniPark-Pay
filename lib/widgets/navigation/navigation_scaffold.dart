import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uniparkpay/app/route_manager.dart';
import 'package:uniparkpay/auth/auth_provider.dart';
import 'package:uniparkpay/app/user_role.dart';
import 'package:uniparkpay/widgets/navigation/app_drawer.dart';
import 'package:uniparkpay/widgets/navigation/bottom_nav_bar.dart';

class NavigationScaffold extends StatefulWidget {
  final RouteManager routeManager;

  const NavigationScaffold({
    super.key,
    required this.routeManager,
  });

  @override
  State<NavigationScaffold> createState() => _NavigationScaffoldState();
}

class _NavigationScaffoldState extends State<NavigationScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: widget.routeManager.currentRoute,
      builder: (context, route, child) {
        final authProvider = Provider.of<AuthProvider>(context);
        final isAdmin = authProvider.role == UserRole.admin;
        
        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(widget.routeManager.currentPage.title),
            leading: isAdmin && AppDrawer.isDrawerRoute(route)
                ? IconButton(
                    icon: const Icon(Icons.menu),
                    color: Colors.blue,
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  )
                : null,
          ),
          drawer: isAdmin ? AppDrawer(
            routeManager: widget.routeManager,
          ) : null,
          body: SafeArea(
            child: Navigator(
              key: widget.routeManager.navigatorKey,
              onGenerateRoute: widget.routeManager.onGenerateRoute,
              initialRoute: RouteManager.defaultRoute,
            ),
          ),
          bottomNavigationBar: BottomNavBar(
            routeManager: widget.routeManager,
          ),
        );
      },
    );
  }
}