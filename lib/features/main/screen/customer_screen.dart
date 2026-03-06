import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/auth_provider.dart';
import '../../main/screen/home_screen.dart';
import '../../appointments/screen/appointments_screen.dart';
import '../../favorites/screen/favorites_screen.dart';
import '../../profile/screen/profile_screen.dart';

// Root shell screen for authenticated customers, served at `/`.
//
// Hosts a BottomNavigationBar with four tabs: Home, Booking, Favourites,
// and Profile. Uses authProvider for auth state so tab access is reactive.

class CustomerScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const CustomerScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends ConsumerState<CustomerScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  @override
  void didUpdateWidget(CustomerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      if (mounted) setState(() => _selectedIndex = widget.initialTab);
    }
  }

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    AppointmentsScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    final isLoggedIn = ref.read(authProvider) is AuthAuthenticated;

    // Home (index 0) is always allowed
    if (index != 0 && !isLoggedIn) {
      _showSignInSnack();
      context.go('/front');
      return;
    }

    setState(() => _selectedIndex = index);
  }

  void _showSignInSnack() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Please sign in to continue')),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state so the nav bar rebuilds when login status changes
    ref.watch(authProvider);
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _widgetOptions),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favourite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
