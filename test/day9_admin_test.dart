import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_lms/features/admin/models/admin_dashboard_model.dart';
import 'package:flutter_lms/features/admin/providers/admin_provider.dart';
import 'package:flutter_lms/features/admin/screens/admin_category_management_screen.dart';
import 'package:flutter_lms/features/admin/screens/admin_course_moderation_screen.dart';
import 'package:flutter_lms/features/admin/screens/admin_main_screen.dart';
import 'package:flutter_lms/features/admin/screens/admin_review_moderation_screen.dart';
import 'package:flutter_lms/features/admin/screens/admin_user_management_screen.dart';
import 'package:flutter_lms/features/auth/models/user_model.dart';
import 'package:flutter_lms/features/courses/models/category_model.dart';
import 'package:flutter_lms/features/courses/models/review_model.dart';
import 'package:flutter_lms/features/dashboard/screens/admin_dashboard_screen.dart';

void main() {
  group('Day 9: Admin Models Unit Tests', () {
    test('AdminDashboardModel deserializes backend summary JSON accurately', () {
      final json = {
        'totalStudents': 150,
        'totalInstructors': 25,
        'activeUsers': 170,
        'totalUsers': 175,
        'publishedCourses': 12,
        'totalCourses': 18,
        'totalEnrollments': 420,
        'completedEnrollments': 95,
        'totalCategories': 8,
        'pendingReviews': 6,
      };

      final model = AdminDashboardModel.fromJson(json);

      expect(model.totalStudents, 150);
      expect(model.totalInstructors, 25);
      expect(model.activeUsers, 170);
      expect(model.totalUsers, 175);
      expect(model.publishedCourses, 12);
      expect(model.totalCourses, 18);
      expect(model.totalEnrollments, 420);
      expect(model.completedEnrollments, 95);
      expect(model.totalCategories, 8);
      expect(model.pendingReviews, 6);

      final copy = model.copyWith(activeUsers: 175, publishedCourses: 15);
      expect(copy.activeUsers, 175);
      expect(copy.publishedCourses, 15);
      expect(copy.totalStudents, 150);
    });

    test('UserModel supports status, isActive, isSuspended getters and copyWith', () {
      final activeUser = UserModel(
        id: 'u-1',
        firstName: 'Kamal',
        lastName: 'Perera',
        email: 'kamal@lms.com',
        role: 'STUDENT',
        status: 'ACTIVE',
      );

      expect(activeUser.isActive, isTrue);
      expect(activeUser.isSuspended, isFalse);

      final suspendedUser = activeUser.copyWith(status: 'SUSPENDED');
      expect(suspendedUser.status, 'SUSPENDED');
      expect(suspendedUser.isActive, isFalse);
      expect(suspendedUser.isSuspended, isTrue);
    });

    test('CategoryModel supports copyWith and isActive toggle', () {
      final cat = CategoryModel(
        id: 'cat-1',
        name: 'Mobile Dev',
        slug: 'mobile-dev',
        isActive: true,
      );

      final updated = cat.copyWith(isActive: false, name: 'Mobile Architecture');
      expect(updated.isActive, isFalse);
      expect(updated.name, 'Mobile Architecture');
      expect(updated.slug, 'mobile-dev');
    });

    test('ReviewModel supports isVisible visibility property and copyWith', () {
      final review = ReviewModel(
        id: 'rev-1',
        courseId: 'c-1',
        studentId: 's-1',
        studentName: 'Kasun',
        rating: 5,
        comment: 'Great course!',
        createdAt: DateTime.now(),
        isVisible: true,
      );

      expect(review.isVisible, isTrue);
      final hidden = review.copyWith(isVisible: false);
      expect(hidden.isVisible, isFalse);
      expect(hidden.id, 'rev-1');
    });
  });

  group('Day 9: AdminProvider State Management Unit Tests', () {
    test('loadAdminDashboard populates dashboard summary', () async {
      final provider = AdminProvider();
      await provider.loadAdminDashboard();

      expect(provider.dashboardSummary, isNotNull);
      expect(provider.dashboardSummary!.totalStudents, greaterThan(0));
      expect(provider.dashboardSummary!.publishedCourses, greaterThan(0));
    });

    test('loadUsers loads user list and filters by role and status', () async {
      final provider = AdminProvider();
      await provider.loadUsers();

      expect(provider.users, isNotEmpty);

      provider.setRoleFilter('STUDENT');
      final students = provider.filteredUsers;
      expect(students.every((u) => u.role == 'STUDENT'), isTrue);

      provider.setUserStatusFilter('ACTIVE');
      final activeStudents = provider.filteredUsers;
      expect(activeStudents.every((u) => u.role == 'STUDENT' && u.isActive), isTrue);

      provider.setRoleFilter('ALL');
      provider.setUserStatusFilter('ALL');
      provider.setUserSearch('nilush');
      expect(provider.filteredUsers.length, 1);
      expect(provider.filteredUsers.first.email, 'nilush@lms.com');
    });

    test('updateUserStatus toggles user status between ACTIVE and SUSPENDED', () async {
      final provider = AdminProvider();
      await provider.loadUsers();

      final target = provider.users.firstWhere((u) => u.role == 'STUDENT');
      final originalStatus = target.status;

      final success = await provider.updateUserStatus(target.id, 'SUSPENDED');
      expect(success, isTrue);

      final updated = provider.users.firstWhere((u) => u.id == target.id);
      expect(updated.status, 'SUSPENDED');
      expect(updated.isSuspended, isTrue);

      // Revert back
      await provider.updateUserStatus(target.id, originalStatus);
    });

    test('Category operations create, update, and toggle category status', () async {
      final provider = AdminProvider();
      await provider.loadCategories();

      final initialCount = provider.categories.length;

      // 1. Create
      final created = await provider.createCategory(
        name: 'AI Engineering',
        slug: 'ai-engineering',
        description: 'LLMs and Deep Learning',
      );
      expect(created, isTrue);
      expect(provider.categories.length, initialCount + 1);
      expect(provider.categories.first.name, 'AI Engineering');

      final newCatId = provider.categories.first.id;

      // 2. Update
      final updated = await provider.updateCategory(
        newCatId,
        name: 'Artificial Intelligence',
        slug: 'artificial-intelligence',
      );
      expect(updated, isTrue);
      expect(provider.categories.first.name, 'Artificial Intelligence');

      // 3. Toggle Status
      final toggled = await provider.toggleCategoryStatus(newCatId, false);
      expect(toggled, isTrue);
      expect(provider.categories.first.isActive, isFalse);
    });

    test('archiveCourseAsAdmin archives a platform course administratively', () async {
      final provider = AdminProvider();
      await provider.loadAdminCourses();

      expect(provider.adminCourses, isNotEmpty);
      final courseToArchive = provider.adminCourses.firstWhere((c) => c.status == 'PUBLISHED');

      final success = await provider.archiveCourseAsAdmin(courseToArchive.id);
      expect(success, isTrue);

      final updatedCourse = provider.adminCourses.firstWhere((c) => c.id == courseToArchive.id);
      expect(updatedCourse.status, 'ARCHIVED');
      expect(updatedCourse.isArchived, isTrue);
    });

    test('toggleReviewVisibility moderates public review visibility', () async {
      final provider = AdminProvider();
      await provider.loadAllReviews();

      expect(provider.reviews, isNotEmpty);
      final review = provider.reviews.firstWhere((r) => r.isVisible);

      final success = await provider.toggleReviewVisibility(review.id, false);
      expect(success, isTrue);

      final updated = provider.reviews.firstWhere((r) => r.id == review.id);
      expect(updated.isVisible, isFalse);
    });
  });

  group('Day 9: Admin Screens Widget Tests', () {
    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AdminProvider()),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('AdminDashboardScreen renders live stats and controls', (tester) async {
      await tester.pumpWidget(createTestApp(const AdminDashboardScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Admin Console 🛡️'), findsOneWidget);
      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('Active Users'), findsOneWidget);
      expect(find.text('Course Categories'), findsOneWidget);
      expect(find.text('Course Moderation'), findsOneWidget);
    });

    testWidgets('AdminUserManagementScreen renders search, filter chips and user cards', (tester) async {
      await tester.pumpWidget(createTestApp(const AdminUserManagementScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('User Management'), findsOneWidget);
      expect(find.text('Role:'), findsOneWidget);
      expect(find.text('Status:'), findsOneWidget);
      expect(find.text('All Roles'), findsOneWidget);
      expect(find.text('All Status'), findsOneWidget);
    });

    testWidgets('AdminCategoryManagementScreen renders category cards and add button', (tester) async {
      await tester.pumpWidget(createTestApp(const AdminCategoryManagementScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Course Categories'), findsOneWidget);
      expect(find.text('New Category'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('AdminCourseModerationScreen renders status filter chips and courses', (tester) async {
      await tester.pumpWidget(createTestApp(const AdminCourseModerationScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Course Moderation'), findsOneWidget);
      expect(find.text('All Courses'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Drafts'), findsOneWidget);
    });

    testWidgets('AdminReviewModerationScreen renders reviews and moderation toggle', (tester) async {
      await tester.pumpWidget(createTestApp(const AdminReviewModerationScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Review Moderation'), findsOneWidget);
      expect(find.text('Total Reviews'), findsOneWidget);
      expect(find.text('Publicly Visible'), findsOneWidget);
    });

    testWidgets('AdminMainScreen renders 4-tab BottomNavigationBar', (tester) async {
      await tester.pumpWidget(createTestApp(const AdminMainScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Overview')), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Users')), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Categories')), findsOneWidget);
      expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Courses')), findsOneWidget);

      // Tap on Users tab
      await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Users')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('User Management'), findsOneWidget);

      // Tap on Categories tab
      await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Categories')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('New Category'), findsOneWidget);
    });
  });
}
