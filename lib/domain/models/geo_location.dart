/// Reverse-geocoding result — the resolved city (or region) name
/// for a pair of GPS coordinates.
///
/// Matches the backend `ReverseGeocodeVO`:
/// ```json
/// { "location": "北京" }
/// ```
class GeoLocation {
  final String location;

  const GeoLocation({required this.location});

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(location: json['location'] as String? ?? '');
  }
}
