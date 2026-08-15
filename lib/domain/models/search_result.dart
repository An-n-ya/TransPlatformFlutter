import 'user.dart';

/// Topic search result item matching the backend topic VO.
class SearchTopic {
  final int id;
  final String name;
  final int participantsCount;

  const SearchTopic({
    required this.id,
    required this.name,
    this.participantsCount = 0,
  });

  factory SearchTopic.fromJson(Map<String, dynamic> json) {
    return SearchTopic(
      id: json['id'] as int? ?? 0,
      name: (json['name'] ?? json['title'] ?? json['topicName'] ?? '')
          as String? ?? '',
      participantsCount:
          (json['participantsCount'] ??
                  json['participants'] ??
                  json['followerCount'] ??
                  0)
              as int? ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'participantsCount': participantsCount,
      };
}

/// Unified result of a single search request.
///
/// The backend wraps the paginated `data` object; [users] is populated
/// when [category] is `user`, [topics] when it is `topic`.
class SearchResult {
  final String category;
  final String keyword;
  final List<User> users;
  final List<SearchTopic> topics;

  // Pagination metadata.
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;

  const SearchResult({
    required this.category,
    required this.keyword,
    this.users = const [],
    this.topics = const [],
    this.page = 0,
    this.size = 20,
    this.totalElements = 0,
    this.totalPages = 0,
    this.hasNext = false,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String? ?? 'user';
    final keyword = json['keyword'] as String? ?? '';
    final pageData = json['data'] as Map<String, dynamic>? ?? const {};
    final content = (pageData['content'] as List?) ?? const [];

    return SearchResult(
      category: category,
      keyword: keyword,
      users: category == 'user'
          ? content
                .map((e) => User.fromJson(e as Map<String, dynamic>))
                .toList()
          : const [],
      topics: category == 'topic'
          ? content
                .map((e) => SearchTopic.fromJson(e as Map<String, dynamic>))
                .toList()
          : const [],
      page: pageData['page'] as int? ?? 0,
      size: pageData['size'] as int? ?? 20,
      totalElements: pageData['totalElements'] as int? ?? 0,
      totalPages: pageData['totalPages'] as int? ?? 0,
      hasNext: pageData['hasNext'] as bool? ?? false,
    );
  }
}
