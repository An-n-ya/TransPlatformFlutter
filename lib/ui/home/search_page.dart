import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/search/search_repository.dart';
import '../../data/repositories/topic/topic_repository.dart';
import '../../data/services/recent_search_store.dart';
import '../../domain/models/search_result.dart';
import '../../domain/models/topic.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../user/user_detail_page.dart';
import '../posts/topic_detail_page.dart';
import '../widgets/search_field.dart';

/// Search page — search users and topics by keyword.
///
/// The idle state shows recent searches (persisted in SharedPreferences)
/// and hot topics. Searching queries both the `user` and `topic`
/// categories and groups the results into two sections.
class SearchPage extends StatefulWidget {
  /// Keyword to search immediately when the page opens.
  final String? initialKeyword;

  const SearchPage({super.key, this.initialKeyword});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _recentStore = RecentSearchStore();

  Timer? _debounce;
  String? _keyword;
  SearchResult? _usersResult;
  SearchResult? _topicsResult;
  bool _loading = false;
  bool _hasError = false;

  List<String> _recentSearches = [];
  List<Topic> _hotTopics = [];

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialKeyword ?? '';
    _loadRecents();
    _loadHotTopics();
    final initial = widget.initialKeyword?.trim();
    if (initial != null && initial.isNotEmpty) {
      _search(initial);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final list = await _recentStore.load();
    if (!mounted) return;
    setState(() => _recentSearches = list);
  }

  Future<void> _loadHotTopics() async {
    final result = await context.read<TopicRepository>().getHotTopics();
    if (!mounted) return;
    setState(() {
      _hotTopics = switch (result) {
        Ok<List<Topic>>(:final value) => value,
        Error<List<Topic>>() => const [],
      };
    });
  }

  void _saveRecent(String keyword) {
    _recentStore.save(keyword).then((list) {
      if (mounted) setState(() => _recentSearches = list);
    });
  }

  /// Debounced live search: triggered on every keystroke. Cleared text
  /// returns to the idle state (recent searches + hot topics).
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final keyword = value.trim();
    if (keyword.isEmpty) {
      setState(() {
        _keyword = null;
        _usersResult = null;
        _topicsResult = null;
        _hasError = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(keyword),
    );
  }

  /// Commits a search explicitly (keyboard search action): saves the
  /// keyword to recents and searches immediately.
  void _submitSearch(String value) {
    _debounce?.cancel();
    final keyword = value.trim();
    if (keyword.isEmpty) return;
    _saveRecent(keyword);
    _search(keyword);
  }

  void _searchFromTap(String keyword) {
    _controller.text = keyword;
    _controller.selection = TextSelection.collapsed(offset: keyword.length);
    _saveRecent(keyword);
    _search(keyword);
  }

  Future<void> _search(String rawKeyword) async {
    final keyword = rawKeyword.trim();
    if (keyword.isEmpty) return;

    setState(() {
      _keyword = keyword;
      _loading = true;
      _hasError = false;
    });

    final repo = context.read<SearchRepository>();
    final results = await Future.wait([
      repo.search(category: 'user', keyword: keyword),
      repo.search(category: 'topic', keyword: keyword),
    ]);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _usersResult = switch (results[0]) {
        Ok<SearchResult>(:final value) => value,
        Error<SearchResult>() => null,
      };
      _topicsResult = switch (results[1]) {
        Ok<SearchResult>(:final value) => value,
        Error<SearchResult>() => null,
      };
      _hasError = _usersResult == null && _topicsResult == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top search bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SearchField(
                      controller: _controller,
                      focusNode: _focusNode,
                      hintText: '搜索用户、话题...',
                      onChanged: _onSearchChanged,
                      onSubmitted: _submitSearch,
                    ),
                  ),
                ],
              ),
            ),
            // ── Content ──
            Expanded(child: _buildBody(cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_keyword == null) return _buildInitialState(cs);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_hasError) return _buildErrorState(cs);

    final users = _usersResult?.users ?? const <User>[];
    final topics = _topicsResult?.topics ?? const <Topic>[];
    if (users.isEmpty && topics.isEmpty) return _buildNoResults(cs);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.zero,
      children: [
        if (users.isNotEmpty)
          _buildUserSection(users, _usersResult?.totalElements, cs),
        if (users.isNotEmpty && topics.isNotEmpty)
          const ColoredBox(color: Color(0x99DED8E1), child: SizedBox(height: 8)),
        if (topics.isNotEmpty)
          _buildTopicSection(topics, _topicsResult?.totalElements, cs),
      ],
    );
  }

  // ── Initial state: recent searches + hot topics ──

  Widget _buildInitialState(ColorScheme cs) {
    final hasRecent = _recentSearches.isNotEmpty;
    final hasHot = _hotTopics.isNotEmpty;

    if (!hasRecent && !hasHot) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 48, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text(
              '搜索用户或话题',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.zero,
      children: [
        if (hasRecent) ...[
          const _SectionHeader(
            title: '最近搜索',
            padding: EdgeInsets.fromLTRB(12, 6, 12, 14),
          ),
          for (final keyword in _recentSearches)
            _RecentRow(
              keyword: keyword,
              onTap: () => _searchFromTap(keyword),
            ),
        ],
        if (hasRecent && hasHot)
          const ColoredBox(
            color: Color(0x99DED8E1),
            child: SizedBox(height: 8),
          ),
        if (hasHot) ...[
          const _SectionHeader(
            title: '热门话题',
            padding: EdgeInsets.fromLTRB(12, 6, 12, 14),
          ),
          for (final topic in _hotTopics)
            _TopicRow(
              topic: topic,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TopicDetailPage(topic: topic),
                ),
              ),
            ),
        ],
      ],
    );
  }

  // ── Result sections ──

  Widget _buildUserSection(
    List<User> users,
    int? totalElements,
    ColorScheme cs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: '用户', count: '${totalElements ?? users.length} 个结果'),
        for (final user in users)
          _UserRow(
            user: user,
            keyword: _keyword,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => UserDetailPage(user: user)),
            ),
          ),
      ],
    );
  }

  Widget _buildTopicSection(
    List<Topic> topics,
    int? totalElements,
    ColorScheme cs,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: '话题',
          count: '${totalElements ?? topics.length} 个结果',
        ),
        for (final topic in topics)
          _TopicRow(
            topic: topic,
            keyword: _keyword,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TopicDetailPage(topic: topic),
              ),
            ),
          ),
      ],
    );
  }

  // ── States ──

  Widget _buildNoResults(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          '未找到与 "$_keyword" 相关的结果',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: cs.error),
          const SizedBox(height: 16),
          Text('搜索失败，请稍后重试', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => _search(_keyword!),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ──

/// Section header — title + optional result count.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? count;
  final EdgeInsetsGeometry padding;

  const _SectionHeader({
    required this.title,
    this.count,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 4),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.96,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              count!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A recent search row — clock icon, keyword, trailing arrow.
class _RecentRow extends StatelessWidget {
  final String keyword;
  final VoidCallback onTap;

  const _RecentRow({required this.keyword, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 19, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF3EDF7),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 18, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                keyword,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(Icons.north_east, size: 14, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// A user result row — avatar, nickname (keyword highlighted), @username.
class _UserRow extends StatelessWidget {
  final User user;
  final String? keyword;
  final VoidCallback onTap;

  const _UserRow({required this.user, this.keyword, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    ImageProvider? image;
    if (user.avatar != null && user.avatar!.isNotEmpty) {
      image = user.avatar!.startsWith('http')
          ? NetworkImage(user.avatar!)
          : AssetImage(user.avatar!) as ImageProvider;
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: image != null
                  ? Image(image: image, fit: BoxFit.cover)
                  : Center(
                      child: Text(
                        user.nickname.isNotEmpty
                            ? user.nickname[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4F378A),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: _highlightSpans(
                        user.nickname,
                        keyword,
                        cs.primary,
                        TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.username.isNotEmpty
                        ? '@${user.username}'
                        : 'ID: ${user.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A topic result row — tag icon, name (keyword highlighted), participants.
class _TopicRow extends StatelessWidget {
  final Topic topic;
  final String? keyword;
  final VoidCallback onTap;

  const _TopicRow({required this.topic, this.keyword, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.tag, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: _highlightSpans(
                        topic.name,
                        keyword,
                        cs.primary,
                        TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${topic.participantsCount} 人参与',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds [TextSpan]s for [text], coloring each occurrence of [keyword]
/// with [highlightColor].
List<TextSpan> _highlightSpans(
  String text,
  String? keyword,
  Color highlightColor,
  TextStyle baseStyle,
) {
  if (keyword == null || keyword.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }
  final lower = text.toLowerCase();
  final kw = keyword.toLowerCase();
  final spans = <TextSpan>[];
  var start = 0;
  while (true) {
    final idx = lower.indexOf(kw, start);
    if (idx == -1) {
      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
      }
      break;
    }
    if (idx > start) {
      spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
    }
    spans.add(
      TextSpan(
        text: text.substring(idx, idx + kw.length),
        style: baseStyle.copyWith(color: highlightColor),
      ),
    );
    start = idx + kw.length;
  }
  return spans;
}
