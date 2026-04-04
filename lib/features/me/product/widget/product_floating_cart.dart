import 'package:BlueEra/features/me/product/model/inventory_based_search_product_response.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:flutter/material.dart';

class ProductFloatingCart extends StatelessWidget {
  final List<VariantData> selectedProducts;
  final VoidCallback onTap;

  const ProductFloatingCart({
    super.key,
    required this.selectedProducts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayImages = selectedProducts.take(3).map((p) {
      if (p.productInformation.media.isNotEmpty &&
          p.productInformation.media.first.isNotEmpty) {
        return p.productInformation.media.first;
      } else if (p.finalVariant.mediaRelatedToVarient.isNotEmpty &&
          p.finalVariant.mediaRelatedToVarient.first.isNotEmpty) {
        return p.finalVariant.mediaRelatedToVarient.first;
      }
      return null;
    }).toList();

    return FloatingCartWidget(
      itemCount: selectedProducts.length,
      displayImages: displayImages,
      onTap: onTap,
    );
  }
}
