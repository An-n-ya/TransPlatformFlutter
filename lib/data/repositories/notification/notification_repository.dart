import '../../../domain/models/notification.dart';
import '../../../utils/result.dart';

/// Data source for notifications.
abstract class NotificationRepository {
  /// Get all notifications for the current user (paginated).
  Future<Result<List<AppNotification>>> getNotifications(
      {int page = 0, int size = 20});

  /// Get unread notification count.
  Future<Result<int>> getUnreadCount();

  /// Mark a single notification as read.
  Future<Result<void>> markAsRead(int notificationId);

  /// Mark all notifications as read.
  Future<Result<void>> markAllAsRead();
}
