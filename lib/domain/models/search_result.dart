import 'topic.dart';
import 'user.dart';

/// Unified result of a single search request.
///
/// The backend wraps the paginated `data` object; [users] is populated
/// when [category] is `user`, [topics] when it is `topic`.
class SearchResult {
  final String category;
  final String keyword;
  final List<User> users;
  final List<Topic> topics;

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
                .map((e) => Topic.fromJson(e as Map<String, dynamic>))
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
