import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical_new/model/medical_nested_category_model.dart';
import 'package:BlueEra/features/me/medical_new/view/medical_subcategory_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MedicalLevel2CategoryScreen extends StatelessWidget {
  final String title;
  final List<MedicalNestedCategoryModel> level2Categories;

  // 4 soft pastel tile backgrounds — picked pseudo-randomly per item
  // (deterministic so a given index keeps the same color across rebuilds).
  static const List<Color> _tileColors = [
    Color(0xFFE3F2FD), // soft blue
    Color(0xFFFFF3E0), // soft peach
    Color(0xFFE8F5E9), // soft mint
    Color(0xFFFCE4EC), // soft pink
  ];

  Color _tileColorFor(MedicalNestedCategoryModel category, int index) {
    // Mix index with name hash so order changes still feel random.
    final seed = (category.name?.hashCode ?? 0) ^ (index * 31);
    return _tileColors[seed.abs() % _tileColors.length];
  }

  const MedicalLevel2CategoryScreen({
    super.key,
    required this.title,
    required this.level2Categories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(title: title),
      body: level2Categories.isEmpty
          ? _buildEmptyState()
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    SizeConfig.size12,
                    SizeConfig.size4,
                    SizeConfig.size12,
                    SizeConfig.size40,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: SizeConfig.size10,
                      mainAxisSpacing: SizeConfig.size10,
                      childAspectRatio: 0.82,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final category = level2Categories[index];
                        return _buildSubCategoryCard(category, index);
                      },
                      childCount: level2Categories.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(height: SizeConfig.size30),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(
        SizeConfig.size14,
        SizeConfig.size14,
        SizeConfig.size14,
        SizeConfig.size10,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size16,
        vertical: SizeConfig.size14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withOpacity(0.95),
            AppColors.primaryColor.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  title,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                CustomText(
                  '${level2Categories.length} ${AppStrings.medicalCategoriesAvailableSuffix.tr}',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.size20),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 56,
              color: AppColors.primaryColor.withOpacity(0.7),
            ),
          ),
          SizedBox(height: SizeConfig.size16),
          CustomText(
            AppStrings.medicalNoSubcategoriesAvailable,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            AppStrings.medicalPleaseCheckBackLater,
            fontSize: SizeConfig.small,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryCard(MedicalNestedCategoryModel category, int index) {
    final childCount = category.children?.length ?? 0;
    final hasChildren = childCount > 0;
    final tileColor = _tileColorFor(category, index);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          final level3Children = category.children ?? [];
          if (level3Children.isNotEmpty) {
            Get.to(() => MedicalSubCategoryScreen(
                  arrLevel3Category: level3Children,
                ));
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image fills its area — no extra padding around it
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(SizeConfig.size10),
                          child: _buildImage(category),
                        ),
                      ),
                    ),
                    if (hasChildren)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: CustomText(
                            '$childCount',
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Tight footer — name only (compact)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: CustomText(
                  category.name ?? '',
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: AppColors.mainTextColor,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(MedicalNestedCategoryModel category) {
    final placeholder = Center(
      child: LocalAssets(
        imagePath: AppIconAssets.place_holder_image,
        width: 56,
        height: 56,
      ),
    );

    if (category.image != null && category.image!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12.0),

        child: CachedNetworkImage(
          imageUrl: category.image!,
          fit: BoxFit.contain,
          placeholder: (_, __) => placeholder,
          errorWidget: (_, __, ___) => Image.asset(
            "assets/category/medical/sub_category_medical/${category.name}.png",
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => placeholder,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Image.asset(
        "assets/category/medical/sub_category_medical/${category.name}.png",
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}