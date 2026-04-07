import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_home_response_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// ss12 — Left sidebar with leaf categories + product grid on right
class MedicalInventoryProductScreen extends StatefulWidget {
  final String title;
  final List<CategoryWithProducts> leafCategories;

  const MedicalInventoryProductScreen({
    super.key,
    required this.title,
    required this.leafCategories,
  });

  @override
  State<MedicalInventoryProductScreen> createState() =>
      _MedicalInventoryProductScreenState();
}

class _MedicalInventoryProductScreenState
    extends State<MedicalInventoryProductScreen> {
  int _selectedIndex = 0;

  List<CategoryProduct> get _currentProducts =>
      widget.leafCategories[_selectedIndex].products ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(title: widget.title),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left sidebar
          _buildSidebar(),
          // Right product grid
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 90,
      color: Colors.white,
      child: ListView.builder(
        itemCount: widget.leafCategories.length,
        padding: EdgeInsets.only(top: SizeConfig.size8),
        itemBuilder: (context, index) {
          final cat = widget.leafCategories[index];
          final isSelected = _selectedIndex == index;

          return InkWell(
            onTap: () => setState(() => _selectedIndex = index),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size12,
                horizontal: SizeConfig.size6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryColor.withValues(alpha: 0.08)
                    : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected ? AppColors.primaryColor : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Placeholder circle for category icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.secondaryTextColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  CustomText(
                    cat.name ?? '',
                    fontSize: 10,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    color: isSelected
                        ? AppColors.primaryColor
                        : AppColors.secondaryTextColor,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_currentProducts.isEmpty) {
      return Center(
        child: CustomText(
          AppStrings.medicalNoProductsFoundLabel,
          color: AppColors.secondaryTextColor,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double availableWidth = constraints.maxWidth;
        double crossAxisSpacing = 10.0;
        double gridItemWidth = (availableWidth - crossAxisSpacing) / 2;
        double childAspectRatio = gridItemWidth / (gridItemWidth * 1.85);

        return GridView.builder(
          padding: EdgeInsets.all(SizeConfig.size8),
          itemCount: _currentProducts.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) =>
              _productCard(_currentProducts[index]),
        );
      },
    );
  }

  Widget _productCard(CategoryProduct product) {
    final imageUrl = product.images?.firstOrNull?.url;
    final variant = product.variants?.firstOrNull;
    final pricing = variant?.pricing?.firstOrNull;
    final mrp = pricing?.mrp;
    final sellingPrice = pricing?.sellingPrice;
    final discount = (mrp != null && sellingPrice != null && mrp > 0)
        ? (((mrp - sellingPrice) / mrp) * 100).toInt()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.hardEdge,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = constraints.maxHeight * 0.42;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: Colors.grey.shade200,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => LocalAssets(
                            imagePath: AppIconAssets.place_holder_image,
                            boxFix: BoxFit.cover,
                          ),
                        )
                      : LocalAssets(
                          imagePath: AppIconAssets.place_holder_image,
                          boxFix: BoxFit.cover,
                        ),
                ),
              ),

              // Info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      CustomText(
                        product.name ?? '',
                        fontSize: SizeConfig.small,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                      ),
                      if (product.description != null)
                        CustomText(
                          product.description!,
                          fontSize: 10,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          color: AppColors.secondaryTextColor,
                        ),
                      // Price
                      Row(
                        children: [
                          CustomText(
                            '₹${sellingPrice ?? mrp ?? ''}',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mainTextColor,
                          ),
                          if (mrp != null &&
                              sellingPrice != null &&
                              mrp != sellingPrice) ...[
                            SizedBox(width: 4),
                            Text(
                              '₹$mrp',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            SizedBox(width: 4),
                            CustomText(
                              '$discount${AppStrings.medicalPercentOffSuffix.tr}',
                              fontSize: 10,
                              color: AppColors.green00,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
