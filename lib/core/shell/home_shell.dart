import 'package:flutter/material.dart';
import 'package:spendwise/core/widgets/shared_bottom_nav.dart';
import 'package:spendwise/features/authentication/screens/dashboard_screen.dart';
import 'package:spendwise/features/transactions/screens/transactions_screen.dart';
import 'package:spendwise/features/statistics/screens/statistics_screen.dart';
import 'package:spendwise/features/profile/screens/profile_screen.dart';
import 'package:spendwise/services/currency_controller.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  void _goToDashboard() => setState(() => _currentIndex = 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // Prevents secondary background overlaps
      body: AnimatedBuilder(
        // Rebuilds the tabs when the selected currency changes so every
        // money display refreshes from the single CurrencyController source.
        animation: CurrencyController.instance,
        builder: (context, child) {
          return IndexedStack(
            index: _currentIndex,
            children: [
              DashboardScreen(),
              TransactionsScreen(onBackPressed: _goToDashboard),
              StatisticsScreen(onBackPressed: _goToDashboard),
              ProfileScreen(onBackPressed: _goToDashboard),
            ],
          );
        },
      ),
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
