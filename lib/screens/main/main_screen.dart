import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../home/home_screen.dart';
import '../sales/sales_screen.dart';
import '../settings/settings_screen.dart';
import '../stocks/add_product_screen.dart';
import '../stocks/stock_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  List<Widget> get pages => [
    HomeScreen(
      onViewInventory: () => setState(() => currentIndex = 1),
      onViewSales: () => setState(() => currentIndex = 2),
      onOpenProfile: () => setState(() => currentIndex = 3),
    ),
    const StockScreen(),
    const SalesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: CustomBottomNavBar(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() => currentIndex = index);
          },
          onAddPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            );
          },
        ),
      ),
    );
  }
}
