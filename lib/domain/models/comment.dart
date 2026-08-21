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

/// Comment / reply view object matching backend [CommentVO].
///
/// Both top-level comments and replies share this model:
/// - [parentId] is null for top-level comments, set for replies
/// - [replyToUser] is the user being replied to (null for top-level)
class Comment {
  final int id;
  final int postId;
  final User author;
  final int? parentId;
  final User? replyToUser;
  final String content;
  final int likesCount;
  final int commentsCount;
  final bool? liked;
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
    this.liked,
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
      liked: json['liked'] as bool?,
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
        'liked': liked,
        'topReply': topReply?.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  Comment copyWith({
    int? likesCount,
    int? commentsCount,
    bool? liked,
    TopReply? topReply,
  }) {
    return Comment(
      id: id,
      postId: postId,
      author: author,
      parentId: parentId,
      replyToUser: replyToUser,
      content: content,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      liked: liked ?? this.liked,
      topReply: topReply ?? this.topReply,
      createdAt: createdAt,
    );
  }
}
