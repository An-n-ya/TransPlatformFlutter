import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../posts/post_card.dart';
import 'user_buttons.dart';

/// Followers / followees list page.
///
/// - [isFollowerPage] = true  → 粉丝列表 (`/api/v1/users/{id}/followers`)
/// - [isFollowerPage] = false → 关注列表 (`/api/v1/users/{id}/followees`)
class FollowInfoPage extends StatefulWidget {
  final int userId;
  final bool isFollowerPage;

  const FollowInfoPage({
    super.key,
    required this.userId,
    this.isFollowerPage = false,
  });

  @override
  State<FollowInfoPage> createState() => _FollowInfoPageState();
}

class _FollowInfoPageState extends State<FollowInfoPage> {
  late Future<Result<List<User>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  Future<Result<List<User>>> _loadUsers() {
    final repo = context.read<UserRepository>();
    return widget.isFollowerPage
        ? repo.getFollowers(widget.userId)
        : repo.getFollowees(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isFollowerPage ? '粉丝' : '关注')),
      body: FutureBuilder<Result<List<User>>>(
        future: _usersFuture,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return switch (snapshot.data!) {
            Ok<List<User>>(:final value) => value.isEmpty
                ? const Center(child: Text('暂无数据'))
                : ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (_, i) => _UserRow(user: value[i]),
                  ),
            Error<List<User>>() => const Center(child: Text('加载失败')),
          };
        },
      ),
    );
  }
}

/// Single user row: avatar + nickname, with a quick follow button.
class _UserRow extends StatelessWidget {
  final User user;

  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return PostHeader(
      user: user,
      subtitle: Text(user.bio ?? ''),
      trailing: UserFollowButton(targetUser: user),
    );
  }
}
