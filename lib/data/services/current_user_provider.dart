import 'package:flutter/foundation.dart';

/// Holds the current authenticated user's ID.
///
/// Set after successful login, consumed via Provider anywhere in the app
/// to avoid redundant API calls just to get the current user ID.
// TODO: 也可以用这个Provider存储一些全局状态，比如当前用户的个人信息等。
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
