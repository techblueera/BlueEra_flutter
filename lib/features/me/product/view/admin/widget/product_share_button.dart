import 'dart:ui';

import 'package:BlueEra/core/services/share_service.dart';
import 'package:flutter/material.dart';

/// Small circular "share" affordance shown on product cards (admin and
/// customer side). Frosted-glass look mirroring [ProductPreviewEyeButton]
/// so it reads as a sibling action when overlaid on the product image.
///
/// On tap it opens the OS share sheet with the product's dynamic deep
/// link (`https://beapp.in/app/product/{productId}`) via
/// [ShareService.shareProduct] — the link auto-carries the signed-in
/// BDM's referral code when eligible. Renders nothing when [productId]
/// is empty so cards without a resolvable id simply omit the action.
class ProductShareButton extends StatelessWidget {
  final String? productId;
  final String? productName;
  final double size;

  const ProductShareButton({
    super.key,
    required this.productId,
    this.productName,
    this.size = 30,
  });

  @override
  Widget build(BuildContext context) {
    final id = productId;
    if (id == null || id.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => ShareService.instance.shareProduct(
        productId: id,
        productName: productName,
      ),
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
              Icons.share_outlined,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
