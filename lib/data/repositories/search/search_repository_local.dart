import '../../../domain/models/search_result.dart';
import '../../../domain/models/user.dart';
import '../../../utils/result.dart';
import 'search_repository.dart';

/// Local implementation of [SearchRepository].
///
/// Returns hardcoded sample data — no backend needed.
class SearchRepositoryLocal implements SearchRepository {
  @override
  Future<Result<SearchResult>> search({
    required String category,
    required String keyword,
    int page = 0,
    int size = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.ok(
      SearchResult(
        category: category,
        keyword: keyword,
        users: category == 'user' ? _mockUsers : const [],
        topics: category == 'topic' ? _mockTopics : const [],
        totalElements:
            category == 'user' ? _mockUsers.length : _mockTopics.length,
        totalPages: 1,
      ),
    );
  }

  final _mockUsers = const [
    User(id: 8, username: 'alice2', nickname: 'Alice二号'),
    User(id: 1, username: 'alice', nickname: 'Alice'),
  ];

  final _mockTopics = const [
    SearchTopic(id: 1, name: 'Topic 1', participantsCount: 15),
    SearchTopic(id: 2, name: 'Topic 2', participantsCount: 1),
  ];
}
