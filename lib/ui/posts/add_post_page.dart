import 'dart:io';
import 'dart:math';

import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/post/post_repository.dart';
import '../../data/repositories/location/location_repository.dart';
import '../../data/repositories/user/user_repository.dart';
import '../../domain/models/geo_location.dart';
import '../../domain/models/post.dart';
import '../../domain/models/topic.dart';
import '../../domain/models/user.dart';
import '../../utils/result.dart';
import 'add_topic_page.dart';

/// Create new post page (AddPost-Mobile design).
class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<Topic> _topics = [];
  final List<String> _mentionedUsers = [];
  late Future<Result<User>> _userFuture;
  bool _isSubmitting = false;
  bool _isLocating = false;
  String? _locationLabel;

  bool get _canSubmit =>
      !_isSubmitting &&
      (_textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _userFuture = context.read<UserRepository>().getCurrentUser();
    // Rebuild so the "发布" button enable state follows the text.
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage(
      imageQuality: 85,
      // 部分平台不支持 limit 选项，可能一次返回超过剩余数量的图片；
      // 这里兜底：超出 9 张时只保留最近选择的 9 张。
      limit: max(0, 9 - _selectedImages.length),
    );
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 9) {
          _selectedImages.removeRange(0, _selectedImages.length - 9);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  void _insertEmoji() {
    final text = _textController.text;
    final selection = _textController.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final newText = text.replaceRange(start, end, '😊');
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(offset: start + 1);
  }

  Future<void> _addTopics() async {
    final result = await Navigator.of(context).push<List<Topic>>(
      MaterialPageRoute(
        builder: (_) => AddTopicPage(initialSelected: _topics),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _topics
          ..clear()
          ..addAll(result);
      });
    }
  }

  Future<void> _addMentionedUser() async {
    final input = await _promptText('输入用户名');
    if (input == null || input.trim().isEmpty || !mounted) return;
    setState(() => _mentionedUsers.add(input.trim()));
  }

  Future<String?> _promptText(String title) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '请输入'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPost() async {
    
    final content = _textController.text.trim();
    if (content.isEmpty && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容或选择图片')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Pass the selected topic IDs to the post
    final result = await context.read<PostRepository>().createPost(
          content: content,
          location: _locationLabel,
          images:
              _selectedImages.isNotEmpty
                  ? _selectedImages.map((f) => f.path).toList()
                  : null,
          topicIds: _topics.isNotEmpty ? _topics.map((t) => t.id).toList() : null,
        );

    if (!mounted) return;

    switch (result) {
      case Ok<Post>():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发布成功')),
        );
        Navigator.of(context).pop();
      case Error<Post>():
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发布失败: ${_extractError(result.error)}'),
          ),
        );
    }
  }

  String _extractError(Exception e) {
    final s = e.toString();
    final idx = s.indexOf('): ');
    return idx != -1 ? s.substring(idx + 3) : s;
  }

  /// 获取用户当前位置，并调用后端逆地理编码接口解析城市，
  /// 期间在“标记地点”tile 上展示 loading 状态，成功后把城市名替换到副标题。
  Future<void> _markLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLocating = true);
    try {
      final location = Location();

      // 1. 确保系统定位服务已开启。
      if (!await location.serviceEnabled()) {
        final enabled = await location.requestService();
        if (!enabled) {
          if (!mounted) return;
          setState(() => _isLocating = false);
          messenger.showSnackBar(
            const SnackBar(content: Text('定位服务未开启，无法获取位置')),
          );
          return;
        }
      }

      // 2. 检查并申请定位权限。
      var permission = await location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await location.requestPermission();
      }
      if (permission == PermissionStatus.denied ||
          permission == PermissionStatus.deniedForever) {
        if (!mounted) return;
        setState(() => _isLocating = false);
        messenger.showSnackBar(
          const SnackBar(content: Text('未获得定位权限，无法获取位置')),
        );
        return;
      }

      // 3. 获取当前位置（经纬度）。
      final position = await location.getLocation();
      if (!mounted) return;
      final latitude = position.latitude;
      final longitude = position.longitude;

      // 4. 调用后端逆地理编码接口，将坐标解析为城市名称。
      final result = await context
          .read<LocationRepository>()
          .reverseGeocode(latitude: latitude, longitude: longitude);
      if (!mounted) return;

      switch (result) {
        case Ok<GeoLocation>():
          // 成功后不再用 SnackBar，而是把城市名替换到副标题。
          setState(() {
            _isLocating = false;
            _locationLabel = result.value.location;
          });
        case Error<GeoLocation>():
          setState(() => _isLocating = false);
          messenger.showSnackBar(
            SnackBar(content: Text('获取位置失败：${_extractError(result.error)}')),
          );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocating = false);
      messenger.showSnackBar(
        SnackBar(content: Text('获取位置失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            _buildTopBar(cs),
            const Divider(height: 1, color: Color(0xFFE8E0ED)),
            // ── Scrollable content ──
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildComposer(cs),
                    _buildChipsAndToolbar(cs),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Divider(height: 1, color: Color(0xFFE8E0ED)),
                    ),
                    _buildImageSection(cs),
                    const Divider(height: 1, color: Color(0xFFE8E0ED)),
                    _OptionTile(
                      icon: Icons.visibility_outlined,
                      title: '公开可见',
                      subtitle: '点击切换可见范围',
                      onTap: () {},
                    ),
                    const Divider(height: 1, color: Color(0xFFE8E0ED)),
                    _OptionTile(
                      icon: Icons.place_outlined,
                      title: '标记地点',
                      subtitle: _locationLabel ?? '添加你所在的位置',
                      loading: _isLocating,
                      onTap: _markLocation,
                    ),
                  ],
                ),
              ),
            ),
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
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '新建贴文',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ),
            _buildPublishButton(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildPublishButton(ColorScheme cs) {
    final enabled = _canSubmit;
    return InkWell(
      onTap: enabled ? _submitPost : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? cs.primary : const Color(0xFFCAC4D0),
          borderRadius: BorderRadius.circular(18),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                '发布',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? Colors.white
                      : const Color(0xFF938F99),
                ),
              ),
      ),
    );
  }

  Widget _buildComposer(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: FutureBuilder<Result<User>>(
        future: _userFuture,
        builder: (_, snapshot) {
          final user = switch (snapshot.data) {
            Ok<User>(:final value) => value,
            _ => null,
          };
          ImageProvider? image;
          if (user?.avatar != null && user!.avatar!.isNotEmpty) {
            image = user.avatar!.startsWith('http')
                ? NetworkImage(user.avatar!)
                : AssetImage(user.avatar!) as ImageProvider;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: image,
                  child: image == null
                      ? Text(
                          user != null && user.nickname.isNotEmpty
                              ? user.nickname[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        user?.nickname ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    TextField(
                      controller: _textController,
                      enabled: !_isSubmitting,
                      maxLines: null,
                      minLines: 3,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: '分享你的想法…',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: Color(0xFFC4BFCA),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChipsAndToolbar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_topics.isNotEmpty || _mentionedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final topic in _topics)
                    _PillChip(
                      label: '#${topic.name}',
                      onClose: () => setState(() => _topics.remove(topic)),
                    ),
                  for (final user in _mentionedUsers)
                    _PillChip(
                      label: '@$user',
                      onClose: () =>
                          setState(() => _mentionedUsers.remove(user)),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                _ToolbarIcon(
                  icon: Icons.emoji_emotions_outlined,
                  onTap: _insertEmoji,
                ),
                _ToolbarIcon(icon: Icons.tag, onTap: _addTopics),
                _ToolbarIcon(
                  icon: Icons.alternate_email,
                  onTap: _addMentionedUser,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ColorScheme cs) {
    const spacing = 4.0;
    final tileCount =
        _selectedImages.length + (_selectedImages.length < 9 ? 1 : 0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 网格高度跟随内容：根据可用宽度算出每格边长，再按行数计算总高度，
          // 保证每个格子都是正方形，且整体高度随图片数量自适应。
          LayoutBuilder(
            builder: (context, constraints) {
              final tileSize = (constraints.maxWidth - spacing * 2) / 3;
              final rowCount = (tileCount / 3).ceil();
              final gridHeight =
                  rowCount * tileSize + (rowCount - 1) * spacing;
              return SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                  ),
                  itemCount: tileCount,
                  itemBuilder: (context, index) {
                    if (index == _selectedImages.length &&
                        _selectedImages.length < 9) {
                      return _AddPhotoTile(onTap: _pickImages);
                    }
                    return _ImagePreview(
                      file: _selectedImages[index],
                      onDelete: () => _removeImage(index),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 6),
          Text(
            '${_selectedImages.length}/9 张图片',
            style: TextStyle(fontSize: 11, color: cs.outline),
          ),
        ],
      ),
    );
  }
}

// ── Image preview widget ──

class _ImagePreview extends StatelessWidget {
  final XFile file;
  final VoidCallback onDelete;

  const _ImagePreview({required this.file, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // 自适应填充网格格子，尺寸跟随网格单元格，不固定为 80。
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 点击图片时，使用 easy_image_viewer 的 showImageViewer 预览图片，
          // 支持双击缩放与滑动关闭。删除按钮的 GestureDetector 在内层，会优先响应点击，
          // 因此不会误触到预览。
          GestureDetector(
            onTap: () => showImageViewer(
              context,
              Image.file(File(file.path)).image,
              swipeDismissible: true,
              doubleTapZoomable: true,
            ),
            child: Image.file(
              File(file.path),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ──

/// Pill-shaped chip for a selected topic (#...) or mentioned user (@...).
class _PillChip extends StatelessWidget {
  final String label;
  final VoidCallback onClose;

  const _PillChip({required this.label, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 30,
      padding: const EdgeInsets.fromLTRB(11, 3, 7, 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0FF),
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: Icon(Icons.close, size: 10, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ToolbarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: cs.onSurfaceVariant),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        // 不固定尺寸，自适应填满网格单元格。
        decoration: BoxDecoration(
          color: cs.surfaceDim,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                size: 22, color: cs.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              '添加',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// 为 true 时在右侧显示 loading 指示器，并禁用点击。
  final bool loading;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: loading ? null : onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 16, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.outline,
                    ),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
