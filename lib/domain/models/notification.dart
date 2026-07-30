import 'user.dart';

/// Notification view object matching backend [NotificationVO].
class AppNotification {
  final int id;
  final String type; // "reply", "like", "follow"
  final String title;
  final String? content;
  final User fromUser;
  final int? targetId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.content,
    required this.fromUser,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      fromUser: User.fromJson(json['fromUser'] as Map<String, dynamic>),
      targetId: json['targetId'] as int?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
