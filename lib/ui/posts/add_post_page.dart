import 'package:flutter/material.dart';

/// Create new post page.
///
/// Allows entering text, attaching photos, mentioning users,
/// adding topics, setting visibility, and marking a location.
/// Backend integration is intentionally left out for now.
class AddPostPage extends StatefulWidget {
  const AddPostPage({super.key});

  @override
  State<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('新建贴文'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: '分享瞬间...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 12,
              children: [
                _OutlinedChip(
                  icon: Icons.person_outline,
                  label: '用户',
                  onTap: () {},
                ),
                _OutlinedChip(
                  icon: Icons.tag_outlined,
                  label: '话题',
                  onTap: () {},
                ),
              ],
            ),
          ),
          Divider(color: cs.outline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/image.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _AddPhotoButton(onTap: () {}),
              ],
            ),
          ),
          const Divider(height: 1),
          _ListTileButton(
            label: '公开可见',
            onTap: () {},
          ),
          const Divider(height: 1),
          _ListTileButton(
            label: '标记位置',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

/// Outlined chip with leading icon used for user/topic mentions.
class _OutlinedChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlinedChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: cs.onSurface,
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

/// Square button used to add more photos.
class _AddPhotoButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPhotoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: cs.surfaceDim,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.add, color: cs.onSurfaceVariant),
      ),
    );
  }
}

/// Tappable list row for visibility and location options.
class _ListTileButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ListTileButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
