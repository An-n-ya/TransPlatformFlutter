import '../../../domain/models/geo_location.dart';
import '../../../utils/result.dart';

/// Data source for reverse geocoding (GPS coordinates → city location).
///
/// Implementations:
/// - [LocationRepositoryLocal] — hardcoded sample data for UI development
/// - [LocationRepositoryRemote] — calls the backend API
abstract class LocationRepository {
  /// Resolve GPS coordinates to a human-readable city name.
  ///
  /// The backend delegates to Baidu reverse geocoding and returns only the
  /// city (falling back to province, or "境外" for overseas coordinates).
  Future<Result<GeoLocation>> reverseGeocode({
    required double latitude,
    required double longitude,
  });
}
