import 'package:flutter/foundation.dart';

import '../../domain/models/user.dart';

/// Holds the current authenticated user's global state.
///
/// Set after successful login, consumed via Provider anywhere in the app
/// to avoid redundant API calls.
///
/// Since providers are recreated on app restart, [SplashPage] restores this
/// state by re-executing [setUserId] (via [setCurrentUser]) after it
/// validates the saved session against the backend.
class CurrentUserProvider extends ChangeNotifier {
  int? _userId;
  int? _pinnedPostId;
  final Set<int> _followeeIds = {};

  int? get userId => _userId;
  int? get pinnedPostId => _pinnedPostId;

  /// IDs of users the current user is following.
  Set<int> get followeeIds => Set.unmodifiable(_followeeIds);

  /// Whether the current user follows [targetUserId].
  bool isFollowing(int targetUserId) => _followeeIds.contains(targetUserId);

  void setPinnedPostId(int id) {
    _pinnedPostId = id;
    notifyListeners();
  }

  void clearPinnedPostId() {
    _pinnedPostId = null;
    notifyListeners();
  }

  /// Set the current user's id after login/register.
  ///
  /// Re-executed on app restart by [SplashPage] once the saved session has
  /// been validated against the backend (see [setCurrentUser]).
  void setUserId(int id) {
    _userId = id;
    notifyListeners();
  }

  /// Restore the current user's global state from a freshly fetched [User]
  /// profile (e.g. session restore on app restart).
  void setCurrentUser(User user) {
    _userId = user.id;
    if (user.pinnedPostId != null) {
      _pinnedPostId = user.pinnedPostId;
    }
    notifyListeners();
  }

  /// Replace the entire follow list.
  void setFolloweeIds(Iterable<int> ids) {
    _followeeIds
      ..clear()
      ..addAll(ids);
    notifyListeners();
  }

  /// Add a single followee (after following).
  void addFollowee(int id) {
    if (_followeeIds.add(id)) notifyListeners();
  }

  /// Remove a single followee (after unfollowing).
  void removeFollowee(int id) {
    if (_followeeIds.remove(id)) notifyListeners();
  }

  void clear() {
    _userId = null;
    _pinnedPostId = null;
    _followeeIds.clear();
    notifyListeners();
  }
}
