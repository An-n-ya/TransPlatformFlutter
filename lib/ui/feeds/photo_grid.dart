import 'package:flutter/material.dart';

class PhotoGrid extends StatelessWidget {
  final List<String> images = [
    'assets/images/avatar.jpg',
    'assets/images/avatar.jpg',
    'assets/images/avatar.jpg',
    'assets/images/avatar.jpg',
    'assets/images/avatar.jpg',
    'assets/images/avatar.jpg',
    'assets/images/avatar.jpg',
    'assets/images/avatar.jpg',
  ];

  PhotoGrid({super.key});

  @override
  Widget build(BuildContext context) {
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(images[index], fit: BoxFit.cover),
        );
      },
    );
  }
}
