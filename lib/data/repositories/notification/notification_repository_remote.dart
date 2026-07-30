import '../../../domain/models/notification.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import '../../services/api/page_result.dart';
import 'notification_repository.dart';

class NotificationRepositoryRemote implements NotificationRepository {
  final ApiClient _api;

  NotificationRepositoryRemote({required ApiClient apiClient})
      : _api = apiClient;

  @override
  Future<Result<List<AppNotification>>> getNotifications(
      {int page = 0, int size = 20}) async {
    final result = await _api.getPage<AppNotification>(
      '/api/v1/notifications',
      queryParams: {
        'page': page.toString(),
        'size': size.toString(),
      },
      fromItem: (data) =>
          AppNotification.fromJson(data as Map<String, dynamic>),
    );
    switch (result) {
      case Ok<PageResult<AppNotification>>():
        return Result.ok(result.value.content);
      case Error<PageResult<AppNotification>>():
        return Result.error(result.error);
    }
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    return _api.get<int>(
      '/api/v1/notifications/unread/count',
      fromData: (data) => data as int,
    );
  }

  @override
  Future<Result<void>> markAsRead(int notificationId) async {
    return _api.put<void>('/api/v1/notifications/$notificationId/read');
  }

  @override
  Future<Result<void>> markAllAsRead() async {
    return _api.put<void>('/api/v1/notifications/read-all');
  }
}
