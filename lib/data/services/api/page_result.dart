/// Backend pagination result.
///
/// ```json
/// {
///   "content": [...],
///   "page": 0,
///   "size": 20,
///   "totalElements": 100,
///   "totalPages": 5,
///   "hasNext": true
/// }
/// ```
class PageResult<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;

  const PageResult({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromItem,
  ) {
    final list = (json['content'] as List?)
            ?.map((e) => fromItem(e))
            .toList() ??
        <T>[];
    return PageResult(
      content: list,
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 20,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }
}
