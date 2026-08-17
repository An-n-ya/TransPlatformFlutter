import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/search/search_repository.dart';
import '../../data/repositories/topic/topic_repository.dart';
import '../../domain/models/search_result.dart';
import '../../domain/models/topic.dart';
import '../../utils/result.dart';
import '../widgets/search_field.dart';

/// Topic picker page — select, search and create topics for a new post.
///
/// Follows the AddTopic-Mobile / NewTopic-Mobile designs. Returns the
/// selected topics via [Navigator.pop] when confirmed.
class AddTopicPage extends StatefulWidget {
  /// Topics already selected before opening this page.
  final List<Topic> initialSelected;

  const AddTopicPage({super.key, this.initialSelected = const []});

  @override
  State<AddTopicPage> createState() => _AddTopicPageState();
}

class _AddTopicPageState extends State<AddTopicPage> {
  static const int _maxTopics = 5;

  final _searchController = TextEditingController();
  Timer? _debounce;

  late final List<Topic> _selected = [...widget.initialSelected];
  List<Topic> _topics = [];
  List<Topic> _searchResults = [];
  String? _keyword;
  bool _loading = false;
  bool _error = false;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadHotTopics();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ── Data loading ──

  Future<void> _loadHotTopics() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final result = await context.read<TopicRepository>().getHotTopics();
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Ok<List<Topic>>(:final value):
          _topics = value;
        case Error<List<Topic>>():
          _error = true;
      }
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final keyword = _searchController.text.trim();
      if (keyword.isEmpty) {
        setState(() {
          _keyword = null;
          _searchResults = [];
        });
        return;
      }
      _searchTopics(keyword);
    });
  }

  Future<void> _searchTopics(String keyword) async {
    setState(() => _keyword = keyword);
    final result = await context.read<SearchRepository>().search(
      category: 'topic',
      keyword: keyword,
    );
    if (!mounted || _keyword != keyword) return;
    setState(() {
      _searchResults = switch (result) {
        Ok<SearchResult>(:final value) => value.topics,
        Error<SearchResult>() => const [],
      };
    });
  }

  // ── Selection ──

  bool _isSelected(Topic topic) => _selected.any((e) => e.id == topic.id);

  void _toggle(Topic topic) {
    setState(() {
      if (_isSelected(topic)) {
        _selected.removeWhere((e) => e.id == topic.id);
      } else if (_selected.length < _maxTopics) {
        _selected.add(topic);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('最多选择 $_maxTopics 个话题')),
        );
      }
    });
  }

  void _removeSelected(Topic topic) {
    setState(() => _selected.removeWhere((e) => e.id == topic.id));
  }

  Future<void> _createTopic() async {
    final name = _keyword?.trim();
    if (name == null || name.isEmpty) return;

    setState(() => _isCreating = true);
    final result = await context.read<TopicRepository>().createTopic(
      name: name,
    );
    if (!mounted) return;
    setState(() => _isCreating = false);

    switch (result) {
      case Ok<Topic>(:final value):
        if (_selected.length >= _maxTopics) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('最多选择 $_maxTopics 个话题')),
          );
          return;
        }
        setState(() => _selected.add(value));
        _searchController.clear();
      case Error<Topic>():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('创建话题失败')),
        );
    }
  }

  void _confirm() {
    Navigator.of(context).pop(_selected);
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final searching = _keyword != null && _keyword!.isNotEmpty;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(cs),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SearchField(
                controller: _searchController,
                hintText: '搜索或输入新话题名称…',
              ),
            ),
            if (_selected.isNotEmpty) _buildSelectedChips(cs),
            Expanded(child: _buildContent(cs, searching)),
            _buildBottomBar(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 22),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '添加话题',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
            _ConfirmButton(label: '完成', onTap: _confirm),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChips(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final topic in _selected)
                  _SelectedChip(
                    label: '#${topic.name}',
                    onClose: () => _removeSelected(topic),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${_selected.length}/$_maxTopics',
            style: TextStyle(fontSize: 12, color: cs.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, bool searching) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (!searching) {
      if (_error) return _buildErrorState(cs);
      if (_topics.isEmpty) {
        return Center(
          child: Text('暂无话题', style: TextStyle(color: cs.onSurfaceVariant)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            icon: Icons.local_fire_department,
            title: '热门话题',
            color: cs.primary,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _topics.length,
              itemBuilder: (_, i) {
                final topic = _topics[i];
                return _TopicRow(
                  rank: i + 1,
                  topic: topic,
                  selected: _isSelected(topic),
                  onTap: () => _toggle(topic),
                );
              },
            ),
          ),
        ],
      );
    }

    // Searching
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.search,
          title: '搜索结果',
          color: cs.outline,
        ),
        if (_searchResults.isEmpty)
          _CreateTopicRow(
            keyword: _keyword!,
            creating: _isCreating,
            onCreate: _createTopic,
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (_, i) {
              final topic = _searchResults[i];
              return _TopicRow(
                topic: topic,
                selected: _isSelected(topic),
                onTap: () => _toggle(topic),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
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
          Text('加载失败，请稍后重试', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _loadHotTopics,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: const Border(
          top: BorderSide(color: Color(0xFFE8E0ED)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _confirm,
              child: Text(
                '确认添加 ${_selected.length} 个话题',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ──

class _ConfirmButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ConfirmButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Primary-colored pill chip for a selected topic.
class _SelectedChip extends StatelessWidget {
  final String label;
  final VoidCallback onClose;

  const _SelectedChip({required this.label, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 28,
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(7),
            child: const Icon(Icons.close, size: 10, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Row to create a new topic when search returns no results.
class _CreateTopicRow extends StatelessWidget {
  final String keyword;
  final bool creating;
  final VoidCallback onCreate;

  const _CreateTopicRow({
    required this.keyword,
    required this.creating,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: creating ? null : onCreate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF0EBF7))),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x1A6750A4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: creating
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.add, size: 20, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '创建话题 "$keyword"',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '点击创建并添加这个新话题',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.outline,
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

/// A selectable topic row — optional rank number, participants count,
/// and a checkbox on the right.
class _TopicRow extends StatelessWidget {
  final int? rank;
  final Topic topic;
  final bool selected;
  final VoidCallback onTap;

  const _TopicRow({
    this.rank,
    required this.topic,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rankColor = switch (rank) {
      1 => const Color(0xFFD4183D),
      2 => const Color(0xFFF9A825),
      3 => cs.primary,
      _ => const Color(0xFFC4BFCA),
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF4F0FF),
          border: Border(bottom: BorderSide(color: Color(0xFFF0EBF7))),
        ),
        child: Row(
          children: [
            if (rank != null) ...[
              SizedBox(
                width: 32,
                child: Text(
                  '$rank',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: rankColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${topic.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  if (topic.participantsCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${_formatCount(topic.participantsCount)} 次参与',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _TopicCheckbox(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _TopicCheckbox extends StatelessWidget {
  final bool selected;

  const _TopicCheckbox({required this.selected});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? cs.primary : Colors.transparent,
        border: Border.all(
          color: selected ? cs.primary : const Color(0xFFCAC4D0),
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 13, color: Colors.white)
          : null,
    );
  }
}

/// Format a large participant count, e.g. 3280000 → "328万".
String _formatCount(int count) {
  if (count >= 100000000) {
    final value = count / 100000000;
    return value == value.roundToDouble()
        ? '${value.toInt()}亿'
        : '${value.toStringAsFixed(1)}亿';
  }
  if (count >= 10000) {
    final value = count / 10000;
    return value == value.roundToDouble()
        ? '${value.toInt()}万'
        : '${value.toStringAsFixed(1)}万';
  }
  return '$count';
}
