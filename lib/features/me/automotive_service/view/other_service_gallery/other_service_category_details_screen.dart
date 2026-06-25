import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/automotive_service/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/automotive_service/controller/other_service_photo_controller.dart';
import 'package:BlueEra/features/me/others/model/business_profile_full_model.dart';
import 'package:BlueEra/features/me/others/model/other_service_gallery_res_model.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_dialog.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Gallery-category details page for the automotive_service "Special
/// Automotive" flow.
///
/// In addition to the original photo grid (kept 1:1, including the
/// per-tile delete confirmation), this screen now surfaces profile
/// context so a viewer can understand *whose* gallery they're looking
/// at without having to bounce back to the main profile screen:
///
///   * **Details card** — profile logo, name, location/address, and an
///     expandable description, taken from the already-loaded
///     `AutomotiveBusinessProfileFullController.businessProfile`.
///   * **QR code card** — encodes the business-profile id (the same id
///     used everywhere else in the module). Sharing the screen-shot or
///     letting someone scan the QR lands them back on this profile.
///   * **Contact Us card** — phone numbers, email addresses, website
///     and the primary branch address pulled from `contactUs[0]`. Every
///     row is tap-actionable: phone dials, email opens compose, website
///     opens in the browser, address opens Google Maps with the saved
///     coordinates when available.
///
/// Photo grid + delete confirmation are unchanged so existing
/// functionality is preserved.
class OtherServiceCategoryDetailsScreen extends StatelessWidget {
  final OtherServiceGalleryData categoryData;

  /// `getOrPut` (not `Get.find`) so deep-linking straight to this
  /// screen — without first going through `AutomotiveServiceMain` —
  /// doesn't blow up with "controller not registered". When the parent
  /// already registered the instance, this is a no-op.
  final OtherServicePhotoPhotoController controller =
      getOrPut(() => OtherServicePhotoPhotoController());
  final AutomotiveBusinessProfileFullController profileController =
      getOrPut(() => AutomotiveBusinessProfileFullController());

  OtherServiceCategoryDetailsScreen({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: CommonBackAppBar(
        title: categoryData.title,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            SizeConfig.size12, SizeConfig.size12, SizeConfig.size12, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile / contact / QR depend on the live businessProfile,
            // so each section is its own Obx for fine-grained rebuilds.
            Obx(() => _detailsCard(profileController.businessProfile.value)),
            SizedBox(height: SizeConfig.size10),
            Obx(() => _qrCard(profileController.businessProfile.value)),
            SizedBox(height: SizeConfig.size10),
            Obx(
                () => _contactUsCard(profileController.businessProfile.value)),
            SizedBox(height: SizeConfig.size14),

            // Photos section — header + live grid.
            Obx(() {
              final currentCategory = controller.propertyPhotosList.firstWhere(
                (item) => item.id == categoryData.id,
                orElse: () => categoryData,
              );
              final images = currentCategory.imageUrls ?? const <String>[];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _photosHeader(images.length),
                  SizedBox(height: SizeConfig.size10),
                  if (images.isEmpty)
                    _emptyPhotosPlaceholder()
                  else
                    _photosGrid(context, images),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Details card — profile logo + name + description + address
  // ────────────────────────────────────────────────────────────────
  Widget _detailsCard(BusinessProfileData? data) {
    final profile = data?.profile;
    final logo = (profile?.logoUrl ?? '').trim();
    final name = (profile?.profileName ?? '').trim();
    final description = (profile?.description ?? '').trim();
    final location = profile?.location;
    final address = _formatAddress(location);

    // When the profile isn't loaded yet there's nothing useful to show
    // — collapse the whole card so the gallery still reads cleanly.
    if (name.isEmpty &&
        description.isEmpty &&
        address.isEmpty &&
        logo.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedAvatarWidget(
                imageUrl: logo,
                size: SizeConfig.size57,
                borderColor: AppColors.greyE5,
                borderRadius: SizeConfig.size12,
              ),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name.isNotEmpty)
                      CustomText(
                        name,
                        fontSize: SizeConfig.large,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (categoryData.title?.isNotEmpty == true) ...[
                      SizedBox(height: SizeConfig.size4),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size8,
                            vertical: SizeConfig.size3),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.3)),
                        ),
                        child: CustomText(
                          categoryData.title ?? '',
                          fontSize: SizeConfig.small,
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            Divider(color: AppColors.greyE5, height: SizeConfig.size20),
            CustomText(
              description,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryTextColor,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (address.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size10),
            _iconRow(
              icon: Icons.location_on_outlined,
              label: address,
              onTap: () => _openMaps(location),
            ),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // QR code card — scan to land back on this profile
  // ────────────────────────────────────────────────────────────────
  Widget _qrCard(BusinessProfileData? data) {
    final qrData = (data?.profile?.sId ?? '').trim().isNotEmpty
        ? data!.profile!.sId!.trim()
        : otherServiceIDGlobal.trim();
    if (qrData.isEmpty) return const SizedBox.shrink();

    final qrSize = SizeConfig.screenWidth * 0.45;

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size14),
      child: Column(
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
                child: Icon(Icons.qr_code_2_rounded,
                    size: 18, color: AppColors.primaryColor),
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText(
                AppStrings.otherProfileQr.tr,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
          Divider(color: AppColors.greyE5, height: SizeConfig.size20),
          Container(
            padding: EdgeInsets.all(SizeConfig.size12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyE5, width: 1),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: qrSize,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              gapless: true,
              backgroundColor: Colors.white,
            ),
          ),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            AppStrings.otherScanToViewProfile.tr,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
          SizedBox(height: SizeConfig.size10),
          // Copy ID — the QR encodes only the id; surface the same id
          // as plain text so the user can paste it into a chat / mail.
          InkWell(
            onTap: () => _copyToClipboard(qrData, label: 'Profile ID'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size12,
                  vertical: SizeConfig.size6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded,
                      size: 14, color: AppColors.primaryColor),
                  SizedBox(width: SizeConfig.size6),
                  CustomText(
                    AppStrings.otherCopyProfileId.tr,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Contact Us card — phones, emails, website, address
  // ────────────────────────────────────────────────────────────────
  Widget _contactUsCard(BusinessProfileData? data) {
    final contacts = data?.contactUs ?? const <ContactUsOtherProfile>[];
    if (contacts.isEmpty) return const SizedBox.shrink();

    // De-duped phone / email lists across all branches' departments
    // — the same number can appear under multiple departments and
    // showing it twice is noise.
    final phones = <String>{};
    final emails = <String>{};
    for (final c in contacts) {
      for (final d in (c.departments ?? const <OtherProfileDepartments>[])) {
        final p = (d.phone ?? '').trim();
        final e = (d.email ?? '').trim();
        if (p.isNotEmpty) phones.add(p);
        if (e.isNotEmpty) emails.add(e);
      }
    }

    final primary = contacts.first;
    final branchAddress = _formatAddress(primary.branch?.location);
    final website = (primary.branch?.website ?? '').trim();

    final rows = <Widget>[
      if (phones.isNotEmpty)
        ...phones.map((p) => _iconRow(
              icon: Icons.call_rounded,
              label: p,
              trailingIcon: Icons.copy_rounded,
              onTap: () => _dial(p),
              onTrailingTap: () => _copyToClipboard(p, label: 'Phone'),
            )),
      if (emails.isNotEmpty)
        ...emails.map((e) => _iconRow(
              icon: Icons.mail_outline_rounded,
              label: e,
              trailingIcon: Icons.copy_rounded,
              onTap: () => _composeEmail(e),
              onTrailingTap: () => _copyToClipboard(e, label: 'Email'),
            )),
      if (website.isNotEmpty)
        _iconRow(
          icon: Icons.public_rounded,
          label: website,
          onTap: () => _openUrl(website),
        ),
      if (branchAddress.isNotEmpty)
        _iconRow(
          icon: Icons.location_on_outlined,
          label: branchAddress,
          trailingIcon: Icons.directions_rounded,
          onTap: () => _openMaps(primary.branch?.location),
          onTrailingTap: () => _openMaps(primary.branch?.location),
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size14),
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
                child: Icon(Icons.contact_phone_outlined,
                    size: 16, color: AppColors.primaryColor),
              ),
              SizedBox(width: SizeConfig.size8),
              CustomText(
                AppStrings.otherContactUs.tr,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            ],
          ),
          Divider(color: AppColors.greyE5, height: SizeConfig.size20),
          ...List.generate(rows.length, (i) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i == rows.length - 1 ? 0 : SizeConfig.size10),
              child: rows[i],
            );
          }),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Photos section — header + grid (existing behaviour preserved)
  // ────────────────────────────────────────────────────────────────
  Widget _photosHeader(int count) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
      child: Row(
        children: [
          Icon(Icons.photo_library_outlined,
              size: 18, color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size8),
          CustomText(
            AppStrings.gallery.tr,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
          SizedBox(width: SizeConfig.size6),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: CustomText(
              '$count',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPhotosPlaceholder() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size40),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined,
              size: 48,
              color: AppColors.secondaryTextColor.withValues(alpha: 0.6)),
          SizedBox(height: SizeConfig.size8),
          CustomText(
            AppStrings.otherNoPhotosYet.tr,
            fontSize: SizeConfig.medium,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _photosGrid(BuildContext context, List<String> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Stack(
          children: [
            InkWell(
              onTap: () {
                navigatePushTo(
                  context,
                  ImageViewScreen(
                    subTitle: categoryData.title,
                    appBarTitle: AppStrings.imageViewer,
                    imageUrls: images,
                    initialIndex: index,
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Delete button overlay — confirmation flow + controller
            // call kept identical to the previous implementation.
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () async {
                  await showCommonDialog(
                    context: context,
                    text: AppStrings.hotelConfirmDeleteImage.tr,
                    confirmCallback: () async {
                      Get.back();
                      await controller.deleteOtherServiceController(
                        imgId: categoryData.id ?? "",
                        imgUrl: images[index],
                      );
                    },
                    cancelCallback: () {
                      Navigator.of(context).pop(); // Close the dialog
                    },
                    confirmText: AppStrings.yes,
                    cancelText: AppStrings.no,
                  );
                },
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.red.withValues(alpha: 0.8),
                  child: const Icon(Icons.delete,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Helpers — formatting, launchers, generic icon row
  // ────────────────────────────────────────────────────────────────

  /// Compose-friendly address string. Returns "" when the location is
  /// missing or only carries empty fields.
  String _formatAddress(Location? location) {
    if (location == null) return '';
    final parts = <String>[
      if ((location.name ?? '').trim().isNotEmpty) location.name!.trim(),
      if ((location.address ?? '').trim().isNotEmpty) location.address!.trim(),
    ];
    return parts.join(', ');
  }

  /// One row used inside the cards — leading icon circle, label that
  /// fills the remaining width, an optional trailing affordance.
  Widget _iconRow({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    IconData? trailingIcon,
    VoidCallback? onTrailingTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: SizeConfig.size4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: AppColors.primaryColor),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: CustomText(
                label,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w500,
                color: AppColors.mainTextColor,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingIcon != null) ...[
              SizedBox(width: SizeConfig.size6),
              InkWell(
                onTap: onTrailingTap ?? onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsets.all(SizeConfig.size6),
                  child: Icon(trailingIcon,
                      size: 16, color: AppColors.secondaryTextColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _composeEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUrl(String url) async {
    final normalised =
        url.startsWith('http://') || url.startsWith('https://')
            ? url
            : 'https://$url';
    final uri = Uri.tryParse(normalised);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Opens Maps either with lat/lng (when present) or with the address
  /// as a free-text search — both forms launch the same external app.
  Future<void> _openMaps(Location? location) async {
    if (location == null) return;
    final coords = location.coordinates;
    Uri? uri;
    if (coords != null && coords.length >= 2) {
      // BlueEra stores [longitude, latitude] in GeoJSON order; flip for
      // the URL which expects lat,lng.
      final lat = coords[1];
      final lng = coords[0];
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      final address = _formatAddress(location);
      if (address.isEmpty) return;
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyToClipboard(String value,
      {required String label}) async {
    await Clipboard.setData(ClipboardData(text: value));
    commonSnackBar(message: '$label copied');
  }
}
