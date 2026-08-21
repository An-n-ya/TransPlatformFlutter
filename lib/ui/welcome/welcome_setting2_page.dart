import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import 'welcome_page.dart';

/// Welcome step 2/2 — upload an avatar from the gallery.
///
/// Persists the avatar via `PUT /api/v1/users/me` before continuing.
class WelcomeSetting2Page extends StatefulWidget {
  const WelcomeSetting2Page({super.key});

  @override
  State<WelcomeSetting2Page> createState() => _WelcomeSetting2PageState();
}

class _WelcomeSetting2PageState extends State<WelcomeSetting2Page> {
  final _picker = ImagePicker();
  String? _uploadedPath;
  bool _isSaving = false;
  String? _errorMessage;

  void _skip() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WelcomePage()));
  }

  /// Picks an image from the gallery and shows it as the avatar preview.
  Future<void> _handleAvatarPick() async {
    if (_isSaving) return;
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (image != null && mounted) {
      setState(() => _uploadedPath = image.path);
    }
  }

  Future<void> _finish() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await context.read<UserRepository>().updateUser(
      avatar: _uploadedPath,
    );
    if (!mounted) return;

    switch (result) {
      case Ok<User>():
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const WelcomePage()));
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
    return Scaffold(
      backgroundColor: const Color(0xFFFEF7FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    _buildTopBar(),
                    const SizedBox(height: 32),
                    _buildContent(),
                    const Spacer(),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB3261E),
                          ),
                        ),
                      ),
                    _buildFinishButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Color(0xFF1D1B20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Step indicator: 2/2
            const Row(
              children: [
                _StepBar(active: true),
                SizedBox(width: 8),
                _StepBar(active: true),
                SizedBox(width: 8),
                Text(
                  '2 / 2',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.4,
                    color: Color(0xFF49454F),
                  ),
                ),
              ],
            ),
          ],
        ),
        TextButton(
          onPressed: _isSaving ? null : _skip,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF49454F),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            '跳过',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Avatar preview (tappable → gallery)
        GestureDetector(
          onTap: _handleAvatarPick,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD8E4),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: _uploadedPath != null
                    ? Image.file(
                        File(_uploadedPath!),
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      )
                    : const Icon(
                        Icons.person_outline,
                        size: 44,
                        color: Color(0xFF1C1B1F),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8DEF8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFEF7FF),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.photo_camera,
                    size: 14,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '选择头像',
          style: TextStyle(
            fontSize: 28,
            height: 36 / 28,
            color: Color(0xFF1C1B1F),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '上传一张图片作为您的头像',
          style: TextStyle(
            fontSize: 14,
            height: 21 / 14,
            letterSpacing: 0.25,
            color: Color(0xFF49454F),
          ),
        ),
        const SizedBox(height: 24),
        // Upload from gallery
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            // FIXME: 复用Avatar Preview的onTap逻辑。
            onPressed: _isSaving ? null : _handleAvatarPick,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF49454F),
              side: const BorderSide(color: Color(0xFF79747E)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
            ),
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: const Text(
              '从相册上传头像',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishButton() {
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: _isSaving ? null : _finish,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF6750A4),
          disabledBackgroundColor: const Color(0x806750A4),
          foregroundColor: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                '完成设置',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
      ),
    );
  }
}

/// A short segment of the step indicator (active → primary, else outline).
class _StepBar extends StatelessWidget {
  final bool active;

  const _StepBar({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 24 : 16,
      height: 4,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF6750A4) : const Color(0xFFCAC4D0),
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}
