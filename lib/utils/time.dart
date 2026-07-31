import 'package:intl/intl.dart';

/// Formats a [DateTime] as a relative time string.
///
/// - < 1 minute → "X 分钟前"
/// - < 1 hour   → "X 分钟前"
/// - < 24 hours → "X 小时前"
/// - < 7 days   → "X 天前"
/// - otherwise  → "yyyy-MM-dd"
String formatRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes == 0) return '现在';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  return DateFormat('yyyy-MM-dd').format(dt);
}
