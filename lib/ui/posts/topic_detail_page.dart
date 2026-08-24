import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/models/topic.dart';
import '../../utils/result.dart';
import 'post_card.dart';

/// Topic detail page — shows all posts under a topic.
///
/// Fetches posts via the unified query endpoint
/// (`GET /api/v1/posts` with body `{"topicId": ...}`).
class TopicDetailPage extends StatefulWidget {
  final Topic topic;

  const TopicDetailPage({super.key, required this.topic});

  @override
  State<TopicDetailPage> createState() => _TopicDetailPageState();
}

class _TopicDetailPageState extends State<TopicDetailPage> {
  late Future<Result<List<Post>>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  void _loadPosts() {
    _postsFuture =
        context.read<PostRepository>().getPostsByTopic(widget.topic.id);
  }

  Future<void> _refreshPosts() async {
    final future =
        context.read<PostRepository>().getPostsByTopic(widget.topic.id);
    setState(() {
      _postsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag, size: 20, color: cs.primary),
            const SizedBox(width: 4),
            Text(widget.topic.name),
          ],
        ),
      ),
      body: FutureBuilder<Result<List<Post>>>(
        future: _postsFuture,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return switch (snapshot.data!) {
            Ok<List<Post>>(:final value) => value.isEmpty
                ? const Center(child: Text('暂无贴文'))
                : PostFeed(posts: value, onRefresh: _refreshPosts),
            Error<List<Post>>() => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: cs.error),
                    const SizedBox(height: 16),
                    Text('加载失败',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => setState(_loadPosts),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}
