import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/controller/medical_controller.dart';
import 'package:BlueEra/features/me/medical/view/my_medical_listing/my_medical_variant_card.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import '../../../../../core/api/model/images.dart';
import '../../model/my_medical_products_response.dart';

/// The category → variants page. Mirrors grocery's
/// `GroceryNestedCategoryWithInventoryScreen` role: one page reached from a
/// category card that fetches and lists what's inside.
///
/// Two modes:
///  * **Category mode** (the storefront card path): given a [categoryId] and no
///    static [variants], it fetches the category's products and flattens every
///    product's variants into one grid, paginating on scroll. This is what
///    replaced the old `MyMedicalProductsScreen` products-list layer.
///  * **Static mode** (legacy): given an explicit [variants] list, it just
///    renders it. Kept so any caller that already has a single product's
///    variants can push them directly.
class MyMedicalVariantScreen extends StatefulWidget {
  final List<MedicalProductVariants>? variants;
  final bool? isShowInGrid;
  final String? categoryId;
  final String? categoryName;

  const MyMedicalVariantScreen({
    super.key,
    this.variants,
    this.isShowInGrid = true,
    this.categoryId,
    this.categoryName,
  });

  @override
  State<MyMedicalVariantScreen> createState() => _MyMedicalVariantScreenState();
}

class _MyMedicalVariantScreenState extends State<MyMedicalVariantScreen> {
  final controller = getOrPut(() => MedicalController());
  final ScrollController scrollController = ScrollController();

  /// Category mode fetches; static mode uses the passed-in list as-is.
  late final bool _categoryMode;

  @override
  void initState() {
    super.initState();
    // Discriminate on whether a variants list was passed AT ALL, not whether
    // it's empty: the legacy product path always passes a list (sometimes
    // empty, for a variant-less product) and must stay in static mode so it
    // shows "no variants" rather than fetching the whole category.
    _categoryMode =
        widget.variants == null && (widget.categoryId?.isNotEmpty ?? false);

    if (_categoryMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.fetchMyGroceryProducts(categoryId: widget.categoryId!);
      });
      scrollController.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      controller.fetchMyGroceryProducts(
        categoryId: widget.categoryId!,
        isLoadMore: true,
      );
    }
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  /// Flattens every product's variants into a single list, carrying the
  /// product image onto any variant that has none — the same fix
  /// `MedicalProductCard._navigateToVariants` used to apply per product.
  List<MedicalProductVariants> _flatten(List<Products> products) {
    final out = <MedicalProductVariants>[];
    for (final p in products) {
      final Images? productImage =
          (p.images?.isNotEmpty ?? false) ? p.images!.first : null;
      for (final v in (p.variants ?? <MedicalProductVariants>[])) {
        if (productImage != null &&
            (v.images == null || v.images!.isEmpty)) {
          v.images = [productImage];
        }
        out.add(v);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: widget.categoryName),
      body: SafeArea(
        child: _categoryMode ? _buildCategoryMode() : _buildStaticMode(),
      ),
    );
  }

  // ── Category mode — reactive on the fetched products list ──────────────
  Widget _buildCategoryMode() {
    return Obx(() {
      if (controller.isMyMedicalDataFirstLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final variants = _flatten(controller.myMedicalProductsList.toList());

      if (variants.isEmpty) {
        return Center(
          child: CustomText(
            AppStrings.medicalNoVariantsForProduct.tr,
            fontSize: SizeConfig.large,
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        );
      }

      return _variantGrid(
        variants,
        showLoadMore: controller.isMyMedicalDataLoadingMore.value,
      );
    });
  }

  // ── Static mode — render the passed-in list ──────────────────────────
  Widget _buildStaticMode() {
    final variants = widget.variants ?? <MedicalProductVariants>[];
    if (variants.isEmpty) {
      return Center(
        child: CustomText(
          AppStrings.medicalNoVariantsForProduct.tr,
          fontSize: SizeConfig.large,
          color: AppColors.secondaryTextColor,
          fontWeight: FontWeight.w500,
        ),
      );
    }
    return (widget.isShowInGrid ?? false)
        ? _variantGrid(variants, showLoadMore: false)
        : ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8, vertical: SizeConfig.size8),
            itemCount: variants.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: SizeConfig.size10),
              child: MyMedicalVariantCard(
                variantItem: variants[index],
                isShowInGrid: false,
                categoryId: widget.categoryId,
              ),
            ),
          );
  }

  Widget _variantGrid(
    List<MedicalProductVariants> variants, {
    required bool showLoadMore,
  }) {
    return GridView.builder(
      controller: scrollController,
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8, vertical: SizeConfig.size10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        // itemWidth / approx card height — kept from the previous grid so cards
        // keep their proportions.
        childAspectRatio:
            ((SizeConfig.screenWidth - SizeConfig.size8 * 2 - 10) / 2) /
                SizeConfig.size280,
      ),
      itemCount: variants.length + (showLoadMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= variants.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return MyMedicalVariantCard(
          variantItem: variants[index],
          isShowInGrid: true,
          categoryId: widget.categoryId,
        );
      },
    );
  }
}
