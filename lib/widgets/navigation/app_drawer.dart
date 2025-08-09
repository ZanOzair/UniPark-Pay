import 'package:flutter/material.dart';
import 'package:uniparkpay/app/route_manager.dart';

class AppDrawer extends StatefulWidget {
  final RouteManager routeManager;
  
  const AppDrawer({
    super.key,
    required this.routeManager,
  });

  static final Set<String> drawerRoutes = {
    '/settings',
    '/admin/users',
    '/admin/qr-upload',
    '/admin/parking-sessions',
  };
  
  static bool isDrawerRoute(String route) {
    return drawerRoutes.contains(route);
  }

  static bool isCurrentRoute(String currentRoute, String targetRoute) {
    return currentRoute == targetRoute;
  }

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ValueListenableBuilder<String>(
        valueListenable: widget.routeManager.currentRoute,
        builder: (context, route, child) {
          return ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text('UniParkPay'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Users',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('User Management'),
                selected: AppDrawer.isCurrentRoute(route, '/admin/users'),
                selectedTileColor: Color.fromRGBO(33, 150, 243, 0.1),
                selectedColor: Colors.blue,
                onTap: () {
                  widget.routeManager.navigateTo('/admin/users');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text('QR Payment Code'),
                selected: AppDrawer.isCurrentRoute(route, '/admin/qr-upload'),
                selectedTileColor: Color.fromRGBO(33, 150, 243, 0.1),
                selectedColor: Colors.blue,
                onTap: () {
                  widget.routeManager.navigateTo('/admin/qr-upload');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Parking Sessions'),
                selected: AppDrawer.isCurrentRoute(route, '/admin/parking-sessions'),
                selectedTileColor: Color.fromRGBO(33, 150, 243, 0.1),
                selectedColor: Colors.blue,
                onTap: () {
                  widget.routeManager.navigateTo('/admin/parking-sessions');
                  Navigator.pop(context);
                },
              ),
              // const Divider(),
              // ListTile(
              //   leading: const Icon(Icons.settings),
              //   title: const Text('Settings'),
              //   selected: AppDrawer.isCurrentRoute(route, '/settings'),
              //   selectedTileColor: Color.fromRGBO(33, 150, 243, 0.1),
              //   selectedColor: Colors.blue,
              //   onTap: () {
              //     widget.routeManager.navigateTo('/settings');
              //     Navigator.pop(context);
              //   },
              // ),
            ],
          );
        },
      ),
    );
  }
}