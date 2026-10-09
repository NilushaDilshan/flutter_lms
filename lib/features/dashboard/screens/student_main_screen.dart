import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../courses/screens/course_catalog_screen.dart';
import '../../courses/screens/my_courses_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'student_dashboard_screen.dart';

class StudentMainScreen extends StatefulWidget {
  final String studentName;
  final int initialTab;

  const StudentMainScreen({
    super.key,
    this.studentName = 'Kamal Perera',
    this.initialTab = 0,
  });

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      StudentDashboardScreen(studentName: widget.studentName),
      const CourseCatalogScreen(),
      const MyCoursesScreen(),
      const ProfileScreen(),
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
        selectedItemColor: AppColors.studentRole,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore_rounded),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark_rounded),
            label: 'My Learning',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
