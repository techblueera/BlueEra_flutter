import 'package:BlueEra/core/api/model/get_all_store_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/services/location/location_service.dart';
import 'package:BlueEra/core/services/share_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/business/widgets/business_availability_widget.dart';
import 'package:BlueEra/features/business/widgets/business_common_subcategory_widget.dart';
import 'package:BlueEra/features/business/widgets/rating_widget.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/store/controller/store_controller.dart';
import 'package:BlueEra/features/me/grocery/widget/food_type_indicator.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/network_assets.dart';
import 'package:BlueEra/widgets/route_map_bottom_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/shared_preference_utils.dart';

/// A reusable business profile header card for visiting any business.
///
/// Usage:
/// ```dart
/// VisitBusinessCommonHeader(
///   details: businessProfileDetails,
///   onRated: () => controller.fetchData(),
/// );
/// ```
class VisitBusinessCommonHeader extends StatefulWidget {
  final BusinessProfileDetails? details;
  final VoidCallback? onRated;

  /// Fires after a successful follow / unfollow so the parent can
  /// re-fetch the business profile (e.g. to refresh `total_followers`).
  final VoidCallback? onFollowChanged;

  const VisitBusinessCommonHeader({
    super.key,
    required this.details,
    this.onRated,
    this.onFollowChanged,
  });

  @override
  State<VisitBusinessCommonHeader> createState() => _VisitBusinessCommonHeaderState();
}

class _VisitBusinessCommonHeaderState extends State<VisitBusinessCommonHeader> {
  final storeController = getOrPut(() => StoreController());
  final chatViewController = Get.find<ChatViewController>();
  final RxBool _isFollowed = false.obs;

  BusinessProfileDetails? get details => widget.details;

  @override
  void initState() {
    super.initState();
    _isFollowed.value = widget.details?.is_following ?? false;
  }

  @override
  void didUpdateWidget(covariant VisitBusinessCommonHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync when parent supplies a refreshed details payload — e.g.,
    // after a pull-to-refresh or a follow/unfollow call reloads the
    // profile. Guard against overwriting a pending optimistic toggle by
    // only syncing when the server value actually changed.
    final newValue = widget.details?.is_following ?? false;
    if (oldWidget.details?.is_following != widget.details?.is_following && _isFollowed.value != newValue) {
      _isFollowed.value = newValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCover = details?.coverimage != null && details!.coverimage!.isNotEmpty;
    final hasAddress = details?.address != null && details!.address!.trim().isNotEmpty;
    final hasDietaryType = details?.dietaryType != null && details!.dietaryType!.trim().isNotEmpty;
    final hasAvailability = details?.availability?.schedule != null;

    return CustomFormCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Banner + Profile Image + Actions ───
          SizedBox(
            height: 260,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Cover image with gradient overlay
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 210,
                        width: double.infinity,
                        child: hasCover
                            ? Image.network(
                                details!.coverimage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildBannerPlaceholder(),
                              )
                            : _buildBannerPlaceholder(),
                      ),
                      // Bottom gradient for readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile avatar
                Positioned(
                  left: 16,
                  top: 180,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.white,
                      child: details?.logo?.isNotEmpty == true
                          ? ClipOval(child: NetWorkOcToAssets(imgUrl: details?.logo ?? ""))
                          : LocalAssets(imagePath: AppIconAssets.user_out_line),
                    ),
                  ),
                ),

                // Follow + Chat buttons
                Positioned(
                  right: 12,
                  bottom: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Chat
                      _buildCircleAction(
                        icon: AppIconAssets.quillChatIcon,
                        onTap: () {
                          if (isGuestUser()) {
                            createProfileScreen();

                            return;
                          }
                          chatViewController.checkChatConnectionAndOpenChat(
                            userId: details?.userId ?? '',
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // Follow
                      _buildFollowButton(),
                    ],
                  ),
                ),

                // Rate + Share actions on banner (top-right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildActionRow(),
                ),
              ],
            ),
          ),

          // ─── Details Section ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Name
                CustomText(
                  details?.businessName,
                  fontSize: 20,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 8),

                // Dietary + SubCategory chips
                if (hasDietaryType || details?.subCategoryDetails?.name != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (hasDietaryType) ...[
                        _buildDietaryIndicator(details!.dietaryType!),
                        const SizedBox(width: 6),
                      ],
                      if (details?.subCategoryDetails?.name != null)
                        BusinessCommonSubCategoryWidget(
                          label: details?.subCategoryDetails?.name,
                        )
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Distance + Address card (tappable for map)
                if (hasAddress)
                  GestureDetector(
                    onTap: () => RouteMapBottomSheet.show(
                      context: context,
                      destinationName: details?.businessName ?? 'Business',
                      destinationAddress: details?.address ?? '',
                      destinationLat: details?.businessLocation?.lat?.toDouble() ?? 0.0,
                      destinationLng: details?.businessLocation?.lon?.toDouble() ?? 0.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.near_me_rounded, size: 16, color: AppColors.primaryColor),
                          const SizedBox(width: 8),
                          CustomText(
                            '${calculateDistance(
                                  details?.businessLocation?.lat?.toDouble() ?? 0.0,
                                  details?.businessLocation?.lon?.toDouble() ?? 0.0,
                                )?.toStringAsFixed(2) ?? '--'} KM',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.secondaryTextColor.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: CustomText(
                              getLocalityAddress(details!.address),
                              fontSize: 11,
                              color: AppColors.secondaryTextColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.directions_rounded, size: 18, color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  ),
                if (hasAddress) const SizedBox(height: 10),

                // Availability
                if (hasAvailability)
                  BusinessAvailabilityWidget(
                    hasAvailability: true,
                    schedule: details?.availability?.schedule,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Row: Rate + Share (over cover image) ───
  Widget _buildActionRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _overBannerIconButton(
          child: LocalAssets(
            imagePath: AppIconAssets.star_rounded,
            width: 15,
            height: 15,
            imgColor: Colors.white,
          ),
          onTap: () async {
            final success = await showDialog(
              context: context,
              builder: (_) => RatingFeedbackDialog(
                businessId: details?.id ?? '',
                reviewFor: AppConstants.business,
              ),
            );
            if (success == true) {
              widget.onRated?.call();
            }
          },
        ),
        const SizedBox(width: 6),
        _overBannerIconButton(
          child: LocalAssets(
            imagePath: AppIconAssets.share_bold,
            width: 15,
            height: 15,
            imgColor: Colors.white,
          ),
          onTap: () async {
            // Custom message ("Check out X on BlueEra") — use the
            // raw openShareSheet entry point so we control the body,
            // but still avoid touching SharePlus / ShareParams
            // directly.
            final isBusiness = accountTypeGlobal.toUpperCase() == AppConstants.business;

            final shareLink = isBusiness
                ? businessProfileDeepLink(
                    userId: details?.userId,
                  )
                : profileDeepLink(
                    userId: details?.userId,
                  );

            await ShareService.instance.openShareSheet(
              text: "Check out ${details?.businessName ?? 'this profile'} on BlueEra:\n$shareLink",
              subject: details?.businessName,
            );
          },
        ),
      ],
    );
  }

  /// 36×36 floating circular button designed to sit on top of a cover
  /// photo. Light translucent black fill + thin white ring keeps the
  /// icon readable on both light and dark images.
  Widget _overBannerIconButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ─── Circle Action Button ───
  Widget _buildCircleAction({
    required String icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
            border: Border.all(color: AppColors.greyE5, width: 0.5),
            boxShadow: [AppShadows.textFieldShadow]),
        child: LocalAssets(
          imagePath: AppIconAssets.chat,
          height: 16,
          width: 16,
          imgColor: AppColors.secondaryTextColor,
        ),
      ),
    );
  }

  // ─── Follow Button ───
  Widget _buildFollowButton() {
    return Obx(() => InkWell(
          onTap: () async {
            if (isGuestUser()) {
              createProfileScreen();
              return;
            }
            final store = GetAllStoreResModel(
              id: details?.id,
              userId: details?.userId,
            );
            if (_isFollowed.value) {
              await storeController.unFollowBusinessUser(
                businessId: details?.userId,
                store: store,
              );
              _isFollowed.value = false;
            } else {
              await storeController.followBusinessUser(
                businessId: details?.userId,
                store: store,
              );
              _isFollowed.value = true;
            }
            // Let the parent refresh the profile so follower count
            // reflects the server state.
            widget.onFollowChanged?.call();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _isFollowed.value ? AppColors.white : Colors.blue,
              borderRadius: BorderRadius.circular(20),
              border: _isFollowed.value ? Border.all(color: AppColors.greyE5) : null,
              boxShadow: [
                BoxShadow(
                  color: (_isFollowed.value ? Colors.black : Colors.blue).withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CustomText(
              _isFollowed.value ? AppStrings.unfollow : AppStrings.follow,
              color: _isFollowed.value ? AppColors.secondaryTextColor : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ));
  }

  /// Banner shown when `coverimage` is missing or fails to load.
  /// Falls back to the business logo. If there's no logo either, shows
  /// the generic place-holder asset.
  Widget _buildBannerPlaceholder() {
    final logo = details?.logo ?? '';
    if (logo.isEmpty) {
      return Container(
        color: AppColors.greyLite,
        child: Center(
          child: LocalAssets(
            imagePath: AppIconAssets.place_holder_image,
            boxFix: BoxFit.cover,
            height: 210,
            width: double.infinity,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: logo,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.greyLite),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.greyLite,
        child: Center(
          child: LocalAssets(
            imagePath: AppIconAssets.place_holder_image,
            boxFix: BoxFit.cover,
            height: 210,
            width: double.infinity,
          ),
        ),
      ),
    );
  }

  Widget _buildDietaryIndicator(String dietaryType) {
    if (dietaryType == 'Both') {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 1),
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 7,
              width: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.green00),
            ),
            const SizedBox(width: 4),
            Container(
              height: 7,
              width: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.red00),
            ),
          ],
        ),
      );
    }
    return FoodTypeIndicator(
      isVegetarian: dietaryType == 'Veg',
      size: 7,
    );
  }
}
