import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/shimmer_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/widgets/website_overview_card.dart';
import 'package:BlueEra/features/common/reel/view/channel/follower_following_screen.dart';
import 'package:BlueEra/features/me/content_creator/controller/earn_artist_controller.dart';
import 'package:BlueEra/features/me/content_creator/model/earn_artist_model.dart';
import 'package:BlueEra/features/me/content_creator/view/associate_brands_screen.dart';
import 'package:BlueEra/features/me/content_creator/widget/artist_expertise_picker.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/controller/perosonal__create_profile_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/edit_profile_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/profile_designation_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_bio_card.dart';
import 'package:BlueEra/features/personal/personal_profile/widgets/profile_location_card.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_circular_profile_image.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// The identity/stats/bio/website sections read from the personal profile and
/// render regardless of the earn fetch, so the tab is never blocked on the
/// earn profile loading. The earn sections show a small inline spinner while
/// the profile first loads/creates, then their data (or a subtle empty state).
/// This screen is self-contained — it copies the identity/stats layout from
/// professionals_consultant rather than importing it.
class ContentCreatorOverviewTab extends StatefulWidget {
  const ContentCreatorOverviewTab({super.key});

  @override
  State<ContentCreatorOverviewTab> createState() =>
      _ContentCreatorOverviewTabState();
}

class _ContentCreatorOverviewTabState extends State<ContentCreatorOverviewTab> {
  static const _cardBorder = Color(0xFFEDEFF4);
  static const _hMargin = 20.0;

  final _viewCtrl =
      getOrPut(() => ViewPersonalDetailsController(), permanent: true);
  final _personalCtrl = getOrPut(() => PersonalCreateProfileController());
  final _earnCtrl = getOrPut(() => EarnArtistController());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Personal-profile sections (always rendered) ──
        _buildIdentityCard(context),
        _gap(),
        _buildStatsCard(),
        _gap(),
        const ProfileBioCard(),
        _gap(),
        // ── Earn-artist sections (spinner while first loading) ──
        _buildEarnSections(),
        // ── Website (personal profile) ──
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 20, right: 10),
          child: Obx(() => WebsiteOverviewCard(
            websiteUrl: _viewCtrl.website.value,
            onSave: (url) => _personalCtrl.updateUserProfileDetails(
              params: {ApiKeys.website: url},
              isFromProfileOnly: true,
            ),
          )),
        ),
        // ── Location (personal profile) ──
        Padding(
          padding: const EdgeInsets.only(top: 10, left: 20, right: 10),
          child: const ProfileLocationCard(margin: EdgeInsets.zero),
        ),
        SizedBox(height: SizeConfig.size16),
      ],
    );
  }

  SizedBox _gap() => SizedBox(height: SizeConfig.size12);

  // ─── EARN SECTIONS WRAPPER ──────────────────────────────────────────────
  Widget _buildEarnSections() {
    return Obx(() {
      final status = _earnCtrl.artistResponse.value.status;
      final artist = _earnCtrl.artist.value;
      final firstLoading =
          (status == Status.LOADING || status == Status.INITIAL) &&
              artist == null;

      if (firstLoading) return _earnSkeleton();
      // No profile yet (error / edge) — render nothing rather than blocking.
      if (artist == null) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _expertiseSection(artist),
          _gap(),
          _pricingSection(artist),
          _gap(),
          _certificatesSection(artist),
          _gap(),
          _brandsSection(artist),
          _gap(),
          _gallerySection(artist),
        ],
      );
    });
  }

  // ─── EARN SECTIONS SKELETON (shimmer while first loading) ───────────────
  /// Mirrors the five earn cards (expertise, pricing, certificates, brands,
  /// gallery) as shimmer placeholders so the tab shows its real shape while the
  /// profile loads, instead of one lonely spinner.
  Widget _earnSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _skExpertise(),
        _gap(),
        _skPricing(),
        _gap(),
        _skCertificates(),
        _gap(),
        _skBrands(),
        _gap(),
        _skGallery(),
      ],
    );
  }

  /// Header row placeholder — a title block + a trailing edit-dot.
  Widget _skHeaderRow({double titleWidth = 120}) {
    return Row(
      children: [
        shimmerContainer(width: titleWidth, height: 16),
        const Spacer(),
        shimmerContainer(width: 22, height: 22, radius: 11),
      ],
    );
  }

  Widget _skExpertise() {
    return _card(
      child: buildLoadingShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skHeaderRow(titleWidth: 110),
            SizedBox(height: SizeConfig.size14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final w in const [90.0, 120.0, 78.0, 110.0, 64.0])
                  shimmerContainer(width: w, height: 30, radius: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _skPricing() {
    return _card(
      child: buildLoadingShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skHeaderRow(titleWidth: 160),
            SizedBox(height: SizeConfig.size14),
            shimmerContainer(width: 130, height: 30),
            SizedBox(height: SizeConfig.size14),
            shimmerContainer(height: 1),
            SizedBox(height: SizeConfig.size12),
            Row(
              children: [
                Expanded(child: _skMetric()),
                SizedBox(width: SizeConfig.size12),
                Expanded(child: _skMetric()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _skMetric() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shimmerContainer(width: 70, height: 10),
        SizedBox(height: SizeConfig.size6),
        shimmerContainer(width: 90, height: 14),
      ],
    );
  }

  Widget _skCertificates() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLoadingShimmer(child: _skHeaderRow(titleWidth: 160)),
          SizedBox(height: SizeConfig.size14),
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: 2,
              separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size12),
              itemBuilder: (_, __) => buildLoadingShimmer(
                child: shimmerContainer(width: 250, height: 300, radius: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skBrands() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _hMargin),
          child: buildLoadingShimmer(child: _skHeaderRow(titleWidth: 140)),
        ),
        SizedBox(height: SizeConfig.size12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: _hMargin),
            itemCount: 4,
            separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size16),
            itemBuilder: (_, __) => buildLoadingShimmer(
              child: Column(
                children: [
                  shimmerContainer(width: 64, height: 64, radius: 32),
                  SizedBox(height: SizeConfig.size6),
                  shimmerContainer(width: 50, height: 10),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _skGallery() {
    return _card(
      child: buildLoadingShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _skHeaderRow(titleWidth: 90),
            SizedBox(height: SizeConfig.size14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (_, __) => shimmerContainer(radius: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  IDENTITY CARD  (copied from professionals_main.dart; adapted to read
  //  name/designation/bio/contact directly off the personal `user`)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildIdentityCard(BuildContext context) {
    const bannerHeight = 200.0;
    const avatarSize = 88.0;
    const avatarOverlap = avatarSize / 2;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomFormCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            children: [
              SizedBox(
                height: bannerHeight + avatarOverlap,
                width: double.infinity,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: bannerHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(child: _bannerImage()),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.18),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _glassActionPill(
                              icon: Icons.camera_alt_rounded,
                              label: AppStrings.editCover.tr,
                              onTap: () => _onCoverImageEdit(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _avatarFrame(avatarSize),
                          SizedBox(width: SizeConfig.size12),
                          Padding(
                            padding: EdgeInsets.only(bottom: avatarOverlap - 4),
                            child: _memberSincePill(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildIdentityBlock(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerImage() {
    return Obx(() {
      final banner = _personalCtrl.coverImagePath?.value ?? '';
      if (banner.isNotEmpty) {
        return Image.network(banner, fit: BoxFit.cover);
      }
      final fallback = _personalCtrl.imagePath?.value ?? '';
      if (fallback.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: fallback,
          fit: BoxFit.cover,
          placeholder: (_, __) => _coverFallback(),
          errorWidget: (_, __, ___) => _coverFallback(),
        );
      }
      return _coverFallback();
    });
  }

  Widget _coverFallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor.withValues(alpha: 0.18),
              AppColors.primaryColor.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  Widget _avatarFrame(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Obx(() {
          return CommonProfileImage(
            imagePath: _personalCtrl.imagePath?.value ?? '',
            onImageUpdate: (image) async {
              _personalCtrl.imagePath?.value = image;
              dynamic dataImage = await multiPartImage(imagePath: image);
              var reqProfile = {ApiKeys.profile_image: dataImage};
              await _personalCtrl.updateUserProfileDetails(
                  params: reqProfile, isFromProfileOnly: true);
            },
            dialogTitle: AppStrings.uploadProfilePicture,
            showProfileBorder: false,
          );
        }),
      ),
    );
  }

  Widget _memberSincePill() {
    return Obx(() {
      final createdAt =
          _viewCtrl.personalProfileDetails.value.user?.createdAt ?? '';
      if (createdAt.isEmpty) return const SizedBox.shrink();
      final since = _formatJoinedDate(createdAt);
      if (since.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size4,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE4D2A6),
            width: 0.6,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 12,
              color: const Color(0xFFB7781F),
            ),
            const SizedBox(width: 4),
            Text(
              '${AppStrings.proConsultMemberPrefix.tr} · $since',
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B3A00),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildIdentityBlock() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        SizeConfig.size8,
        20,
        SizeConfig.size20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            // Content-creator has NO professional-service model — read the
            // identity fields directly off the personal `user`.
            final user = _viewCtrl.personalProfileDetails.value.user;
            final name = _capitalizeFirst(user?.name ?? '');
            final username = user?.username ?? '';
            final designation = user?.designation ?? '';
            final bio = user?.bio ?? '';
            final dob = user?.dateOfBirth;
            final email = user?.email ?? '';
            final phone = user?.contactNo ?? '';

            final hasDesignation = designation.trim().isNotEmpty;
            final hasName = name.isNotEmpty;
            final hasUsername = username.isNotEmpty;
            final hasBio = bio.isNotEmpty;
            final hasPhone = phone.isNotEmpty;
            final hasEmail = email.isNotEmpty;
            final hasDob = dob != null && dob.date != null && dob.month != null;
            final hasContact = hasPhone || hasEmail || hasDob;
            final hasAnyIdentity =
                hasDesignation || hasName || hasUsername || hasBio || hasContact;

            final children = <Widget>[];

            if (hasDesignation) {
              children.add(_designationEyebrow(designation));
            }

            if (hasName) {
              if (children.isNotEmpty) {
                children.add(SizedBox(height: SizeConfig.size6));
              }
              children.add(_nameRow(name));
            } else if (hasAnyIdentity) {
              if (children.isNotEmpty) {
                children.add(SizedBox(height: SizeConfig.size8));
              }
              children.add(
                Align(
                  alignment: Alignment.centerRight,
                  child: _editChip(
                    onTap: () => EditProfileBottomSheet.show(Get.context!),
                    label: AppStrings.edit,
                  ),
                ),
              );
            }

            if (hasUsername) {
              children.add(const SizedBox(height: 4));
              children.add(_usernameText(username));
            }

            // Bio rendering lives in its own [ProfileBioCard] tile — the
            // identity block no longer carries it. `hasBio` still feeds the
            // `hasAnyIdentity` aggregate so the fallback Edit chip still
            // appears when the user has a bio but no name.

            if (hasContact) {
              children.add(SizedBox(height: SizeConfig.size12));
              children.add(Container(
                height: 1,
                color: const Color(0xFFEDEFF4),
              ));
              children.add(SizedBox(height: SizeConfig.size12));
              if (hasPhone) {
                children.add(_infoRow(Icons.phone_rounded, phone));
              }
              if (hasDob) {
                if (children.last is! SizedBox) {
                  children.add(SizedBox(height: SizeConfig.size8));
                }
                children.add(_infoRow(Icons.cake_rounded,
                    '${AppStrings.proConsultBornPrefix.tr} ${_formatDob(dob)}'));
              }
              if (hasEmail) {
                if (children.last is! SizedBox) {
                  children.add(SizedBox(height: SizeConfig.size8));
                }
                children.add(_infoRow(Icons.alternate_email_rounded, email));
              }
            }

            if (children.isEmpty) {
              return _completeProfileCta();
            }

            return Padding(
              padding: EdgeInsets.only(top: SizeConfig.size12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _designationEyebrow(String designation) {
    return InkWell(
      onTap: () => showProfileDesignationSheet(Get.context!),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 1.5,
            color: AppColors.primaryColor,
          ),
          SizedBox(width: SizeConfig.size8),
          Flexible(
            child: Text(
              designation.toUpperCase(),
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryColor,
                letterSpacing: 1.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameRow(String name) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontFamily: AppConstants.OpenSans,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
              height: 1.1,
              letterSpacing: -0.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: SizeConfig.size8),
        _editChip(
          onTap: () => EditProfileBottomSheet.show(Get.context!),
          label: AppStrings.edit,
        ),
      ],
    );
  }

  Widget _usernameText(String username) {
    return Text(
      '@$username',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.secondaryTextColor,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _completeProfileCta() {
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size12),
      child: InkWell(
        onTap: () => EditProfileBottomSheet.show(Get.context!),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size14,
            vertical: SizeConfig.size12,
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.account_circle_outlined,
                  size: 20, color: AppColors.primaryColor),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Text(
                  AppStrings.completeProfile.tr,
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: AppColors.primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editChip({
    required VoidCallback onTap,
    required String label,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.25),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LocalAssets(
              imagePath: AppIconAssets.pen_line,
              height: 12,
              width: 12,
              imgColor: AppColors.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.OpenSans,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: AppColors.primaryColor),
        ),
        SizedBox(width: SizeConfig.size10),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _glassActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── COVER IMAGE EDIT ───────────────────────────────────────────────────
  Future<void> _onCoverImageEdit(BuildContext context) async {
    final String? newPath = await PhotoPickerService.pickSinglePhoto(
      context,
      AppStrings.editCoverPicture,
      cropAspectRatio: CropAspectRatio(width: 3, height: 2),
    );
    if (newPath == null || newPath.isEmpty) return;
    dynamic dataImage = await multiPartImage(imagePath: newPath);
    var reqProfile = {ApiKeys.coverpicture: dataImage};
    await _personalCtrl.updateUserProfileDetails(
        params: reqProfile, isFromProfileOnly: true);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STATS CARD  (copied verbatim from professionals_main.dart)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomFormCard(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size16,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDEFF4), width: 1),
        child: Obx(() {
          final followers = _viewCtrl.followersCount.value;
          final following = _viewCtrl.followingCount.value;
          final posts = _viewCtrl.postsCount.value;
          return Row(
            children: [
              Expanded(
                  child: _statTile(label: AppStrings.posts.tr, value: '$posts')),
              _statSeam(),
              Expanded(
                child: _statTile(
                  label: AppStrings.followers.tr,
                  value: _formatCount(followers),
                  onTap: () => Get.to(
                      () => FollowersFollowingPage(tabIndex: 1, userID: userId)),
                ),
              ),
              _statSeam(),
              Expanded(
                child: _statTile(
                  label: AppStrings.following.tr,
                  value: _formatCount(following),
                  onTap: () => Get.to(
                      () => FollowersFollowingPage(tabIndex: 0, userID: userId)),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final tile = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
            letterSpacing: -0.4,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryTextColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 18,
          height: 2,
          decoration: BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
    if (onTap == null) return tile;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: tile,
      ),
    );
  }

  Widget _statSeam() {
    return Container(
      height: 36,
      width: 1,
      color: const Color(0xFFEDEFF4),
    );
  }

  // ─── SHARED CARD SHELL / HEADERS (earn sections) ────────────────────────
  Widget _card({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: _hMargin),
      child: CustomFormCard(
        padding: padding ??
            EdgeInsets.symmetric(
                horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder, width: 1),
        child: child,
      ),
    );
  }

  Widget _sectionHeader(String title,
      {String? trailingLabel,
      IconData? trailingIcon,
      String? trailingIconAsset,
      VoidCallback? onTrailing}) {
    return Row(
      children: [
        Expanded(
          child: CustomText(title,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor),
        ),
        if (trailingLabel != null)
          InkWell(
            onTap: onTrailing,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: CustomText(trailingLabel,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor),
            ),
          ),
        if (trailingIconAsset != null)
          InkWell(
            onTap: onTrailing,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: LocalAssets(
                imagePath: trailingIconAsset,
                height: 18,
                width: 18,
                imgColor: AppColors.secondaryTextColor,
              ),
            ),
          )
        else if (trailingIcon != null)
          InkWell(
            onTap: onTrailing,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(trailingIcon,
                  size: 18, color: AppColors.secondaryTextColor),
            ),
          ),
      ],
    );
  }

  void _comingSoon() => commonSnackBar(message: 'Coming soon');

  // ─── EXPERTISE (earn) ───────────────────────────────────────────────────
  Widget _expertiseSection(EarnArtist artist) {
    if (artist.expertise.isEmpty) {
      return _emptySection('Expertise', 'No expertise added yet.',
          trailingIcon: Icons.add_rounded, onTrailing: _openExpertiseSheet);
    }
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Expertise',
              trailingIconAsset: AppIconAssets.pen_line,
              onTrailing: _openExpertiseSheet),
          SizedBox(height: SizeConfig.size14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final e in artist.expertise) _expertiseChip(e)],
          ),
        ],
      ),
    );
  }

  /// One expertise as a tinted pill. A small accent dot keeps the chips from
  /// reading as a stock tag cloud while staying disciplined.
  Widget _expertiseChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: SizeConfig.size8),
          CustomText(label,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor),
        ],
      ),
    );
  }

  /// Opens the API-fed expertise multi-select. Loads suggestions from
  /// `predefined-artist-expertise/{category}?type=` and seeds the current picks.
  void _openExpertiseSheet() {
    _earnCtrl.loadExpertiseSuggestions();
    _showUpdateSheet(
      title: 'Expertise',
      content: ArtistExpertisePicker(controller: _earnCtrl),
    );
  }

  // ─── PRICING / ENGAGEMENT (earn) ────────────────────────────────────────
  Widget _pricingSection(EarnArtist artist) {
    final booking = artist.booking;
    final hasPricing = booking != null &&
        (booking.priceLabel.isNotEmpty || booking.bookingType.isNotEmpty);
    if (!hasPricing) {
      return _emptySection(
          'Pricing / Engagement', 'No pricing added yet.',
          trailingIcon: Icons.add_rounded, onTrailing: _openPricingSheet);
    }
    final hasFee = booking.priceLabel.isNotEmpty;
    final mode = booking.bookingType.isNotEmpty ? booking.bookingType : '—';
    final minLabel = _minPriceLabel(booking);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Pricing / Engagement',
              trailingIconAsset: AppIconAssets.pen_line,
              onTrailing: _openPricingSheet),
          SizedBox(height: SizeConfig.size14),
          // Hero fee — the single most characteristic fact of this section, so
          // it leads at display scale rather than sitting in a generic cell.
          if (hasFee)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹',
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 1),
                Text(
                  booking.priceLabel,
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
                SizedBox(width: SizeConfig.size6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '/ ${booking.priceTypeLabel.toLowerCase()}',
                    style: TextStyle(
                      fontFamily: AppConstants.OpenSans,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            )
          else
            CustomText('Price on request',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor),
          SizedBox(height: SizeConfig.size14),
          Container(height: 1, color: _cardBorder),
          SizedBox(height: SizeConfig.size12),
          Row(
            children: [
              Expanded(child: _pricingMetric('Engagement', mode)),
              Container(width: 1, height: 34, color: _cardBorder),
              SizedBox(width: SizeConfig.size12),
              Expanded(child: _pricingMetric('Minimum', minLabel)),
            ],
          ),
        ],
      ),
    );
  }

  /// A secondary pricing fact — small tracked label over a bold value. Reads as
  /// supporting data under the hero fee, not competing with it.
  Widget _pricingMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: AppConstants.OpenSans,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.secondaryTextColor,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: SizeConfig.size6),
        CustomText(value,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  /// `₹2,000`-style label for the booking minimum, or `—` when unset.
  String _minPriceLabel(ArtistBooking booking) {
    final m = booking.minimumPrice;
    if (m == null) return '—';
    final n =
        m == m.roundToDouble() ? m.toInt().toString() : m.toString();
    return '₹$n';
  }

  /// Pricing edit sheet — fee, minimum fee, engagement mode + a `perHour`/
  /// `perVisit` toggle. `booking` MERGES server-side, so only what changed is
  /// sent.
  void _openPricingSheet() {
    _earnCtrl.seedPricingInputs();
    _showUpdateSheet(
      title: 'Pricing / Engagement',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _labeledField(
                  'Fee (₹)',
                  CommonTextField(
                    textEditController: _earnCtrl.priceController,
                    hintText: 'e.g. 600',
                    keyBoardType: TextInputType.number,
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: _labeledField(
                  'Minimum Fee (₹)',
                  CommonTextField(
                    textEditController: _earnCtrl.minPriceController,
                    hintText: 'e.g. 2000',
                    keyBoardType: TextInputType.number,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size12),
          _labeledField(
            'Engagement Mode',
            CommonTextField(
              textEditController: _earnCtrl.bookingTypeController,
              hintText: 'e.g. Online / Commission',
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          CustomText('Price Type',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.mainTextColor),
          SizedBox(height: SizeConfig.size8),
          Obx(() => Row(
                children: [
                  for (final pt in EarnArtistController.priceTypeOptions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _priceTypeChip(
                        label: pt == 'perHour' ? 'Per Hour' : 'Per Visit',
                        selected: _earnCtrl.selectedPriceType.value == pt,
                        onTap: () => _earnCtrl.selectedPriceType.value = pt,
                      ),
                    ),
                ],
              )),
          SizedBox(height: SizeConfig.paddingL),
          Obx(() => CustomBtn(
                radius: SizeConfig.size10,
                bgColor: AppColors.primaryColor,
                title: _earnCtrl.isUpdating.value ? null : AppStrings.update.tr,
                isLoading: _earnCtrl.isUpdating.value,
                onTap: () async {
                  final booking = <String, dynamic>{
                    'priceType': _earnCtrl.selectedPriceType.value,
                  };
                  final price =
                      int.tryParse(_earnCtrl.priceController.text.trim());
                  if (price != null) booking['price'] = price;
                  final minPrice =
                      int.tryParse(_earnCtrl.minPriceController.text.trim());
                  if (minPrice != null) booking['minimumPrice'] = minPrice;
                  final mode = _earnCtrl.bookingTypeController.text.trim();
                  if (mode.isNotEmpty) booking['bookingType'] = mode;
                  final ok = await _earnCtrl.updateArtist({'booking': booking});
                  if (ok) Get.back();
                },
              )),
        ],
      ),
    );
  }

  Widget _priceTypeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withValues(alpha: 0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primaryColor
                : const Color(0xFFE6E8EE),
            width: selected ? 1.2 : 1,
          ),
        ),
        child: CustomText(
          label,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color:
              selected ? AppColors.primaryColor : AppColors.mainTextColor,
        ),
      ),
    );
  }

  // ─── CERTIFICATE & AWARDS (earn) ────────────────────────────────────────
  Widget _certificatesSection(EarnArtist artist) {
    final certs = artist.certificatesAndAwards;
    if (certs.isEmpty) {
      return _bannerEmptyState(
        image: AppImageAssets.homeServicesBanner,
        eyebrow: 'Certificate & Awards',
        message: 'Show your credentials — add your first certificate or award.',
        ctaLabel: 'Add Certificate',
        ctaIcon: Icons.workspace_premium_rounded,
        onTap: () => _openCertificateSheet(artist),
      );
    }
    // Vertical-only card padding so the horizontal list scrolls edge-to-edge
    // across the whole card; header + list carry their own horizontal padding.
    return _card(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            child: _sectionHeader('Certificate & Awards',
                trailingLabel: 'Add',
                onTrailing: () => _openCertificateSheet(artist)),
          ),
          SizedBox(height: SizeConfig.size14),
          SizedBox(
            height: 300,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
              itemCount: certs.length,
              separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size12),
              itemBuilder: (_, i) => _certificateCard(certs[i], i, artist),
            ),
          ),
        ],
      ),
    );
  }

  Widget _certificateCard(ArtistCertificate cert, int index, EarnArtist artist) {
    return Container(
      width: 250,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16233B), Color(0xFF0C1526)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The certificate art fills the whole card at full opacity.
          Positioned.fill(
            child: cert.firstMedia.isNotEmpty
                ? _networkImage(cert.firstMedia, fit: BoxFit.cover)
                : _certificateArtFallback(),
          ),
          // Per-card edit affordance.
          Positioned(
            top: 10,
            right: 10,
            child: _glassActionPill(
              icon: Icons.edit_rounded,
              label: AppStrings.edit.tr,
              onTap: () =>
                  _openCertificateSheet(artist, editIndex: index, existing: cert),
            ),
          ),
          // Bottom scrim so the name/description stay legible over the art.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 34, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.88),
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    cert.name.isNotEmpty ? cert.name : 'Certificate',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cert.description.isNotEmpty) ...[
                    SizedBox(height: SizeConfig.size6),
                    CustomText(
                      cert.description,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.80),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      height: 1.4,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Branded fill for a certificate that has no uploaded media yet.
  Widget _certificateArtFallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B2A46), Color(0xFF0C1526)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.workspace_premium_rounded,
          size: 40,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  // ─── ASSOCIATE BRANDS (earn) ────────────────────────────────────────────
  /// Opens the search-and-select page. `brandCollaborations` persists as bare
  /// Business ids, so the page both browses businesses and manages the picks;
  /// on save it writes ids back to the profile + caches display detail, and the
  /// strip below rebuilds reactively.
  void _openAssociateBrands() {
    Get.to(() => const AssociateBrandsScreen());
  }

  Widget _brandsSection(EarnArtist artist) {
    final brands = artist.brandCollaborations;
    if (brands.isEmpty) {
      return _emptySection(
        'Associates Brands',
        'Tag the brands and businesses you work with.',
        trailingLabel: 'Add',
        onTrailing: _openAssociateBrands,
      );
    }
    // White [_card] with VERTICAL-only padding so the horizontal strip can
    // scroll edge-to-edge across the whole card (a proper carousel) instead of
    // being confined to the inner padded area. The header and the scroll list
    // carry their own horizontal padding.
    return _card(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            child: _sectionHeader('Associates Brands',
                trailingLabel: 'Add More', onTrailing: _openAssociateBrands),
          ),
          SizedBox(height: SizeConfig.size12),
          // Full-width horizontal scroll (SingleChildScrollView + Row): the
          // gesture spans the whole card and items bleed to its edges, while
          // the strip's height still follows the content.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < brands.length; i++) ...[
                  if (i != 0) SizedBox(width: SizeConfig.size16),
                  // Stored entries are id-only; resolve to cached logo/name.
                  _brandItem(_earnCtrl.resolveBrand(brands[i])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brandItem(ArtistBrand brand) {
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF15151A),
              border: Border.all(color: _cardBorder, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: brand.logo.isNotEmpty
                ? _networkImage(brand.logo, fit: BoxFit.cover)
                : Center(
                    child: CustomText(
                      brand.name.isNotEmpty
                          ? brand.name.characters.first.toUpperCase()
                          : '?',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            brand.name.isNotEmpty ? brand.name : 'Brand',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          if (brand.subLabel.isNotEmpty)
            CustomText(
              brand.subLabel,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  // ─── GALLERY (earn) — manageable (add photos via S3 presign) ────────────
  Widget _gallerySection(EarnArtist artist) {
    final images = <String>[
      for (final g in artist.gallery) ...g.images,
    ];
    // Read reactively (this runs inside [_buildEarnSections]'s Obx) so the
    // section flips to its uploading state the moment a picker returns.
    final uploading = _earnCtrl.isGalleryUploading.value;

    // Empty + idle → the inviting banner. Uploading or populated → the card.
    if (images.isEmpty && !uploading) {
      return _bannerEmptyState(
        image: AppImageAssets.homeMadeProductsBanner,
        eyebrow: 'Gallery',
        message: 'Showcase your work — add photos of your best pieces.',
        ctaLabel: 'Add Photos',
        ctaIcon: Icons.add_photo_alternate_rounded,
        onTap: _onAddGalleryPhotos,
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('Gallery',
              trailingLabel: uploading ? null : 'Add Photo',
              onTrailing: _onAddGalleryPhotos),
          if (uploading) ...[
            SizedBox(height: SizeConfig.size10),
            _galleryUploadingRow(),
          ],
          if (images.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size12),
            _galleryMosaic(images),
          ],
        ],
      ),
    );
  }

  /// Staggered photo mosaic (mirrors [BusinessCommonGalleryCard]) — varied tile
  /// sizes, capped at 10, each tap opening the full-screen image viewer.
  Widget _galleryMosaic(List<String> images) {
    final count = images.length > 10 ? 10 : images.length;
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: List.generate(count, (index) {
        int crossAxisCellCount = 2;
        num mainAxisCellCount = 2;
        if (count == 1) {
          // Single photo → span the full width instead of a lonely half-tile.
          crossAxisCellCount = 4;
          mainAxisCellCount = 2.4;
        } else if (index % 6 == 0 || index % 6 == 5) {
          crossAxisCellCount = 2;
          mainAxisCellCount = 3;
        } else if (index % 6 == 3) {
          crossAxisCellCount = 4;
          mainAxisCellCount = 2;
        } else {
          crossAxisCellCount = 2;
          mainAxisCellCount = 1.5;
        }
        final url = images[index];
        final deleting = _earnCtrl.galleryDeletingUrl.value == url;
        return StaggeredGridTile.count(
          crossAxisCellCount: crossAxisCellCount,
          mainAxisCellCount: mainAxisCellCount,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                InkWell(
                  onTap: deleting
                      ? null
                      : () => navigatePushTo(
                            context,
                            ImageViewScreen(
                              appBarTitle: AppStrings.imageViewer,
                              subTitle: AppStrings.imageViewer,
                              imageUrls: images,
                              initialIndex: index,
                            ),
                          ),
                  child: _networkImage(url, fit: BoxFit.cover),
                ),
                if (deleting)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  )
                else
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _galleryDeleteButton(url),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Small glass delete button pinned to a gallery tile. Confirms before
  /// removing the image via [EarnArtistController.removeGalleryImage].
  Widget _galleryDeleteButton(String url) {
    return GestureDetector(
      onTap: () => _confirmDeleteGalleryImage(url),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 0.8),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            size: 16, color: Colors.white),
      ),
    );
  }

  Future<void> _confirmDeleteGalleryImage(String url) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText('Remove photo?',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor),
        content: CustomText(
            'This photo will be removed from your gallery.',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: CustomText(AppStrings.cancel.tr,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryTextColor),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: CustomText('Remove',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.red.shade400),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _earnCtrl.removeGalleryImage(url);
    }
  }

  // ─── BANNER EMPTY STATE (certificate / gallery) ─────────────────────────
  /// A full-bleed, photo-backed invitation to fill an empty section. The
  /// banner carries a section [eyebrow] top-left, a one-line [message], and a
  /// glass action pill — the whole card taps through to [onTap], so the state
  /// reads as "start here" rather than "nothing to see".
  Widget _bannerEmptyState({
    required String image,
    required String eyebrow,
    required String message,
    required String ctaLabel,
    required IconData ctaIcon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hMargin),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 190,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: AssetImage(image),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Blur + top→bottom scrim so the copy stays legible over any art.
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.34),
                        Colors.black.withValues(alpha: 0.64),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 16,
                child: Text(
                  eyebrow.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppConstants.OpenSans,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.92),
                    letterSpacing: 1.6,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LocalAssets(
                      imagePath: AppImageAssets.noMeContent,
                      height: 64,
                      width: 64,
                    ),
                    SizedBox(height: SizeConfig.size10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: CustomText(
                        message,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: SizeConfig.size12),
                    _bannerCtaPill(ctaLabel, ctaIcon),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bannerCtaPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.42),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          CustomText(label,
              fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
        ],
      ),
    );
  }

  Widget _galleryUploadingRow() {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.primaryColor),
          ),
        ),
        SizedBox(width: SizeConfig.size10),
        CustomText('Uploading photos…',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor),
      ],
    );
  }

  /// Picks a single photo and hands it to [EarnArtistController.addGalleryImages],
  /// which mints a presigned S3 url, uploads the bytes, then refetches.
  Future<void> _onAddGalleryPhotos() async {
    if (_earnCtrl.isGalleryUploading.value) return;
    final path = await PhotoPickerService.pickSinglePhoto(
      context,
      'Add Photo',
    );
    if (path == null || path.isEmpty) return;
    await _earnCtrl.addGalleryImages([path]);
  }

  /// Add / edit-certificate sheet (name + description + optional media).
  /// `certificatesAndAwards` REPLACES on PUT, so add appends and edit swaps the
  /// entry at [editIndex]; either way the whole list is re-sent. New media uses
  /// the S3 presigned flow; on edit the entry's existing media is preserved.
  void _openCertificateSheet(EarnArtist artist,
      {int? editIndex, ArtistCertificate? existing}) {
    final isEdit = editIndex != null;
    _earnCtrl.seedCertificateInputs();
    if (isEdit && existing != null) {
      _earnCtrl.certNameController.text = existing.name;
      _earnCtrl.certDescController.text = existing.description;
      // Show the already-uploaded media as removable previews (instead of an
      // empty upload zone).
      _earnCtrl.certExistingMedia.assignAll(existing.media);
    }
    _showUpdateSheet(
      title: isEdit ? 'Edit Certificate / Award' : 'Add Certificate / Award',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeledField(
            'Title',
            CommonTextField(
              textEditController: _earnCtrl.certNameController,
              hintText: 'e.g. State Art Award 2024',
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          _labeledField(
            'Description',
            CommonTextField(
              textEditController: _earnCtrl.certDescController,
              hintText: 'Short description',
              maxLine: 3,
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          _labeledField(
              isEdit ? 'Add Media (optional)' : 'Media (optional)',
              _certMediaPicker()),
          SizedBox(height: SizeConfig.paddingL),
          Obx(() => CustomBtn(
                radius: SizeConfig.size10,
                bgColor: AppColors.primaryColor,
                title: _earnCtrl.isUpdating.value
                    ? null
                    : (isEdit ? AppStrings.update.tr : AppStrings.add.tr),
                isLoading: _earnCtrl.isUpdating.value,
                onTap: () async {
                  final ok = isEdit
                      ? await _earnCtrl.updateCertificate(
                          index: editIndex,
                          name: _earnCtrl.certNameController.text,
                          description: _earnCtrl.certDescController.text,
                          existing: artist.certificatesAndAwards,
                          keptMedia: _earnCtrl.certExistingMedia.toList(),
                          newMediaPaths: _earnCtrl.certMediaPaths.toList(),
                        )
                      : await _earnCtrl.addCertificate(
                          name: _earnCtrl.certNameController.text,
                          description: _earnCtrl.certDescController.text,
                          existing: artist.certificatesAndAwards,
                        );
                  if (ok) Get.back();
                },
              )),
        ],
      ),
    );
  }

  /// Horizontal strip of picked certificate images + an "add" tile. The picked
  /// paths live on the controller so the strip survives sheet rebuilds and is
  /// cleared each time the sheet reopens.
  Widget _certMediaPicker() {
    return Obx(() {
      final existing = _earnCtrl.certExistingMedia;
      final paths = _earnCtrl.certMediaPaths;
      final total = existing.length + paths.length;
      // Nothing yet → a full-width upload zone. Otherwise show the already-
      // uploaded media (network, removable) first, then freshly-picked local
      // images, then a compact "Add more" row.
      if (total == 0) return _fullWidthUploadZone();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < existing.length; i++) ...[
            _fullWidthNetworkMediaPreview(existing[i], i),
            SizedBox(height: SizeConfig.size10),
          ],
          for (var i = 0; i < paths.length; i++) ...[
            _fullWidthMediaPreview(paths[i], i),
            SizedBox(height: SizeConfig.size10),
          ],
          if (total < 5) _addMoreZone(),
        ],
      );
    });
  }

  /// Full-width preview of an already-uploaded certificate image (network),
  /// with a remove button that drops it from [certExistingMedia] so the save
  /// PUTs the certificate without it.
  Widget _fullWidthNetworkMediaPreview(String url, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: double.infinity,
            height: 170,
            child: _networkImage(url, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () => _earnCtrl.certExistingMedia.removeAt(index),
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fullWidthMediaPreview(String path, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(path),
            width: double.infinity,
            height: 170,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: double.infinity,
              height: 170,
              color: const Color(0xFFF1F1F3),
              alignment: Alignment.center,
              child: Icon(Icons.broken_image_outlined,
                  size: 28, color: AppColors.secondaryTextColor),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () => _earnCtrl.certMediaPaths.removeAt(index),
            customBorder: const CircleBorder(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addMoreZone() {
    return InkWell(
      onTap: _pickCertMedia,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 18, color: AppColors.primaryColor),
            SizedBox(width: SizeConfig.size8),
            CustomText('Add more',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor),
          ],
        ),
      ),
    );
  }

  /// Picks up to 5 certificate images into [certMediaPaths] (de-duped, capped).
  Future<void> _pickCertMedia() async {
    final picked = await PhotoPickerService.pickMultiplePhotos(
      context,
      'Add Media',
      maxImages: 5,
    );
    if (picked == null || picked.isEmpty) return;
    for (final p in picked) {
      if (_earnCtrl.certMediaPaths.length >= 5) break;
      if (!_earnCtrl.certMediaPaths.contains(p)) {
        _earnCtrl.certMediaPaths.add(p);
      }
    }
  }

  Widget _fullWidthUploadZone() {
    return InkWell(
      onTap: _pickCertMedia,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 24, color: AppColors.primaryColor),
            SizedBox(height: SizeConfig.size8),
            CustomText('Upload certificate photo',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor),
            SizedBox(height: SizeConfig.size4),
            CustomText('PNG or JPG · up to 5',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor),
          ],
        ),
      ),
    );
  }

  // ─── SHARED EDIT-SHEET SCAFFOLD ─────────────────────────────────────────
  /// Common bottom-sheet shell for every inline edit (drag handle, title +
  /// close, keyboard-aware padding). Mirrors the self-profession service
  /// screen's `_showCommonUpdateSheet`.
  void _showUpdateSheet({required String title, required Widget content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: SizeConfig.size16,
            right: SizeConfig.size16,
            top: SizeConfig.size12,
            bottom: SizeConfig.size24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryTextColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: CustomText(title,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor),
                  ),
                  InkWell(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size12),
              content,
            ],
          ),
        ),
      ),
    );
  }

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.mainTextColor),
        SizedBox(height: SizeConfig.size8),
        field,
      ],
    );
  }

  // ─── EMPTY-STATE + SHARED PRIMITIVES ────────────────────────────────────
  Widget _emptySection(String title, String message,
      {String? trailingLabel, IconData? trailingIcon, VoidCallback? onTrailing}) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title,
              trailingLabel: trailingLabel,
              trailingIcon: trailingIcon,
              onTrailing: onTrailing ?? _comingSoon),
          SizedBox(height: SizeConfig.size12),
          CustomText(message,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor),
        ],
      ),
    );
  }

  Widget _networkImage(String url, {BoxFit fit = BoxFit.cover}) {
    if (url.isEmpty) return _imagePlaceholder(Icons.image_outlined);
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => Container(color: const Color(0xFFF1F1F3)),
      errorWidget: (_, __, ___) =>
          _imagePlaceholder(Icons.broken_image_outlined),
    );
  }

  Widget _imagePlaceholder(IconData icon) => Container(
        color: const Color(0xFFF1F1F3),
        alignment: Alignment.center,
        child: Icon(icon, size: 28, color: AppColors.secondaryTextColor),
      );

  // ─── TEXT HELPERS (copied from professionals_main.dart) ─────────────────
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  String _formatJoinedDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  String _formatDob(DateOfBirth dob) {
    final months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final month =
        (dob.month != null && dob.month! >= 1 && dob.month! <= 12)
            ? months[dob.month!]
            : '';
    final day = dob.date?.toString() ?? '';
    if (month.isEmpty && day.isEmpty) return '';
    return '$day $month'.trim();
  }
}
