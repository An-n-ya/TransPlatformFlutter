import '../../../domain/models/topic.dart';
import '../../../utils/result.dart';
import 'topic_repository.dart';

/// Local implementation of [TopicRepository].
///
/// Returns hardcoded sample data — no backend needed.
class TopicRepositoryLocal implements TopicRepository {
  @override
  Future<Result<List<Topic>>> getTopics({int page = 0, int size = 20}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.ok(_mockTopics);
  }

  @override
  Future<Result<List<Topic>>> getHotTopics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sorted = [..._mockTopics]
      ..sort((a, b) => b.participantsCount.compareTo(a.participantsCount));
    return Result.ok(sorted);
  }

  @override
  Future<Result<Topic>> createTopic({
    required String name,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Result.ok(
      Topic(
        id: 100 + _mockTopics.length,
        name: name,
        description: description,
        participantsCount: 0,
      ),
    );
  }

  final _mockTopics = const [
    Topic(id: 1, name: '摄影日记', participantsCount: 3280000),
    Topic(id: 2, name: '城市记录', participantsCount: 2110000),
    Topic(id: 3, name: '美食探店', participantsCount: 5040000),
    Topic(id: 4, name: '旅行攻略', participantsCount: 120000000),
  ];
}
