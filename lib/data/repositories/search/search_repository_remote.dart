import '../../../domain/models/search_result.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import 'search_repository.dart';

/// Remote implementation of [SearchRepository].
///
/// Calls the backend API at [ApiClient.baseUrl].
class SearchRepositoryRemote implements SearchRepository {
  final ApiClient _api;

  SearchRepositoryRemote({required ApiClient apiClient}) : _api = apiClient;

  @override
  Future<Result<SearchResult>> search({
    required String category,
    required String keyword,
    int page = 0,
    int size = 20,
  }) {
    return _api.get<SearchResult>(
      '/api/v1/search',
      queryParams: {
        'category': category,
        'keyword': keyword,
        'page': page.toString(),
        'size': size.toString(),
      },
      fromData: (data) => SearchResult.fromJson(data as Map<String, dynamic>),
    );
  }
}
