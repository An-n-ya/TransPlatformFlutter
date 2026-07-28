import 'user.dart';

/// Comment view object matching backend [CommentVO].
///
/// ```json
/// {
///   "id": 1,
///   "postId": 1,
///   "author": { ... },
///   "parentId": null,
///   "replyToUser": null,
///   "content": "Great!",
///   "likesCount": 5,
///   "replies": [],
///   "createdAt": "2024-01-15T10:30:00"
/// }
/// ```
class Comment {
  final int id;
  final int postId;
  final User author;
  final int? parentId;
  final User? replyToUser;
  final String content;
  final int likesCount;
  final List<Comment> replies;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    this.parentId,
    this.replyToUser,
    required this.content,
    this.likesCount = 0,
    this.replies = const [],
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      postId: json['postId'] as int? ?? 0,
      author: User.fromJson(json['author'] as Map<String, dynamic>),
      parentId: json['parentId'] as int?,
      replyToUser: json['replyToUser'] != null
          ? User.fromJson(json['replyToUser'] as Map<String, dynamic>)
          : null,
      content: json['content'] as String? ?? '',
      likesCount: json['likesCount'] as int? ?? 0,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'author': author.toJson(),
        'parentId': parentId,
        'replyToUser': replyToUser?.toJson(),
        'content': content,
        'likesCount': likesCount,
        'replies': replies.map((r) => r.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
}
