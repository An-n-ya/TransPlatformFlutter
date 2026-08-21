# Riverpod + 乐观更新 + 内存缓存 SSOT 数据层重构方案

## Summary

将项目数据层从当前的 `provider` + `FutureBuilder` + `setState` 模式，重构为 **Riverpod（代码生成风格）+ 内存缓存作为 Single Source of Truth（SSOT）+ 乐观更新（含失败回滚）** 架构。

采用**增量迁移**策略：先以 `PostRepository`（含 Post/Comment）作为参考实现打通整套架构，验证模式稳定后再依次迁移其余 5 个 Repository（User/Auth/Notification/Search/Topic）。迁移期间 `provider` 与 Riverpod 共存，已迁移模块从 `MultiProvider` 中移除对应 Provider。

本方案覆盖 **Phase 0~4**（Post 模块完整迁移），其余 5 个 Repository 的迁移作为后续工作列出，模式相同。

---

## Current State Analysis

### 现有架构（基于实际代码探索）

| 层级 | 现状 | 关键文件 |
|------|------|----------|
| 状态管理 | `provider` 包 + `ChangeNotifier` + `setState` | [dependencies.dart](file:///home/annya/playground/Flutter/trans_platform/lib/config/dependencies.dart) |
| DI | `MultiProvider` + `Provider<T>` / `ProxyProvider` 注册 6 个 Repository | [dependencies.dart](file:///home/annya/playground/Flutter/trans_platform/lib/config/dependencies.dart#L28-L71) |
| 数据契约 | Repository abstract + `Result<T>` sealed class（Ok/Error） | [post_repository.dart](file:///home/annya/playground/Flutter/trans_platform/lib/data/repositories/post/post_repository.dart), [result.dart](file:///home/annya/playground/Flutter/trans_platform/lib/utils/result.dart) |
| 数据源 | Remote（HTTP via `ApiClient`）+ Local（mock 样本数据）双实现 | [post_repository_remote.dart](file:///home/annya/playground/Flutter/trans_platform/lib/data/repositories/post/post_repository_remote.dart), [post_repository_local.dart](file:///home/annya/playground/Flutter/trans_platform/lib/data/repositories/post/post_repository_local.dart) |
| 缓存 | 无业务数据缓存；仅 `shared_preferences`（最近搜索）和 `flutter_secure_storage`（token） | [recent_search_store.dart](file:///home/annya/playground/Flutter/trans_platform/lib/data/services/recent_search_store.dart) |
| UI 数据流 | 页面内 `context.read<Repo>()` 直接调用 + `FutureBuilder<Result<T>>` + `setState` 手动管理 loading/error | [post_detail_page.dart](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/post_detail_page.dart#L62-L125) |
| "乐观更新" | **实为悲观更新**：等待 `Result` 返回后才 `setState`，无回滚机制 | [post_card.dart#L169-L219](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/post_card.dart#L169-L219), [comment.dart#L64-L87](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/comment.dart#L64-L87) |

### 核心痛点

1. **无 SSOT**：同一 Post 在 feed / detail / user_profile 三处独立 fetch，状态不同步（详情页点赞后返回列表页看不到更新）
2. **无缓存**：每次导航都重新请求网络，无离线能力
3. **样板代码冗余**：每个页面手动管理 `_isLoading` / `_loadError` / `_data` 三态
4. **非真正乐观更新**：当前实现等 API 成功后才更新 UI，体验不佳
5. **跨页面状态隔离**：`setState` 修改无法广播到其他页面

---

## Target Architecture

```
┌──────────────────────────────────────────────────────────┐
│  UI Layer (ConsumerWidget / ConsumerStatefulWidget)      │
│  ref.watch(provider) → render                            │
│  ref.read(mutationNotifier) → user actions               │
└────────────────────────┬─────────────────────────────────┘
                         │ watch/read
┌────────────────────────▼─────────────────────────────────┐
│  Riverpod Providers Layer (code-generated @riverpod)     │
│  ┌──────────────────┐  ┌────────────────────────────┐    │
│  │ Async Notifiers  │  │ Mutation Notifiers         │    │
│  │ (loaders)        │  │ (optimistic + rollback)    │    │
│  │ postFeedProvider │  │ postInteractionProvider    │    │
│  │ postDetailProv.  │  │ commentMutationProvider    │    │
│  │ postCommentsProv.│  │                            │    │
│  └────────┬─────────┘  └──────────┬─────────────────┘    │
└───────────┼────────────────────────┼─────────────────────┘
            │ read/write             │ read/write (SSOT)
┌───────────▼────────────────────────▼─────────────────────┐
│  In-Memory Cache Layer (SSOT)                            │
│  postCacheProvider   → Map<int, Post> + list query index │
│  commentCacheProvider→ Map<int, Comment> + per-post idx  │
└───────────────────────────┬──────────────────────────────┘
                            │ on cache miss / refresh
┌───────────────────────────▼──────────────────────────────┐
│  Repository Layer (UNCHANGED - reuse existing)           │
│  PostRepository (abstract)                               │
│   ├── PostRepositoryRemote  → ApiClient → HTTP           │
│   └── PostRepositoryLocal   → mock sample data           │
└──────────────────────────────────────────────────────────┘
```

### 关键设计原则

1. **Cache = SSOT**：所有 UI 看到的 Post/Comment 必须来自 cache，Repository 仅作为 cache 的数据源（miss 时回填）
2. **Normalization**：cache 中实体按 ID 存储；列表查询保存为 ID 列表 + 查询 key，避免同一实体多份副本
3. **乐观更新作用于 cache**：mutation notifier 先改 cache → UI 自动 rebuild → 再发 API → 失败回滚 cache
4. **Repository 零改动**：复用现有 `PostRepository` / `PostRepositoryRemote` / `PostRepositoryLocal`，cache 层在上层包装
5. **保留 `Result<T>`**：Repository 返回类型不变，mutation notifier 内部 switch 处理 Ok/Error

---

## Proposed Changes

### Phase 0 — 依赖与脚手架

#### 0.1 更新 [pubspec.yaml](file:///home/annya/playground/Flutter/trans_platform/pubspec.yaml)

在 `dependencies` 中新增：
```yaml
dependencies:
  # ... existing ...
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
```

在 `dev_dependencies` 中新增：
```yaml
dev_dependencies:
  # ... existing ...
  build_runner: ^2.4.13
  riverpod_generator: ^2.4.3
  riverpod_lint: ^2.3.13
  custom_lint: ^0.6.7
```

在 `analysis_options.yaml`（若不存在则新建）中启用 riverpod_lint：
```yaml
analyzer:
  plugins:
    - custom_lint
```

执行 `flutter pub get` 与首次 `dart run build_runner build --delete-conflicting-outputs` 生成 `.g.dart` 文件。

#### 0.2 根节点包裹 ProviderScope

修改 [main.dart](file:///home/annya/playground/Flutter/trans_platform/lib/main.dart)、[main_local.dart](file:///home/annya/playground/Flutter/trans_platform/lib/main_local.dart)、[main_remote.dart](file:///home/annya/playground/Flutter/trans_platform/lib/main_remote.dart)：在 `MultiProvider` 外层包裹 `ProviderScope`，使 Riverpod 与 provider 共存。

```dart
void main() {
  runApp(
    ProviderScope(                        // ← NEW
      child: MultiProvider(
        providers: providersLocal,
        child: const MainApp(),
      ),
    ),
  );
}
```

#### 0.3 新建 `lib/providers/repository_providers.dart`

将现有 Repository 通过 Riverpod 暴露，便于后续 Notifier 注入。依据 `Env.useRemote`（或保留双入口 `main_local.dart` / `main_remote.dart`）选择实现：

```dart
@riverpod
PostRepository postRepository(PostRepositoryRef ref) {
  // 复用 config/dependencies.dart 的选择逻辑
  // local mode → PostRepositoryLocal()
  // remote mode → PostRepositoryRemote(apiClient: ...)
  return _resolvePostRepository();
}
```

> 决策：`ApiClient` 也需对应暴露为 Riverpod provider（`apiClientProvider`），以便 `postRepositoryProvider` 依赖注入。`TokenStorageService` / `CurrentUserProvider` 后续迁移 User/Auth 时再转 Riverpod，本阶段保留 provider 包形式。

---

### Phase 1 — Cache Layer（SSOT）

#### 1.1 新建 `lib/data/cache/post_cache.dart`

设计为 Riverpod `Notifier`（手写，不走 codegen，因为 cache 是纯内存状态、无 async）：

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/post.dart';

part 'post_cache.g.dart';

/// In-memory SSOT for Post entities.
/// Holds normalized Post map + list-query index (query key → ordered post IDs).
class PostCacheState {
  final Map<int, Post> posts;                 // ID → Post
  final Map<String, List<int>> listQueries;   // queryKey → [postIds]

  const PostCacheState({
    Map<int, Post>? posts,
    Map<String, List<int>>? listQueries,
  })  : posts = posts ?? const {},
        listQueries = listQueries ?? const {};

  PostCacheState copyWith({...}) {...}
}

@riverpod
class PostCache extends _$PostCache {
  @override
  PostCacheState build() => const PostCacheState();

  Post? getById(int id) => state.posts[id];

  List<Post> getList(String queryKey) =>
      (state.listQueries[queryKey] ?? [])
          .map((id) => state.posts[id])
          .whereType<Post>()
          .toList();

  /// Upsert single post (used by loaders + optimistic mutations).
  void upsert(Post post) {
    state = state.copyWith(
      posts: {...state.posts, post.id: post},
    );
  }

  /// Bulk upsert + record list query (used by feed/userPosts/topicPosts loaders).
  void upsertAll(String queryKey, List<Post> posts) {
    final newPosts = {...state.posts};
    for (final p in posts) {
      newPosts[p.id] = p;
    }
    state = state.copyWith(
      posts: newPosts,
      listQueries: {...state.listQueries, queryKey: posts.map((p) => p.id).toList()},
    );
  }

  void remove(int id) {
    final newPosts = {...state.posts}..remove(id);
    state = state.copyWith(posts: newPosts);
  }
}
```

#### 1.2 新建 `lib/data/cache/comment_cache.dart`

对称结构，但列表查询 key 改为 `post-{postId}`：

```dart
@riverpod
class CommentCache extends _$CommentCache {
  @override
  CommentCacheState build() => const CommentCacheState();

  Comment? getById(int id) => state.comments[id];
  List<Comment> getByPost(int postId) => /* resolve from listQueries['post-$postId'] */;

  void upsert(Comment c) {...}
  void upsertForPost(int postId, List<Comment> comments) {...}
  void remove(int id) {...}
}
```

#### 1.3 SSOT 流程约定（文档化为代码注释）

- **读取**：AsyncNotifier 加载时先检查 cache 是否命中且未过期（本阶段采用"会话内有效"策略，不做 TTL），命中则直接 emit cache 数据；未命中调用 Repository，结果写入 cache
- **写入**：所有 mutation 必须通过 cache 的 `upsert`/`remove` 修改状态，禁止直接修改 Repository 返回值后跳过 cache
- **失效**：下拉刷新 = 清空对应 listQuery key + 重新 fetch；create/delete 后 invalidate 受影响的 listQuery

---

### Phase 2 — Post Providers（Loaders + Mutations）

#### 2.1 新建 `lib/providers/post_providers.dart`（只读 AsyncNotifier）

```dart
@riverpod
class PostFeed extends _$PostFeed {
  @override
  Future<List<Post>> build() async {
    final repo = ref.read(postRepositoryProvider);
    final cache = ref.read(postCacheProvider.notifier);
    final result = await repo.getFeed();
    switch (result) {
      case Ok(:final value):
        cache.upsertAll('feed', value);   // fill SSOT
        return value;
      case Error(:final error):
        throw error;                      // AsyncError
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(postRepositoryProvider);
      final cache = ref.read(postCacheProvider.notifier);
      final result = await repo.getFeed();
      switch (result) {
        case Ok(:final value):
          cache.upsertAll('feed', value);
          return value;
        case Error(:final error):
          throw error;
      }
    });
  }
}

@riverpod
class PostDetail extends _$PostDetail {
  @override
  Future<Post> build(int postId) async {
    final cache = ref.read(postCacheProvider.notifier);
    // SSOT: try cache first
    final cached = cache.getById(postId);
    if (cached != null) return cached;
    // miss → fetch
    final repo = ref.read(postRepositoryProvider);
    final result = await repo.getPost(postId);
    switch (result) {
      case Ok(:final value):
        cache.upsert(value);
        return value;
      case Error(:final error):
        throw error;
    }
  }
}

@riverpod
class PostComments extends _$PostComments {
  @override
  Future<List<Comment>> build(int postId) async {
    final repo = ref.read(postRepositoryProvider);
    final cache = ref.read(commentCacheProvider.notifier);
    final result = await repo.getPostComments(postId);
    switch (result) {
      case Ok(:final value):
        cache.upsertForPost(postId, value);
        return value;
      case Error(:final error):
        throw error;
    }
  }
}
```

#### 2.2 新建 `lib/providers/post_interaction_providers.dart`（乐观更新 Mutations）

封装 like/unlike/collect/uncollect，统一乐观更新 + 回滚模式：

```dart
@riverpod
class PostInteraction extends _$PostInteraction {
  @override
  void build() {}

  Future<void> toggleLike(int postId) async {
    final cache = ref.read(postCacheProvider.notifier);
    final repo = ref.read(postRepositoryProvider);

    // 1. Snapshot for rollback
    final previous = cache.getById(postId);
    if (previous == null) return;

    // 2. Optimistic upsert (UI rebuilds automatically via cache watchers)
    final optimistic = previous.copyWith(
      liked: !previous.liked,
      likesCount: previous.likesCount + (previous.liked ? -1 : 1),
    );
    cache.upsert(optimistic);

    // 3. API call
    final result = previous.liked
        ? await repo.unlikePost(postId)
        : await repo.likePost(postId);

    // 4. Rollback on failure
    switch (result) {
      case Ok():
        break;
      case Error():
        cache.upsert(previous);   // rollback to snapshot
        ref.read(snackbarProvider.notifier).show('操作失败');
    }
  }

  Future<void> toggleCollect(int postId) async { /* same pattern */ }
}
```

#### 2.3 新建 `lib/providers/comment_mutation_providers.dart`

处理 createComment / deleteComment / toggleCommentLike，乐观更新 `commentCacheProvider`：

```dart
@riverpod
class CommentMutation extends _$CommentMutation {
  @override
  void build() {}

  Future<void> create(int postId, String content) async {
    // Optimistic: insert temp Comment (negative temp id) into cache
    // On Ok: replace temp id with real id from server
    // On Error: remove temp comment + snackbar
  }

  Future<void> delete(int commentId) async {
    // Optimistic: remove from cache immediately
    // On Error: re-fetch list or restore from snapshot
  }

  Future<void> toggleLike(int commentId) async { /* same as post like */ }
}
```

#### 2.4 全局 Snackbar Provider（轻量封装）

新建 `lib/providers/snackbar_provider.dart`，封装 `ScaffoldMessenger` 调用，供 mutation 回滚时复用：

```dart
@riverpod
class Snackbar extends _$Snackbar {
  @override
  void build() {}

  void show(String message) {
    ref.read(rootScaffoldMessengerKeyProvider).currentState
        ?.showSnackBar(SnackBar(content: Text(message)));
  }
}
```

> 决策：需要给 `MainApp` 的 `MaterialApp` 配置一个 `scaffoldMessengerKey`（全局 `GlobalKey<ScaffoldMessengerState>`），避免 mutation notifier 拿不到 `BuildContext`。

---

### Phase 3 — UI 迁移（Post 模块）

| 文件 | 改造点 |
|------|--------|
| [posts_page.dart](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/posts_page.dart) | `StatefulWidget` → `ConsumerWidget`；`_feedFuture` + `FutureBuilder` → `ref.watch(postFeedProvider)` + `AsyncValue.when`；下拉刷新调 `ref.read(postFeedProvider.notifier).refresh()` |
| [post_detail_page.dart](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/post_detail_page.dart) | `StatefulWidget` → `ConsumerStatefulWidget`；`_post`/`_isLoadingPost`/`_loadError` 三态 → `ref.watch(postDetailProvider(widget.postId))`；`_commentsFuture` + `FutureBuilder` → `ref.watch(postCommentsProvider(post.id))`；`_sendComment`/`_deleteComment` 改调 `ref.read(commentMutationProvider.notifier).create/delete` |
| [post_card.dart](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/post_card.dart) | `StatefulWidget` → `ConsumerStatefulWidget`；移除本地 `_liked`/`_likesCount`/`_collected`/`_collectionsCount` 状态；改 `ref.watch(postCacheProvider).getById(widget.post.id)` 读取 SSOT；`_toggleLike`/`_toggleCollect` → `ref.read(postInteractionProvider.notifier).toggleLike/toggleCollect(widget.post.id)` |
| [comment.dart](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/comment.dart) | `_CommentTile` `StatefulWidget` → `ConsumerStatefulWidget`；移除本地 `_liked`/`_likesCount`；改从 `commentCacheProvider` 读取；`_toggleLike` → `ref.read(commentMutationProvider.notifier).toggleLike(widget.comment.id)` |

#### 迁移示例：post_detail_page.dart 评论加载段

**Before**（[post_detail_page.dart#L295-L338](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/post_detail_page.dart#L295-L338)）：
```dart
Widget _buildCommentsSection() {
  return FutureBuilder<Result<List<Comment>>>(
    future: _commentsFuture,
    builder: (_, snapshot) { ... 40 lines of loading/error/data switch ... },
  );
}
```

**After**：
```dart
Widget _buildCommentsSection(int postId) {
  final asyncComments = ref.watch(postCommentsProvider(postId));
  return asyncComments.when(
    loading: () => const Padding(
      padding: EdgeInsets.only(top: 24),
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (e, _) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text('加载评论失败: $e'),
    ),
    data: (comments) => comments.isEmpty
        ? const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: Text('暂无评论'),
          )
        : Padding(
            padding: const EdgeInsets.only(top: 8),
            child: CommentList(
              comments: comments,
              currentUserId: _currentUserId,
              onDeleteRequested: (id) =>
                  ref.read(commentMutationProvider.notifier).delete(id),
            ),
          ),
  );
}
```

---

### Phase 4 — 验证

#### 4.1 静态检查
```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```
要求 0 error、0 warning（riverpod_lint 全绿）。

#### 4.2 功能验证（local mode）
```bash
flutter run --target lib/main_local.dart
```
逐项验证：
- [ ] Feed 列表首次加载显示 → 数据正常
- [ ] 下拉刷新 → 调 `refresh()` 重新 fetch
- [ ] 点击 Post 进入详情 → 显示同一 Post（来自 cache，无新网络请求）
- [ ] 详情页点赞 → UI **立即**变红（乐观更新）
- [ ] 详情页点赞后返回 Feed → Feed 中该 Post 点赞状态保持一致（SSOT 验证）
- [ ] 详情页发评论 → 评论列表立即出现新评论（乐观插入）
- [ ] 删除评论 → 评论立即消失
- [ ] 评论点赞 → 立即变红

#### 4.3 乐观更新回滚验证（remote mode，断网模拟失败）
```bash
flutter run --target lib/main_remote.dart
```
- [ ] 启动后正常加载 → 在 Post 详情页点赞 → **立即**断开网络（关闭后端）→ UI 应：先变红（乐观），API 失败后回滚为未点赞 + 弹"操作失败"
- [ ] 发评论时断网 → 临时评论插入后回滚移除 + 弹错误

#### 4.4 跨页面 SSOT 验证
- [ ] Feed 页给 Post A 点赞 → 进 Post A 详情页 → 详情页显示已点赞
- [ ] 详情页取消点赞 → 返回 Feed → Feed 中 Post A 显示未点赞、count -1

---

## Assumptions & Decisions

| # | 决策 | 理由 |
|---|------|------|
| 1 | 增量迁移：先做 Post 模块 | 用户当前在 `post_detail_page` 工作；Post 涵盖 list/detail/CRUD/interaction 全场景，验证模式最完整；降低单次改动风险 |
| 2 | Riverpod 代码生成风格（`@riverpod` + `riverpod_generator`） | 类型安全、样板少、社区主流；用户已确认 |
| 3 | `provider` 包迁移期保留共存 | 用户确认逐步替换；已迁移模块从 `MultiProvider` 移除对应 Provider，未迁移模块继续用 `provider` |
| 4 | Cache 为纯内存（不持久化） | 用户明确要求"内存缓存"；进程重启数据丢失可接受 |
| 5 | Cache 不做 TTL/过期策略（Phase 1） | 简化首版；下拉刷新即手动失效；后续如需可加 `lastFetchedAt` |
| 6 | Repository 层零改动 | 现有 `PostRepository` 接口 + Remote/Local 双实现质量良好，复用降低风险 |
| 7 | 保留 `Result<T>` sealed class | Repository 返回类型不变；mutation notifier 内部 switch 转 `AsyncValue` |
| 8 | 全局 `scaffoldMessengerKey` 用于回滚提示 | mutation notifier 无 `BuildContext`，需全局 key 调 `ScaffoldMessenger` |
| 9 | 列表查询 cache 用 `queryKey` 字符串索引（如 `'feed'`、`'user-$userId'`、`'topic-$topicId'`） | 规范化存储，同一 Post 在多个 list 中只存一份实体 |
| 10 | 乐观更新始终 snapshot + rollback | 防止网络失败时 UI 状态漂移；`Result.error` 触发 `cache.upsert(previous)` |
| 11 | `ApiClient` / `TokenStorageService` / `CurrentUserProvider` 暂留 provider 包 | User/Auth 模块未迁移，本阶段不动；仅 `PostRepository` 通过 Riverpod 暴露 |
| 12 | 后续迁移顺序建议：User → Auth → Notification → Search → Topic | User 依赖少、UI 多；Auth 涉及 token 流程较复杂放后；Search/Topic 简单收尾 |

---

## File Change Summary

### 新建文件（10 个）
| 路径 | 用途 |
|------|------|
| `lib/providers/repository_providers.dart` | `apiClientProvider`、`postRepositoryProvider` |
| `lib/providers/post_providers.dart` | `postFeedProvider`、`postDetailProvider`、`postCommentsProvider`（loaders） |
| `lib/providers/post_interaction_providers.dart` | `postInteractionProvider`（like/collect 乐观更新） |
| `lib/providers/comment_mutation_providers.dart` | `commentMutationProvider`（create/delete/like 乐观更新） |
| `lib/providers/snackbar_provider.dart` | 全局 snackbar + `rootScaffoldMessengerKeyProvider` |
| `lib/data/cache/post_cache.dart` | `PostCache` Notifier + `PostCacheState`（SSOT） |
| `lib/data/cache/comment_cache.dart` | `CommentCache` Notifier + `CommentCacheState`（SSOT） |
| 上述各 `.dart` 对应的 `.g.dart` | build_runner 生成 |

### 修改文件（6 个）
| 路径 | 改动 |
|------|------|
| [pubspec.yaml](file:///home/annya/playground/Flutter/trans_platform/pubspec.yaml) | 新增 5 个依赖 |
| `analysis_options.yaml` | 启用 `custom_lint` + `riverpod_lint` |
| [main.dart](file:///home/annya/playground/Flutter/trans_platform/lib/main.dart) / [main_local.dart](file:///home/annya/playground/Flutter/trans_platform/lib/main_local.dart) / [main_remote.dart](file:///home/annya/playground/Flutter/trans_platform/lib/main_remote.dart) | 外层包 `ProviderScope`；`MaterialApp` 加 `scaffoldMessengerKey` |
| [posts_page.dart](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/posts_page.dart) | 迁移 ConsumerWidget + `ref.watch(postFeedProvider)` |
| [post_detail_page.dart](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/post_detail_page.dart) | 迁移 ConsumerStatefulWidget + watchers + mutation 调用 |
| [post_card.dart](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/post_card.dart) | 移除本地交互状态，从 cache 读取 + 调 mutation notifier |
| [comment.dart](file:///home/annya/playground/Flutter/trans_platform/lib/ui/posts/comment.dart) | 同 post_card，迁移 `_CommentTile` |

### 不改动文件
- `lib/data/repositories/post/*`（Repository 接口与双实现保持原样）
- `lib/utils/result.dart`（`Result<T>` sealed class 保持）
- `lib/data/services/api/*`（`ApiClient` 保持）
- 其他 5 个 Repository 及其 UI（后续阶段处理）

---

## Future Work（Phase 5+，本次不实施）

按相同模式依次迁移：
1. **UserRepository** → `userCacheProvider` + `userDetailProvider` + `followMutationProvider`；迁移 `user_detail_page.dart`、`user_header.dart`、`user_buttons.dart`、`follow_info_page.dart`
2. **AuthRepository** → `authSessionProvider`；替换 `CurrentUserProvider`（ChangeNotifier）为 Riverpod；迁移 `login_page.dart`、`register_page.dart`、`splash_page.dart` 等；token 流程改走 `tokenStorageProvider`
3. **NotificationRepository** → `notificationCacheProvider` + `notificationListProvider`；迁移 `notification_page.dart`、`activities_page.dart`
4. **SearchRepository** → `searchResultProvider`（无需 cache，搜索结果一次性）；迁移 `search_page.dart`；`recent_search_store.dart` 可保留 shared_preferences
5. **TopicRepository** → `topicCacheProvider` + `topicListProvider`；迁移 `topic_detail_page.dart`、`add_topic_page.dart`
6. 全部迁移完成后，移除 `provider` 包依赖与 `lib/config/dependencies.dart`

---

## Risk & Mitigation

| 风险 | 缓解 |
|------|------|
| `Post.copyWith` 可能不存在或字段不全 | Phase 1 前先检查 [post.dart](file:////home/annya/playground/Flutter/trans_platform/lib/domain/models/post.dart) model，必要时补 `copyWith`（含 `liked`/`likesCount`/`collected`/`collectionsCount` 字段） |
| `Comment` 同上 | 检查 [comment.dart](file:///home/annya/playground/Flutter/trans_platform/lib/domain/models/comment.dart) model |
| Riverpod 与 provider 共存期 `BuildContext` 混用 | 已迁移 UI 用 `ref`，未迁移用 `context`；`ProviderScope` 在最外层包裹即可 |
| build_runner 与现有代码冲突 | 首次 `--delete-conflicting-outputs` 全量生成；后续 `watch` 模式增量 |
| 乐观更新在弱网下用户重复点击 | mutation notifier 内加 `_inFlight` 集合去重（可选，Phase 2 可加） |
