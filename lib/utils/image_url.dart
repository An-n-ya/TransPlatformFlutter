import '../config/env.dart';

/// Fixes image URLs from the backend so they are reachable from
/// the device/emulator.
///
/// The backend stores URLs with `localhost`, but that address is
/// unreachable from an Android emulator (use `10.0.2.2`) or
/// a physical device (use the LAN IP from [Env.apiBaseUrl]).
String resolveImageUrl(String? url) {
  if (url == null || url.isEmpty) return '';

  // Only rewrite URLs pointing to localhost
  if (!url.contains('localhost')) return url;

  // Extract the scheme + host + port from apiBaseUrl, e.g.
  // "http://10.0.2.2:8081" or "http://192.168.1.14:8081"
  final base = Uri.tryParse(Env.apiBaseUrl);
  if (base == null) return url;

  return url.replaceFirst(
    RegExp(r'https?://localhost(:\d+)?'),
    '${base.scheme}://${base.host}${base.port != 80 && base.port != 443 ? ':${base.port}' : ''}',
  );
}
