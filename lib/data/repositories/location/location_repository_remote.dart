import '../../../domain/models/geo_location.dart';
import '../../../utils/result.dart';
import '../../services/api/api_client.dart';
import 'location_repository.dart';

/// Remote implementation of [LocationRepository].
///
/// Calls the backend reverse-geocoding API at [ApiClient.baseUrl]:
/// `GET /api/v1/location/reverse-geocode?latitude=..&longitude=..`
class LocationRepositoryRemote implements LocationRepository {
  final ApiClient _api;

  LocationRepositoryRemote({required ApiClient apiClient}) : _api = apiClient;

  @override
  Future<Result<GeoLocation>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) {
    return _api.get<GeoLocation>(
      '/api/v1/location/reverse-geocode',
      queryParams: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
      fromData: (data) => GeoLocation.fromJson(data as Map<String, dynamic>),
    );
  }
}
