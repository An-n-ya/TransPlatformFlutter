import '../../../domain/models/notification.dart';
import '../../../domain/models/user.dart';
import '../../../utils/result.dart';
import 'notification_repository.dart';

class NotificationRepositoryLocal implements NotificationRepository {
  @override
  Future<Result<List<AppNotification>>> getNotifications(
      {int page = 0, int size = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.ok(_mockNotifications);
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    return Result.ok(3);
  }

  @override
  Future<Result<void>> markAsRead(int notificationId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  @override
  Future<Result<void>> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return Result.ok(null);
  }

  final _mockNotifications = [
    AppNotification(
      id: 1,
      type: 'reply',
      title: '回复',
      content: '写得太好了！',
      fromUser: const User(id: 2, username: 'bob', nickname: 'Bob'),
      targetId: 1,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AppNotification(
      id: 2,
      type: 'like',
      title: '喜欢',
      fromUser: const User(id: 3, username: 'charlie', nickname: 'Charlie'),
      targetId: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    AppNotification(
      id: 3,
      type: 'follow',
      title: '关注',
      fromUser: const User(id: 4, username: 'dave', nickname: 'Dave'),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}
