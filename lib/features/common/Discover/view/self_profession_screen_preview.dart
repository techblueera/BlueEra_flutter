import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/Discover/model/service_model_response.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_rating_row.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/social_gallery_grid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ─── SelfProfessionScreenPreview ───
class SelfProfessionScreenPreview extends StatelessWidget {
  final ServiceData service;
  final Map<String, String> timingMap;
  final String priceDisplay;
  final String priceBadgeText;
  final Color priceBadgeColor;
  final bool isSelfPreview;

  const SelfProfessionScreenPreview({
    super.key,
    required this.service,
    required this.timingMap,
    required this.priceDisplay,
    required this.priceBadgeText,
    required this.priceBadgeColor,
    this.isSelfPreview = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: 80 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                // ─── Cover + Profile Header (merged) ───
                _buildHeaderSection(context),

                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
                  child: Column(
                    children: _joinWithGap(
                      [
                        // ─── Quick Stats Row ───
                        CustomFormCard(
                          padding: EdgeInsets.all(15.0),
                          child: Row(
                            children: [
                              _buildStatItem(
                                icon: Icons.currency_rupee_rounded,
                                label: AppStrings.priceLabel.tr,
                                value: priceDisplay,
                                color: priceBadgeColor,
                              ),
                              _buildDivider(),
                              _buildStatItem(
                                icon: Icons.access_time_rounded,
                                label: AppStrings.opens.tr,
                                value: timingMap["start"] ?? '--',
                                color: Colors.green,
                              ),
                              _buildDivider(),
                              _buildStatItem(
                                icon: Icons.access_time_filled_rounded,
                                label: AppStrings.closes.tr,
                                value: timingMap["end"] ?? '--',
                                color: AppColors.redB4,
                              ),
                            ],
                          ),
                        ),

                        // ─── Service Description ───
                        if (service.service?.facilities?.isNotEmpty == true)
                          _buildInfoCard(
                            icon: Icons.description_outlined,
                            title: AppStrings.serviceDescription.tr,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                service.service!.facilities!.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                            top: 7.0, right: 8.0),
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                            color: AppColors.primaryColor,
                                            shape: BoxShape.circle),
                                      ),
                                      Expanded(
                                        child: CustomText(
                                          service.service!.facilities![index],
                                          fontSize: SizeConfig.medium,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // ─── Work Experience ───
                        if (service.experiences?.isNotEmpty == true)
                          _buildInfoCard(
                            icon: Icons.work_outline_rounded,
                            title: AppStrings.workExperience.tr,
                            child: CustomText(
                              service.experiences![0],
                              fontSize: SizeConfig.medium,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondaryTextColor,
                            ),
                          ),

                        // ─── Expertise ───
                        if (service.skills?.isNotEmpty == true)
                          _buildInfoCard(
                            icon: Icons.star_outline_rounded,
                            title: AppStrings.expertiseLabel.tr,
                            child: Wrap(
                              spacing: SizeConfig.size8,
                              runSpacing: SizeConfig.size8,
                              children: service.skills!
                                  .map((skill) => Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: SizeConfig.size10,
                                            vertical: SizeConfig.size6),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryColor
                                              .withValues(alpha: 0.06),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: AppColors.primaryColor
                                                  .withValues(alpha: 0.2)),
                                        ),
                                        child: CustomText(skill,
                                            fontSize: SizeConfig.small,
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w500),
                                      ))
                                  .toList(),
                            ),
                          ),

                        // ─── Gallery ───
                        if (service.serviceMedia?.photos?.isNotEmpty == true)
                          _buildInfoCard(
                            icon: Icons.photo_library_outlined,
                            title: AppStrings.gallery.tr,
                            child: SocialGalleryGrid(
                              imageUrls: service.serviceMedia!.photos!,
                            ),
                          ),
                      ],
                      gap: SizedBox(height: SizeConfig.size10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Fixed Bottom Button (hidden when previewing own profile) ───
          if (!isSelfPreview)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  SizeConfig.size16,
                  SizeConfig.size12,
                  SizeConfig.size16,
                  SizeConfig.size16 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: CustomBtn(
                  onTap: () {
                    final targetUserId = service.id ?? '';
                    if (targetUserId.isEmpty) return;
                    final chatViewController =
                        getOrPut(() => ChatViewController());

                    final senderName = userNameGlobal.trim();
                    final providerName = (service.name ?? '').trim();
                    final introBody = providerName.isEmpty
                        ? "I'd like to know more about your service."
                        : "I'd like to know more about your $providerName service.";
                    final prefill = senderName.isEmpty
                        ? "Hi, $introBody"
                        : "Hi, I'm $senderName. $introBody";

                    chatViewController.checkChatConnectionAndOpenChat(
                      userId: targetUserId,
                      prefilledMessage: prefill,
                    );
                  },
                  isValidate: true,
                  radius: SizeConfig.size12,
                  title: AppStrings.requestBooking.tr,
                  bgColor: AppColors.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Stat Item ───
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(height: SizeConfig.size4),
          CustomText(value,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor),
          CustomText(label,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: AppColors.greyE5);
  }

  // ─── Info Card ───
  Widget _buildInfoCard(
      {required IconData icon, required String title, required Widget child}) {
    return CustomFormCard(
      padding: EdgeInsets.all(15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: AppColors.primaryColor),
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText(title,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor),
            ],
          ),
          Divider(color: AppColors.greyE5, height: SizeConfig.size20),
          child,
        ],
      ),
    );
  }

  // Inserts `gap` between every pair of rendered children. Collection-if
  // branches that fail are dropped before they reach this list, so no gap
  // is added for absent sections.
  List<Widget> _joinWithGap(List<Widget> items, {required Widget gap}) {
    if (items.isEmpty) return const [];
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) result.add(gap);
      result.add(items[i]);
    }
    return result;
  }

  // ─── Merged Header (cover banner + avatar + name/profession/rating/bio) ───
  Widget _buildHeaderSection(BuildContext context) {
    final profileImage = service.profileImage ?? '';
    final statusBarHeight = MediaQuery.of(context).padding.top;

    Widget gradientFallback() => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover banner + overlapping avatar + top action bar
          SizedBox(
            height: 230 + statusBarHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner (extends behind status bar)
                SizedBox(
                  height: 190 + statusBarHeight,
                  width: double.infinity,
                  child: profileImage.isEmpty
                      ? gradientFallback()
                      : CachedNetworkImage(
                          imageUrl: profileImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => gradientFallback(),
                          errorWidget: (_, __, ___) => gradientFallback(),
                        ),
                ),

                // Top bar: back + share (respects status bar)
                Positioned(
                  top: statusBarHeight + 4,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _coverIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      _coverShareButton(onTap: () {}),
                    ],
                  ),
                ),

                // Profile avatar (transparent behind, thin white border)
                Positioned(
                  left: 16,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CachedAvatarWidget(
                      imageUrl: profileImage,
                      size: SizeConfig.size80,
                      borderColor: Colors.transparent,
                      borderRadius: SizeConfig.size40,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Name / profession / rating / bio — flush under cover, no gap
          _buildProfileInfoContent(),
        ],
      ),
    );
  }

  // Profile info content (no outer card — sits flush under the cover)
  Widget _buildProfileInfoContent() {
    final name = service.name ?? '';
    final profession = service.profession ?? '';
    final bio = service.bio ?? '';
    final hasName = name.trim().isNotEmpty;
    final hasProfession = profession.trim().isNotEmpty;
    final hasBio = bio.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasName)
                Expanded(
                  child: CustomText(
                    name,
                    fontSize: SizeConfig.extraLarge,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
              if (hasName && hasProfession) SizedBox(width: SizeConfig.size8),
              if (hasProfession)
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size8,
                      vertical: SizeConfig.size3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: CustomText(
                    profession,
                    fontSize: SizeConfig.small,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          SizedBox(height: SizeConfig.size6),
          CommonRatingRow(
            rating: double.tryParse(service.rating.toString()) ?? 0.0,
            reviews: service.reviewCount ?? 0,
            distance: '${service.distance ?? 0} KM',
          ),
          if (hasBio) ...[
            // SizedBox(height: SizeConfig.size12),
            // Divider(color: AppColors.greyE5, height: 1),
            SizedBox(height: SizeConfig.size8),
            ExpandableText(
              text: bio,
              trimLines: 3,
              expandMode: ExpandMode.dialog,
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontFamily: AppConstants.OpenSans,
                fontWeight: FontWeight.w400,
                fontSize: SizeConfig.medium,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _coverIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.appBackgroundColor, size: 18),
      ),
    );
  }

  Widget _coverShareButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: LocalAssets(
          imagePath: AppIconAssets.profile_share,
          width: 18,
          height: 18,
          imgColor: AppColors.appBackgroundColor,
        ),
      ),
    );
  }

}
