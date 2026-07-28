import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user/user_repository.dart';
import '../../data/services/token_storage_service.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import '../auth/login_page.dart';
import 'about_page.dart';
import 'profile_page.dart';

/// Settings page, WeChat-style.
///
/// Accessible from the gear icon on the home page.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // ── User profile card ──
          _buildProfileCard(context),

          const Divider(height: 1),

          // ── About ──
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),

          const Divider(height: 1),

          // ── Logout ──
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => _handleLogout(context),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                ),
                child: const Text('退出登录', style: TextStyle(fontSize: 16)),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return FutureBuilder<Result<User>>(
      future: context.read<UserRepository>().getCurrentUser(),
      builder: (context, snapshot) {
        final user = switch (snapshot.data) {
          Ok<User>(:final value) => value,
          _ => null,
        };

        return InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfilePage(existingUser: user),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                ClipOval(
                  child: SizedBox.fromSize(
                    size: const Size(56, 56),
                    child: user?.avatar != null
                        ? _buildAvatar(user!.avatar!)
                        : Icon(Icons.person, size: 32,
                            color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                // Name & bio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.nickname ?? '未设置昵称',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.bio!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String url) {
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.person));
    }
    return Image.asset(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.person));
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Capture references before any async gap
    final navigator = Navigator.of(context);
    final storage = context.read<TokenStorageService>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '退出',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Clear stored tokens
    await storage.clearTokens();

    // Navigate back to login, clearing the entire navigation stack
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}
