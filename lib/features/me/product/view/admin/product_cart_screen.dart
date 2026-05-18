import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/price_row.dart';
import 'package:BlueEra/features/me/product/controller/inventory_controller.dart';
import 'package:BlueEra/features/me/product/controller/product_controller.dart';
import 'package:BlueEra/features/me/product/model/inventory_based_search_product_response.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ProductCartScreen extends StatefulWidget {
  const ProductCartScreen({super.key});

  @override
  State<ProductCartScreen> createState() => _ProductCartScreenState();
}

class _ProductCartScreenState extends State<ProductCartScreen> {
  final productController = getOrPut(() => ProductController());
  late final InventoryController inventoryController;

  /// Per-variant inline error message keyed by variant id. Populated
  /// when the merchant types a selling price that exceeds that
  /// variant's MRP — used to block both the save into
  /// `inventoryController.variantSellingPrice` and the publish CTA.
  final Map<String, String?> _priceErrors = {};

  @override
  void initState() {
    super.initState();
    inventoryController = Get.put(InventoryController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final product in productController.selectedProducts) {
        final id = product.finalVariant.id;
        inventoryController.variantSelection[id] = true;
      }
    });
  }

  void _onSellingPriceChanged(String variantId, String value, double mrp) {
    final trimmed = value.trim();
    final parsed = double.tryParse(trimmed);
    if (parsed != null && parsed > mrp) {
      setState(() {
        _priceErrors[variantId] =
            'Selling price can’t exceed MRP (${AppConstants.rupeeSymbol}${mrp.toStringAsFixed(0)})';
      });
      // Don't persist an invalid price — the existing value stays so
      // publish still uses something sensible.
      return;
    }
    if (_priceErrors[variantId] != null) {
      setState(() => _priceErrors[variantId] = null);
    }
    inventoryController.updateSellingPrice(variantId, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Review & Publish',
      ),
      bottomNavigationBar: _buildBottomBar(context),
      body: Obx(() {
        final products = productController.selectedProducts;

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: AppColors.greyE5,
                ),
                SizedBox(height: SizeConfig.size15),
                CustomText(
                  'No products selected',
                  fontSize: SizeConfig.large,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header summary
            _buildHeader(products.length),

            // Product list
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size12,
                  vertical: SizeConfig.size8,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildCartCard(products[index], index);
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size15,
        vertical: SizeConfig.size12,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size10,
              vertical: SizeConfig.size4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomText(
              '$count ${count == 1 ? 'Product' : 'Products'}',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
          Spacer(),
          CustomText(
            'Set selling price for each variant',
            fontSize: SizeConfig.extraSmall,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCartCard(VariantData variantData, int index) {
    final product = variantData.productInformation;
    final variant = variantData.finalVariant;

    // Build variant attribute string
    final attrParts = variant.attributes.entries.map((entry) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      if (key == 'color' && value is Map<String, dynamic>) {
        return value['color_name'] ?? '';
      } else if (value != null) {
        return value.toString();
      }
      return '';
    }).where((attr) => attr.isNotEmpty);

    final variantLabel = attrParts.isNotEmpty ? attrParts.join(', ') : '';

    // Pick best image: product media > variant media > placeholder
    // Product media has full URLs; variant media may have relative paths
    String imageUrl = '';
    if (product.media.isNotEmpty && product.media.first.isNotEmpty) {
      imageUrl = product.media.first;
    } else if (variant.mediaRelatedToVarient.isNotEmpty &&
        variant.mediaRelatedToVarient.first.isNotEmpty) {
      imageUrl = variant.mediaRelatedToVarient.first;
    }

    final discount = variant.mrp > 0
        ? ((variant.mrp - variant.sellingPrice) / variant.mrp * 100).round()
        : 0;

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Top row: image + info + remove
          Padding(
            padding: EdgeInsets.all(SizeConfig.size12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.fillColor,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.fillColor,
                              child: LocalAssets(
                                imagePath: AppIconAssets.place_holder_image,
                                boxFix: BoxFit.cover,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.fillColor,
                            child: LocalAssets(
                              imagePath: AppIconAssets.place_holder_image,
                              boxFix: BoxFit.cover,
                            ),
                          ),
                  ),
                ),

                SizedBox(width: SizeConfig.size12),

                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        product.name,
                        fontSize: SizeConfig.medium,
                        color: AppColors.mainTextColor,
                        fontWeight: FontWeight.w600,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (variantLabel.isNotEmpty) ...[
                        SizedBox(height: SizeConfig.size4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.boxBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: CustomText(
                            variantLabel,
                            fontSize: SizeConfig.extraSmall,
                            color: AppColors.secondaryTextColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                      SizedBox(height: SizeConfig.size8),
                      PriceRow(
                        sellingPrice: '${AppConstants.rupeeSymbol}${variant.sellingPrice.toStringAsFixed(0)}',
                        mrp: '${AppConstants.rupeeSymbol}${variant.mrp.toStringAsFixed(0)}',
                        discount: '$discount% off',
                      ),
                    ],
                  ),
                ),

                // Remove button
                GestureDetector(
                  onTap: () {
                    inventoryController.variantSelection.remove(variant.id);
                    inventoryController.variantSellingPrice.remove(variant.id);
                    productController.toggleProductSelection(variantData);
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.red,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: AppColors.whiteF3,
            margin: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          ),

          // Selling price input row
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size12,
              vertical: SizeConfig.size10,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: SizeConfig.size6),
                    CustomText(
                      'Your Selling Price',
                      fontSize: SizeConfig.small,
                      color: AppColors.mainTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.fillColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _priceErrors[variant.id] != null
                                  ? AppColors.red
                                  : AppColors.greyE5,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.08),
                                ),
                                alignment: Alignment.center,
                                child: CustomText(
                                  AppConstants.rupeeSymbol,
                                  fontSize: SizeConfig.medium,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType
                                      .numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*')),
                                  ],
                                  style: TextStyle(
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.mainTextColor,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        variant.sellingPrice.toStringAsFixed(0),
                                    hintStyle: TextStyle(
                                      fontSize: SizeConfig.medium,
                                      color: AppColors.secondaryTextColor,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: SizeConfig.size8,
                                      vertical: 10,
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged: (value) =>
                                      _onSellingPriceChanged(
                                          variant.id, value, variant.mrp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_priceErrors[variant.id] != null) ...[
                  SizedBox(height: SizeConfig.size6),
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 14,
                        color: AppColors.red,
                      ),
                      SizedBox(width: SizeConfig.size4),
                      Expanded(
                        child: CustomText(
                          _priceErrors[variant.id]!,
                          fontSize: SizeConfig.extraSmall,
                          color: AppColors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Obx(() {
      final products = productController.selectedProducts;
      if (products.isEmpty) return const SizedBox();

      return Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size15,
          vertical: SizeConfig.size12,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Summary row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    '${products.length} ${products.length == 1 ? 'variant' : 'variants'} selected',
                    fontSize: SizeConfig.small,
                    color: AppColors.secondaryTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.green00,
                      ),
                      SizedBox(width: 4),
                      CustomText(
                        'Ready to publish',
                        fontSize: SizeConfig.small,
                        color: AppColors.green00,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size10),
              // Publish button
              CustomBtn(
                onTap: inventoryController.cloneProductVariantLoading.value
                    ? null
                    : () => _handlePublish(context),
                isValidate: true,
                radius: SizeConfig.size8,
                title: inventoryController.cloneProductVariantLoading.value
                    ? null
                    : 'Publish ${products.length} Products',
                isLoading: inventoryController.cloneProductVariantLoading.value,
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _handlePublish(BuildContext context) async {
    final variants = productController.selectedProducts.toList();
    if (variants.isEmpty) return;

    // Block publish while any row still has a selling-price > MRP error.
    final hasInvalidPrice =
        _priceErrors.values.any((err) => err != null && err.isNotEmpty);
    if (hasInvalidPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const CustomText(
            'Fix selling prices that exceed MRP before publishing.',
            color: AppColors.white,
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final missingPriceIds =
        inventoryController.validateSelectedVariants(variants);

    if (missingPriceIds.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const CustomText(
              AppStrings.useListedPrices,
              fontWeight: FontWeight.bold,
            ),
            content: const CustomText(
              AppStrings.useListedPricesMsg,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const CustomText(AppStrings.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const CustomText(
                  AppStrings.continueText,
                  color: AppColors.white,
                ),
              ),
            ],
          );
        },
      );

      if (proceed != true) return;

      inventoryController.fillMissingSellingPricesWithDefaults(
        variants,
        missingPriceIds,
      );
    }

    final ownerID = productController.ownerID ?? '';
    final providerType =
        productController.ownerProviderType ?? ProviderType.business;

    inventoryController.cloneProductVariantApi(
      providerType: providerType,
      variants: variants,
    );
  }
}
