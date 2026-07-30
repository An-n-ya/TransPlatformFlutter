import 'user.dart';

/// A top-level reply preview attached to a comment.
class TopReply {
  final int id;
  final int userId;
  final String nickname;
  final String content;
  final int likesCount;

  const TopReply({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.content,
    this.likesCount = 0,
  });

  factory TopReply.fromJson(Map<String, dynamic> json) {
    return TopReply(
      id: json['id'] as int,
      userId: json['userId'] as int,
      nickname: json['nickname'] as String? ?? '',
      content: json['content'] as String? ?? '',
      likesCount: json['likesCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'nickname': nickname,
        'content': content,
        'likesCount': likesCount,
      };
}

/// Comment view object matching backend [CommentVO].
class Comment {
  final int id;
  final int postId;
  final User author;
  final int? parentId;
  final User? replyToUser;
  final String content;
  final int likesCount;
  final int commentsCount;
  final TopReply? topReply;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    this.parentId,
    this.replyToUser,
    required this.content,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.topReply,
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
      commentsCount: json['commentsCount'] as int? ?? 0,
      topReply: json['topReply'] != null
          ? TopReply.fromJson(json['topReply'] as Map<String, dynamic>)
          : null,
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
        'topReply': topReply?.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };
}
