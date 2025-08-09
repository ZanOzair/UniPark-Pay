import 'package:flutter/material.dart';
import '../../app/route_manager.dart';

class BottomNavBar extends StatefulWidget {
  final RouteManager routeManager;

  const BottomNavBar({super.key, required this.routeManager});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  @override
  Widget build(BuildContext context) {
    final (selectedColor, currentIndex) = _getNavBarState(
      widget.routeManager.currentRoute.value,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: Colors.white,
          selectedItemColor: selectedColor,
          unselectedItemColor: Colors.grey[600],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          iconSize: 28,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: selectedColor,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          selectedIconTheme: IconThemeData(color: selectedColor, size: 30),
          unselectedIconTheme: IconThemeData(color: Colors.grey[600], size: 28),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.local_parking),
              label: 'Parking',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                widget.routeManager.navigateTo('/parking');
                break;
              case 1:
                widget.routeManager.navigateTo('/profile');
                break;
            }
          },
        ),
      ),
    );
  }

  (Color, int) _getNavBarState(String route) {
    switch (route) {
      case '/profile':
        return (Colors.deepPurple[800]!, 1);
      case '/parking':
        return (Colors.blue[800]!, 0);
      default:
        return (Colors.grey[600]!, 0);
    }
  }
}
