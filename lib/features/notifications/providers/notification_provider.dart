import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  NotificationProvider({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiEndpoints.myNotifications);
      final data = response.data['data'];
      if (data != null && data['notifications'] is List) {
        _notifications = (data['notifications'] as List)
            .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
            .toList();
        _unreadCount = _notifications.where((n) => !n.isRead).length;
      }
    } catch (_) {
      _notifications = _getDemoNotifications();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.unreadNotificationsCount);
      final data = response.data['data'];
      if (data != null && data['unreadCount'] != null) {
        _unreadCount = (data['unreadCount'] as num).toInt();
        notifyListeners();
      }
    } catch (_) {
      // Keep existing
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
      notifyListeners();
    }

    try {
      await _apiClient.patch(ApiEndpoints.markNotificationRead(id));
    } catch (_) {
      // Handled
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();

    try {
      await _apiClient.patch(ApiEndpoints.markAllNotificationsRead);
    } catch (_) {
      // Handled
    }
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();

    try {
      await _apiClient.delete(ApiEndpoints.deleteNotification(id));
    } catch (_) {
      // Handled
    }
  }

  List<NotificationModel> _getDemoNotifications() {
    return [
      NotificationModel(
        id: 'notif-1',
        type: 'ENROLLMENT',
        title: 'Welcome to Flutter & Dart Masterclass!',
        message: 'Your enrollment has been confirmed. Start your first lesson now.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      NotificationModel(
        id: 'notif-2',
        type: 'QUIZ_RESULT',
        title: 'Quiz Result Available',
        message: 'You scored 92% in Quiz 2: State Management.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      NotificationModel(
        id: 'notif-3',
        type: 'ASSIGNMENT_GRADED',
        title: 'Assignment 1 Graded',
        message: 'Instructor Nimal graded your assignment submission: 95/100.',
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }
}
