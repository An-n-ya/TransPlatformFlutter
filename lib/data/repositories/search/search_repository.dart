import '../../../domain/models/search_result.dart';
import '../../../utils/result.dart';

/// Data source for searching users and topics.
///
/// Implementations:
/// - [SearchRepositoryLocal] — hardcoded sample data for UI development
/// - [SearchRepositoryRemote] — calls the backend API
abstract class SearchRepository {
  /// Search a [category] (`user` or `topic`) by [keyword] (paginated).
  Future<Result<SearchResult>> search({
    required String category,
    required String keyword,
    int page = 0,
    int size = 20,
  });
}
