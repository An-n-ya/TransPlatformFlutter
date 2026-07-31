import 'package:flutter/foundation.dart';

/// Holds the current authenticated user's ID.
///
/// Set after successful login, consumed via Provider anywhere in the app
/// to avoid redundant API calls just to get the current user ID.
class CurrentUserProvider extends ChangeNotifier {
  int? _userId;

  int? get userId => _userId;

  void setUserId(int id) {
    _userId = id;
    notifyListeners();
  }

  void clear() {
    _userId = null;
    notifyListeners();
  }
}
