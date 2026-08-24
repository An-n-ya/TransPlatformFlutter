/// Feed stream types for the homepage timeline (`GET /api/v1/feed?type=…`).
enum FeedType {
  /// All users' latest posts (default). SQL direct query.
  plaza,

  /// Latest posts from followed users. Redis write-fanout.
  following,

  /// Posts filtered by the current user's location. SQL direct query.
  nearby;

  /// PostCache list-query key for this stream.
  String get cacheKey => 'feed-$name';

  /// Tab label shown in the UI.
  String get label => switch (this) {
        FeedType.plaza => '广场',
        FeedType.following => '关注',
        FeedType.nearby => '附近',
      };
}
