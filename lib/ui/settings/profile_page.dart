import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';

/// Edit user profile page.
///
/// Allows changing nickname and bio.
class ProfilePage extends StatefulWidget {
  final User? existingUser;

  const ProfilePage({super.key, this.existingUser});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nicknameController;
  late TextEditingController _bioController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nicknameController =
        TextEditingController(text: widget.existingUser?.nickname ?? '');
    _bioController =
        TextEditingController(text: widget.existingUser?.bio ?? '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    final bio = _bioController.text.trim();

    if (nickname.isEmpty) {
      setState(() => _errorMessage = '昵称不能为空');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await context.read<UserRepository>().updateUser(
          nickname: nickname,
          bio: bio.isNotEmpty ? bio : null,
        );

    if (!mounted) return;

    switch (result) {
      case Ok<User>():
        Navigator.of(context).pop(true); // return true = saved
      case Error<User>():
        setState(() {
          _isSaving = false;
          _errorMessage = _extractError(result.error);
        });
    }
  }

  String _extractError(Exception e) {
    final s = e.toString();
    final idx = s.indexOf('): ');
    return idx != -1 ? s.substring(idx + 3) : s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('个人资料'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar
          Center(
            child: Stack(
              children: [
                ClipOval(
                  child: SizedBox.fromSize(
                    size: const Size(80, 80),
                    child: widget.existingUser?.avatar != null
                        ? _buildAvatar(widget.existingUser!.avatar!)
                        : Icon(Icons.person, size: 48,
                            color: theme.colorScheme.primary),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Nickname
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              labelText: '昵称',
              border: OutlineInputBorder(),
            ),
            enabled: !_isSaving,
          ),
          const SizedBox(height: 16),

          // Bio
          TextField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: '个人简介',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            enabled: !_isSaving,
          ),
          const SizedBox(height: 16),

          // Error
          if (_errorMessage != null)
            Text(_errorMessage!,
                style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
    );
  }

  Widget _buildAvatar(String url) {
    if (url.startsWith('http')) {
      return Image.network(url, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.person));
    }
    return Image.asset(url, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.person));
  }
}
