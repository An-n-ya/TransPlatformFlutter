import '../../../domain/models/geo_location.dart';
import '../../../utils/result.dart';
import 'location_repository.dart';

/// Local implementation of [LocationRepository].
///
/// No backend needed — returns the raw coordinates as the location so the
/// UI flow can still be exercised in local mode.
class LocationRepositoryLocal implements LocationRepository {
  @override
  Future<Result<GeoLocation>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return Result.ok(
      GeoLocation(
        location: '(${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)})',
      ),
    );
  }
}
