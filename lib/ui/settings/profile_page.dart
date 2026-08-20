import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import 'reset_email_page.dart';

/// Edit user profile page.
///
/// Allows changing nickname, bio, avatar, bio header image, and email.
class ProfilePage extends StatefulWidget {
  final User? existingUser;

  const ProfilePage({super.key, this.existingUser});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _picker = ImagePicker();
  late TextEditingController _nicknameController;
  late TextEditingController _bioController;
  XFile? _pickedAvatar;
  XFile? _pickedBioHeaderImg;
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

  Future<void> _pickAvatar() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (image != null) setState(() => _pickedAvatar = image);
  }

  Future<void> _pickBioHeaderImg() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1080,
      maxHeight: 360,
    );
    if (image != null) setState(() => _pickedBioHeaderImg = image);
  }

  Future<void> _navigateToResetEmail() async {
    final hasEmail = widget.existingUser?.email != null &&
        widget.existingUser!.email!.isNotEmpty;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ResetEmailPage(isUpdate: hasEmail)),
    );
    if (result == true && mounted) {
      // Email was updated — pop profile page to trigger refresh.
      if (mounted) Navigator.of(context).pop(true);
    }
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
          avatar: _pickedAvatar?.path,
          bio: bio.isNotEmpty ? bio : null,
          bioHeaderImg: _pickedBioHeaderImg?.path,
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
            child: GestureDetector(
              onTap: _pickAvatar,
              child: Stack(
                children: [
                  ClipOval(
                    child: SizedBox.fromSize(
                      size: const Size(80, 80),
                      child: _buildAvatarWidget(),
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

          // Bio header image
          _buildBioHeaderImgSection(theme),
          const SizedBox(height: 16),

          // Email
          _buildEmailRow(theme),
          const SizedBox(height: 16),

          // Error
          if (_errorMessage != null)
            Text(_errorMessage!,
                style: TextStyle(color: theme.colorScheme.error)),
        ],
      ),
    );
  }

  Widget _buildBioHeaderImgSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('背景图片', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _isSaving ? null : _pickBioHeaderImg,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildBioHeaderImgWidget(theme),
          ),
        ),
      ],
    );
  }

  Widget _buildBioHeaderImgWidget(ThemeData theme) {
    if (_pickedBioHeaderImg != null) {
      return Image.file(
        File(_pickedBioHeaderImg!.path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholderBioHeaderImg(theme),
      );
    }
    final url = widget.existingUser?.bioHeaderImg;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(url, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _placeholderBioHeaderImg(theme));
      }
      return Image.asset(url, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholderBioHeaderImg(theme));
    }
    return _placeholderBioHeaderImg(theme);
  }

  Widget _placeholderBioHeaderImg(ThemeData theme) {
    return Center(
      child: Icon(Icons.add_photo_alternate_outlined,
          size: 40, color: theme.colorScheme.outline),
    );
  }

  Widget _buildEmailRow(ThemeData theme) {
    final email = widget.existingUser?.email;
    return InkWell(
      onTap: _isSaving ? null : _navigateToResetEmail,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '邮箱',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.chevron_right),
        ),
        child: Text(
          email != null && email.isNotEmpty ? email : '点击绑定邮箱',
          style: TextStyle(
            color: email != null && email.isNotEmpty
                ? null
                : theme.colorScheme.outline,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    final theme = Theme.of(context);
    // Picked image takes priority
    if (_pickedAvatar != null) {
      return Image.file(
        File(_pickedAvatar!.path),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            Icon(Icons.person, size: 48, color: theme.colorScheme.primary),
      );
    }
    // Existing avatar from user data
    final url = widget.existingUser?.avatar;
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('http')) {
        return Image.network(url, fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Icon(Icons.person));
      }
      return Image.asset(url, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.person));
    }
    return Icon(Icons.person, size: 48, color: theme.colorScheme.primary);
  }
}