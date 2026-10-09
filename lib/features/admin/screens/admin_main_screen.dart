import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../dashboard/screens/admin_dashboard_screen.dart';
import 'admin_category_management_screen.dart';
import 'admin_course_moderation_screen.dart';
import 'admin_user_management_screen.dart';

class AdminMainScreen extends StatefulWidget {
  final String adminEmail;
  final int initialTab;

  const AdminMainScreen({
    super.key,
    this.adminEmail = 'admin@lms.com',
    this.initialTab = 0,
  });

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      AdminDashboardScreen(adminEmail: widget.adminEmail),
      const AdminUserManagementScreen(),
      const AdminCategoryManagementScreen(),
      const AdminCourseModerationScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.adminRole,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.manage_accounts_outlined),
            activeIcon: Icon(Icons.manage_accounts_rounded),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category_rounded),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2_rounded),
            label: 'Courses',
          ),
        ],
      ),
    );
  }
}
