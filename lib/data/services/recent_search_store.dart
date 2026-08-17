import 'package:shared_preferences/shared_preferences.dart';

/// Persists recent search keywords in SharedPreferences.
class RecentSearchStore {
  static const _key = 'recent_searches';
  static const _maxItems = 10;

  /// Loads the stored recent keywords (most recent first).
  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? const [];
  }

  /// Inserts [keyword] at the front (deduplicated, capped) and persists.
  ///
  /// Returns the updated list.
  Future<List<String>> save(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    list.removeWhere((e) => e == keyword);
    list.insert(0, keyword);
    if (list.length > _maxItems) list.removeRange(_maxItems, list.length);
    await prefs.setStringList(_key, list);
    return list;
  }
}
