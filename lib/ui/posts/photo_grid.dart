import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/material.dart';

class PhotoGrid extends StatelessWidget {
  final List<String> images;

  const PhotoGrid({super.key, required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _openViewer(context, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildImage(images[index]),
          ),
        );
      },
    );
  }

  void _openViewer(BuildContext context, int index) {
    final providers = images.map<ImageProvider>((url) {
      if (url.startsWith('http')) return NetworkImage(url);
      return AssetImage(url);
    }).toList();

    showImageViewerPager(
      context,
      MultiImageProvider(providers, initialIndex: index),
      swipeDismissible: true,
      doubleTapZoomable: true,
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder,
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder,
    );
  }

  Widget get _placeholder => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
}
