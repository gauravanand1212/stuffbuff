import 'package:flutter/material.dart';
import 'browse_tools_screen.dart';
import 'my_tools_screen.dart';
import 'my_rentals_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = [
    const BrowseToolsScreen(),
    const MyToolsScreen(),
    const MyRentalsScreen(),
    const ProfileScreen(),
  ];

  final _titles = [
    'Browse Tools',
    'My Tools',
    'My Rentals',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: _currentIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // TODO: Show search
                  },
                ),
              ]
            : null,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman),
            label: 'My Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            label: 'Rentals',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}