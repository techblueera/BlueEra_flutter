import 'package:BlueEra/features/me/manufacturer/model/manufacturer_product_catalog_response.dart';
import 'package:BlueEra/widgets/floating_cart_widget.dart';
import 'package:flutter/material.dart';

class ManufacturerProductFloatingCart extends StatelessWidget {
  final List<ManufacturerSelectedVariant> selectedProducts;
  final VoidCallback onTap;

  const ManufacturerProductFloatingCart({
    super.key,
    required this.selectedProducts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayImages = selectedProducts.take(3).map((p) {
      final url = p.primaryImageUrl;
      return url.isEmpty ? null : url;
    }).toList();

    return FloatingCartWidget(
      itemCount: selectedProducts.length,
      displayImages: displayImages,
      onTap: onTap,
    );
  }
}
