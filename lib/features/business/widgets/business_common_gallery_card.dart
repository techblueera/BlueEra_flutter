import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

class BusinessCommonGalleryCard extends StatelessWidget {
  final List<String>? gallery;
  final VoidCallback onEditTap;
  final VoidCallback onAddTap;
  final String emptyTitle;
  final String addButtonLabel;
  final bool isRestaurantGallery;

  const BusinessCommonGalleryCard({
    super.key,
    this.gallery,
    required this.onEditTap,
    required this.onAddTap,
    this.emptyTitle = 'You Have Not Post Any Photo',
    this.addButtonLabel = 'Add Photo',
    this.isRestaurantGallery = false
  });

  @override
  Widget build(BuildContext context) {
    final hasGallery = gallery?.isNotEmpty ?? false;

    return CustomFormCard(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          // ─── Header ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                  !isRestaurantGallery
                      ? AppStrings.gallery.tr
                      : 'Upload Menu Card & ${AppStrings.gallery.tr}',
                  fontSize: 20, fontWeight: FontWeight.bold),
              if (hasGallery)
                InkWell(
                  onTap: onEditTap,
                  child: LocalAssets(
                      imagePath: AppIconAssets.editIcon,
                      imgColor: AppColors.mainTextColor),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ─── Gallery or Empty State ───
          hasGallery
              ? _buildGallery(gallery!, context)
              : _buildEmptyState(context),
        ],
      ),
    );
  }

  // ─── Gallery grid ───
  Widget _buildGallery(List<String> galleryList, BuildContext context) {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(galleryList.length > 10 ? 10 : galleryList.length,
          (index) {
        int crossAxisCellCount = 2;
        num mainAxisCellCount = 2;
        if (index % 6 == 0 || index % 6 == 5) {
          crossAxisCellCount = 2;
          mainAxisCellCount = 3;
        } else if (index % 6 == 3) {
          crossAxisCellCount = 4;
          mainAxisCellCount = 2;
        } else {
          crossAxisCellCount = 2;
          mainAxisCellCount = 1.5;
        }

        return StaggeredGridTile.count(
          crossAxisCellCount: crossAxisCellCount,
          mainAxisCellCount: mainAxisCellCount,
          child: InkWell(
            onTap: () => navigatePushTo(
                context,
                ImageViewScreen(
                  appBarTitle: AppStrings.imageViewer,
                  subTitle: AppStrings.imageViewer,
                  imageUrls: galleryList,
                  initialIndex: index,
                )),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: galleryList[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── Empty state ───
  Widget _buildEmptyState(BuildContext context) {
    return InkWell(
      onTap: onAddTap,
      child: Container(
        height: SizeConfig.size200,
        width: SizeConfig.screenWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          image: DecorationImage(
            image: AssetImage(AppImageAssets.homeMadeFoodBanner),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Blur overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: AppColors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LocalAssets(
                  imagePath: AppImageAssets.noMeContent,
                  height: SizeConfig.size80,
                  width: SizeConfig.size80,
                ),
                const SizedBox(height: 6.0),
                CustomText(
                  emptyTitle,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),

                // Glassmorphism button
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: AppColors.primaryColor,
                        border: Border.all(
                          color: AppColors.primaryColor,),
                      ),
                      child: CustomText(
                        addButtonLabel,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
