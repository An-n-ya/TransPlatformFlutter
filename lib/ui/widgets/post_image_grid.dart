import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';

/// Square image grid (1 image full-width, otherwise 2 per row) that
/// opens a full-screen pager on tap.
class PostImageGrid extends StatelessWidget {
  final List<String> images;
  final double borderRadius;

  const PostImageGrid({
    super.key,
    required this.images,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    final crossAxisCount = images.length <= 3 ? images.length : 3;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final url = images[index];
        return GestureDetector(
          onTap: () => _openViewer(context, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              color: cs.surfaceContainerHighest,
              child: Image(
                image: _providerOf(url),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  ImageProvider _providerOf(String url) => url.startsWith('http')
      ? NetworkImage(url)
      : AssetImage(url) as ImageProvider;

  void _openViewer(BuildContext context, int index) {
    final providers = images.map(_providerOf).toList();

    showImageViewerPager(
      context,
      MultiImageProvider(providers, initialIndex: index),
      swipeDismissible: true,
      doubleTapZoomable: true,
    );
  }
}
