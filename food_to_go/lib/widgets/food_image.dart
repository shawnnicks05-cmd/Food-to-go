import 'package:flutter/material.dart';

class FoodImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double width;

  const FoodImage({
    super.key,
    required this.imageUrl,
    this.height = 120,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: width,
            color: Colors.grey.shade200,
            child: const Icon(
              Icons.fastfood,
              size: 40,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }
}