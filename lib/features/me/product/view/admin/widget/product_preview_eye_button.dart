import 'dart:ui';

import 'package:flutter/material.dart';

/// Small circular "view" affordance shown on product cards so users know a tap
/// opens the product detail bottom sheet. Frosted-glass look: the image behind
/// is blurred and tinted with translucent black, with a white
/// `visibility_outlined` glyph on top — consistent everywhere the inventory
/// bottom sheet is used.
class ProductPreviewEyeButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const ProductPreviewEyeButton({
    super.key,
    required this.onTap,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.visibility_outlined,
              color: Colors.white,
              size: size * 0.53,
            ),
          ),
        ),
      ),
    );
  }
}
