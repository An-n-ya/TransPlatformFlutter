import '../../../domain/models/topic.dart';
import '../../../utils/result.dart';

/// Data source for topics.
///
/// Implementations:
/// - [TopicRepositoryLocal] — hardcoded sample data for UI development
/// - [TopicRepositoryRemote] — calls the backend API
abstract class TopicRepository {
  /// Get topics (paginated).
  Future<Result<List<Topic>>> getTopics({int page = 0, int size = 20});

  /// Get hot topics (non-paginated).
  Future<Result<List<Topic>>> getHotTopics();

  /// Create a new topic.
  Future<Result<Topic>> createTopic({
    required String name,
    String? description,
  });
}
