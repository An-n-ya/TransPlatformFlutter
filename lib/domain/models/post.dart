import 'topic.dart';
import 'user.dart';

import '../../utils/image_url.dart';

/// Post view object matching backend [PostVO].
///
/// ```json
/// {
///   "id": 1,
///   "author": { ... },
///   "content": "...",
///   "images": ["https://..."],
///   "location": "Beijing",
///   "likesCount": 42,
///   "commentsCount": 7,
///   "collectionsCount": 3,
///   "liked": true,
///   "collected": false,
///   "createdAt": "2024-01-15T10:30:00"
/// }
/// ```
class Post {
  final int id;
  final User author;
  final String content;
  final List<String> images;
  final String? location;
  final int likesCount;
  final int commentsCount;
  final int collectionsCount;
  final bool isPinned;
  final bool? liked;
  final bool? collected;
  final List<Topic> topics;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.author,
    required this.content,
    this.images = const [],
    this.location,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.collectionsCount = 0,
    this.isPinned = false,
    this.liked,
    this.collected,
    this.topics = const [],
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      author: User.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => resolveImageUrl(e as String))
              .toList() ??
          [],
      location: json['location'] as String?,
      likesCount: json['likesCount'] as int? ?? 0,
      commentsCount: json['commentsCount'] as int? ?? 0,
      collectionsCount: json['collectionsCount'] as int? ?? 0,
      liked: json['liked'] as bool?,
      collected: json['collected'] as bool?,
      isPinned: json['isPinned'] as bool? ?? false,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((e) => Topic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author.toJson(),
        'content': content,
        'images': images,
        'location': location,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'collectionsCount': collectionsCount,
        'liked': liked,
        'collected': collected,
        'isPinned': isPinned,
        'topics': topics.map((t) => t.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  Post copyWith({bool? isPinned}) {
    return Post(
      id: id,
      author: author,
      content: content,
      images: images,
      location: location,
      likesCount: likesCount,
      commentsCount: commentsCount,
      collectionsCount: collectionsCount,
      isPinned: isPinned ?? this.isPinned,
      liked: liked,
      collected: collected,
      topics: topics,
      createdAt: createdAt,
    );
  }
}
