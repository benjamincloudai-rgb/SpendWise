import 'package:flutter/material.dart';
import 'package:spendwise/core/widgets/shared_bottom_nav.dart';
import 'package:spendwise/features/authentication/screens/dashboard_screen.dart';
import 'package:spendwise/features/transactions/screens/transactions_screen.dart';
import 'package:spendwise/features/statistics/screens/statistics_screen.dart';
import 'package:spendwise/features/profile/screens/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    const DashboardScreen(),
    const TransactionsScreen(),
    const StatisticsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Prevents secondary background overlaps
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: SharedBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
