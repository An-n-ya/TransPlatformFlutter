import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/search/search_repository.dart';
import '../../domain/models/search_result.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../user/user_detail_page.dart';

/// Search page — search users and topics by keyword.
///
/// Queries both the `user` and `topic` categories and groups the
/// results into two sections, following the Search-Mobile design.
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

  String? _keyword;
  SearchResult? _usersResult;
  SearchResult? _topicsResult;
  bool _loading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialKeyword ?? '';
    final initial = widget.initialKeyword?.trim();
    if (initial != null && initial.isNotEmpty) {
      _search(initial);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
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

  void _clear() {
    _controller.clear();
    setState(() {
      _keyword = null;
      _usersResult = null;
      _topicsResult = null;
      _hasError = false;
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
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(child: _buildSearchField(cs)),
                  ],
                ),
              ),
            ),
            // ── Results ──
            Expanded(child: _buildBody(cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ColorScheme cs) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: _search,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: '搜索用户、话题...',
          hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (_, value, __) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _clear,
                  ),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_keyword == null) return _buildEmptyState(cs);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_hasError) return _buildErrorState(cs);

    final users = _usersResult?.users ?? const <User>[];
    // final topics = _topicsResult?.topics ?? const <SearchTopic>[];
    if (users.isEmpty) return _buildNoResults(cs);
    // if (users.isEmpty && topics.isEmpty) return _buildNoResults(cs);

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.zero,
      children: [
        if (users.isNotEmpty) _buildUserSection(users, cs),
        // if (topics.isNotEmpty) _buildTopicSection(topics, cs),
      ],
    );
  }

  // ── Sections ──

  Widget _buildUserSection(List<User> users, ColorScheme cs) {
    return Container(
      // 8px bottom separator between the user and topic sections
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFDED8E1), width: 8)),
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('用户', cs),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                for (var i = 0; i < users.length; i++) ...[
                  _buildUserRow(users[i], cs),
                  if (i < users.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicSection(List<SearchTopic> topics, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('话题', cs),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < topics.length; i++) ...[
                  _buildTopicRow(topics[i], cs),
                  if (i < topics.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 3),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFCAC4D0))),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          color: const Color(0xFF49454F),
        ),
      ),
    );
  }

  // ── Rows ──

  Widget _buildUserRow(User user, ColorScheme cs) {
    final secondary = user.username.isNotEmpty
        ? user.username
        : 'ID: ${user.id}';
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => UserDetailPage(user: user)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _buildAvatar(user, cs),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicRow(SearchTopic topic, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            topic.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${topic.participantsCount} 人参与',
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(User user, ColorScheme cs) {
    ImageProvider? image;
    if (user.avatar != null && user.avatar!.isNotEmpty) {
      image = user.avatar!.startsWith('http')
          ? NetworkImage(user.avatar!)
          : AssetImage(user.avatar!) as ImageProvider;
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: cs.primaryContainer,
      backgroundImage: image,
      child: image == null
          ? Text(
              user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : '?',
              style: TextStyle(
                color: cs.onPrimaryContainer,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            )
          : null,
    );
  }

  // ── States ──

  Widget _buildEmptyState(ColorScheme cs) {
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
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
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
