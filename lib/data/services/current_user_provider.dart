import 'package:flutter/foundation.dart';

/// Holds the current authenticated user's ID.
///
/// Set after successful login, consumed via Provider anywhere in the app
/// to avoid redundant API calls just to get the current user ID.
class CurrentUserProvider extends ChangeNotifier {
  int? _userId;
  int? _pinnedPostId;

  int? get userId => _userId;
  int? get pinnedPostId => _pinnedPostId;

  void setPinnedPostId(int id) {
    _pinnedPostId = id;
    notifyListeners();
  }

  void clearPinnedPostId() {
    _pinnedPostId = null;
    notifyListeners();
  }

  void setUserId(int id) {
    _userId = id;
    notifyListeners();
  }

  void clear() {
    _userId = null;
    _pinnedPostId = null;
    notifyListeners();
  }
}
