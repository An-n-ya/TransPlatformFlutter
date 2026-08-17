import '../../../domain/models/topic.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import '../../services/api/page_result.dart';
import 'topic_repository.dart';

/// Remote implementation of [TopicRepository].
///
/// Calls the backend API at [ApiClient.baseUrl].
class TopicRepositoryRemote implements TopicRepository {
  final ApiClient _api;

  TopicRepositoryRemote({required ApiClient apiClient}) : _api = apiClient;

  @override
  Future<Result<List<Topic>>> getTopics({int page = 0, int size = 20}) async {
    final result = await _api.getPage<Topic>(
      '/api/v1/topics',
      queryParams: {
        'page': page.toString(),
        'size': size.toString(),
      },
      fromItem: (data) => Topic.fromJson(data as Map<String, dynamic>),
    );
    switch (result) {
      case Ok<PageResult<Topic>>():
        return Result.ok(result.value.content);
      case Error<PageResult<Topic>>():
        return Result.error(result.error);
    }
  }

  @override
  Future<Result<List<Topic>>> getHotTopics() async {
    return _api.get<List<Topic>>(
      '/api/v1/topics/hot',
      fromData: (data) {
        // The backend may return a plain list or a paged object.
        if (data is List) {
          return data
              .map((e) => Topic.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        final content =
            (data as Map<String, dynamic>)['content'] as List? ?? const [];
        return content
            .map((e) => Topic.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  @override
  Future<Result<Topic>> createTopic({
    required String name,
    String? description,
  }) {
    return _api.post<Topic>(
      '/api/v1/topics',
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
      fromData: (data) => Topic.fromJson(data as Map<String, dynamic>),
    );
  }
}
