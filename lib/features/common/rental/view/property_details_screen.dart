import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/features/common/rental/controller/property_controller.dart';
import 'package:BlueEra/features/common/rental/model/property_model.dart';
import 'package:BlueEra/features/common/rental/repo/property_repo.dart';
import 'package:BlueEra/features/common/rental/widget/rental_form_widgets.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:get/get.dart';
import 'dart:io';

class PropertyDetailsScreen extends StatefulWidget {
  final PropertyModel property;
  final bool isOwner;

  const PropertyDetailsScreen({
    super.key,
    required this.property,
    this.isOwner = true,
  });

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  late PropertyModel _property;
  int _currentImage = 0;
  bool _showFullDesc = false;

  PropertyModel get p => _property;
  bool get _isOwner => widget.isOwner;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: p.propertyName,
        isShadowShow: false,
        showElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: SizeConfig.size12),
            _buildTitleCard(),
            SizedBox(height: SizeConfig.size10),
            _buildListedByCard(),
            SizedBox(height: SizeConfig.size10),
            _buildKeyHighlightsCard(),
            SizedBox(height: SizeConfig.size10),
            _buildPropertyInfoCard(),
            if (!_isOwner) ...[
              SizedBox(height: SizeConfig.size10),
              _buildRateCard(),
            ],
            if (p.propertyImages.length > 1) ...[
              SizedBox(height: SizeConfig.size10),
              _buildGalleryCard(),
            ],
            SizedBox(height: SizeConfig.size24),
          ],
        ),
      ),
      bottomNavigationBar: _isOwner
          ? null
          : Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: SafeArea(
              child: InkWell(
                onTap: _openChat,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LocalAssets(
                        imagePath: AppIconAssets.chat,
                        height: 18.0,
                        width: 18.0,
                        imgColor: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      CustomText(
                        AppStrings.chatWithOwner.tr,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  void _openChat() {
    final ownerId = p.userId;
    if (ownerId == null || ownerId.isEmpty) {
      commonSnackBar(message: AppStrings.ownerNotAvailableForChat.tr);
      return;
    }
    final chatController = Get.find<ChatViewController>();
    chatController.checkChatConnectionAndOpenChat(
        userId: ownerId, route: AppConstants.route_discover);
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD METHODS
  // ═══════════════════════════════════════════════════════════

  Widget _buildImageSlider() {
    final images = p.propertyImages;
    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        child: Container(
          height: 220,
          color: AppColors.primaryColor.withValues(alpha: 0.06),
          child: Stack(
            children: [
              Center(
                child: Icon(Icons.holiday_village_outlined,
                    size: 60,
                    color: AppColors.primaryColor.withValues(alpha: 0.3)),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _circleEditButton(onTap: _showEditImagesSheet),
              ),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _currentImage = i),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _openImageViewer(i),
                child: Image.network(
                  images[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.primaryColor.withValues(alpha: 0.06),
                    child: const Center(
                        child: Icon(Icons.broken_image_outlined, size: 40)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _circleEditButton(onTap: _showEditImagesSheet),
            ),
            if (images.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (i) => Container(
                      width: _currentImage == i ? 20 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _currentImage == i
                            ? AppColors.primaryColor
                            : Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleCard() {
    final desc = p.description;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 0.5,
            offset: const Offset(-5, 0),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            spreadRadius: 0.5,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageSlider(),
          Padding(
            padding: EdgeInsets.all(SizeConfig.size15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomText(
                        p.propertyName,
                        fontSize: SizeConfig.extraLarge,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _editIcon(onTap: _showEditTitleCardSheet),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightYellowShade,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.yellowCB,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: AppColors.rating),
                          const SizedBox(width: 3),
                          CustomText(
                            p.rating.toStringAsFixed(1),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.geryFC,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greyE0),
                      ),
                      child: CustomText(
                        p.typeLabel,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  CustomText(
                    _showFullDesc
                        ? desc
                        : (desc.length > 120
                            ? '${desc.substring(0, 120)}...'
                            : desc),
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                  ),
                  if (desc.length > 120)
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showFullDesc = !_showFullDesc),
                      child: CustomText(
                        _showFullDesc
                            ? AppStrings.showLess.tr
                            : AppStrings.readMore.tr,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryColor,
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                CustomText(
                  p.formattedPrice,
                  fontSize: SizeConfig.large18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 10),
                _buildLocationStrip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStrip() {
    final loc = p.displayLocation;
    if (loc.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.geryFC,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              size: 14, color: AppColors.secondaryTextColor),
          const SizedBox(width: 4),
          Expanded(
            child: CustomText(
              loc,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// "Listed By" card — shows the lister's name + role. Sits above Key
  /// Highlights. Owners get the edit pencil (same change flow as the
  /// other cards); on the discover side it's view-only.
  Widget _buildListedByCard() {
    final name = p.listedByName ?? '';
    final role = _listedBy ?? '';
    final hasInfo = name.isNotEmpty || role.isNotEmpty;
    // View-only (discover): nothing to show → hide. Owners always see
    // the card so they can fill the details in.
    if (!hasInfo && !_isOwner) return const SizedBox.shrink();

    final rows = <(String, String)>[];
    if (name.isNotEmpty) rows.add((AppStrings.listerName.tr, name));
    if (role.isNotEmpty) rows.add((AppStrings.filterLabelListedBy.tr, role));

    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.filterLabelListedBy.tr,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
              ),
              _editIcon(onTap: _showEditListedBySheet),
            ],
          ),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            CustomText(
              AppStrings.notSpecified.tr,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        rows[i].$1,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                    Flexible(
                      child: CustomText(
                        rows[i].$2,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Divider(
                  height: 1,
                  color: AppColors.secondaryTextColor.withValues(alpha: 0.1),
                ),
            ],
        ],
      ),
    );
  }

  /// Discover-side card letting the viewer rate this property. Tapping a
  /// star opens a sheet pre-set to that rating with an optional comment.
  Widget _buildRateCard() {
    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.rateThisProperty.tr,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(height: 4),
          CustomText(
            AppStrings.tapStarToShareExperience.tr,
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => _showRateSheet(i + 1),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: const Icon(
                    Icons.star_border_rounded,
                    size: 36,
                    color: AppColors.rating,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showRateSheet(int initial) {
    int selected = initial;
    final commentCtrl = TextEditingController();
    _openEditSheet(
      title: AppStrings.rateThisProperty.tr,
      saveLabel: AppStrings.submitRating.tr,
      children: [
        StatefulBuilder(
          builder: (ctx, setLocal) {
            return Row(
              children: List.generate(5, (i) {
                final filled = i < selected;
                return GestureDetector(
                  onTap: () => setLocal(() => selected = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 44,
                      color: AppColors.rating,
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.commentOptional.tr,
          hint: AppStrings.shareYourExperienceHint.tr,
          controller: commentCtrl,
          maxLines: 3,
          maxLength: 500,
        ),
      ],
      onSave: () {
        if (selected <= 0) {
          commonSnackBar(message: AppStrings.pleaseSelectRating.tr);
          return;
        }
        // Rating submission not wired up yet — just acknowledge for now.
        Get.back();
        commonSnackBar(message: AppStrings.ratingComingSoon.tr);
      },
    );
  }

  Widget _buildKeyHighlightsCard() {
    final highlights = _extractHighlights();
    if (highlights.isEmpty) return const SizedBox.shrink();

    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.keyHighlights.tr,
            fontSize: SizeConfig.large,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                highlights.map((h) => _highlightChip(h.$1, h.$2)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _highlightChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.secondaryTextColor.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          CustomText(
            label,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.mainTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyInfoCard() {
    final info = _extractPropertyInfo();
    if (info.isEmpty) return const SizedBox.shrink();

    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.propertyInformation.tr,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
              ),
              _editIcon(onTap: _showEditSpecsSheet),
            ],
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < info.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      info[i].$1,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  Flexible(
                    child: CustomText(
                      info[i].$2,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
            if (i < info.length - 1)
              Divider(
                height: 1,
                color: AppColors.secondaryTextColor.withValues(alpha: 0.1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGalleryCard () {
    return CustomFormCard(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      isBoxShadowAvail: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomText(
                  AppStrings.gallery.tr,
                  fontSize: SizeConfig.large,
                  fontWeight: FontWeight.w800,
                  color: AppColors.mainTextColor,
                ),
              ),
              _editIcon(onTap: _showEditImagesSheet),
            ],
          ),
          const SizedBox(height: 10),
          _buildStaggeredGallery(),
        ],
      ),
    );
  }

  Widget _buildStaggeredGallery() {
    final imgs = p.propertyImages;
    final rows = <Widget>[];

    for (var i = 0; i < imgs.length; i += 2) {
      final hasTwo = i + 1 < imgs.length;
      rows.add(
        SizedBox(
          height: 140,
          child: Row(
            children: [
              Expanded(
                flex: hasTwo ? 3 : 1,
                child: _galleryImage(imgs[i], i),
              ),
              if (hasTwo) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _galleryImage(imgs[i + 1], i + 1),
                ),
              ],
            ],
          ),
        ),
      );
      if (i + 2 < imgs.length) rows.add(const SizedBox(height: 8));
    }

    return Column(children: rows);
  }

  Widget _galleryImage(String url, int index) {
    return GestureDetector(
      onTap: () => _openImageViewer(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            child: const Center(
                child: Icon(Icons.broken_image_outlined, size: 24)),
          ),
        ),
      ),
    );
  }

  /// Opens the shared full-screen image viewer at [index].
  void _openImageViewer(int index) {
    final images = p.propertyImages;
    if (images.isEmpty) return;
    navigatePushTo(
      context,
      ImageViewScreen(
        subTitle: p.propertyName,
        appBarTitle: AppStrings.imageViewer,
        imageUrls: images,
        initialIndex: index,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EDIT ICONS
  // ═══════════════════════════════════════════════════════════

  Widget _editIcon({VoidCallback? onTap}) {
    if (!_isOwner) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: SvgPicture.asset(
        AppIconAssets.pencilEditIcon,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(
          AppColors.secondaryTextColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _circleEditButton({VoidCallback? onTap}) {
    if (!_isOwner) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.mainTextColor.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          AppIconAssets.pencilEditIcon,
          width: 18,
          height: 18,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EDIT BOTTOM SHEETS
  // ═══════════════════════════════════════════════════════════

  void _openEditSheet({
    required String title,
    required List<Widget> children,
    required VoidCallback onSave,
    String? saveLabel,
  }) {
    saveLabel ??= AppStrings.update.tr;
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE2EE),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          title,
                          fontSize: SizeConfig.large18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mainTextColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF4F6FA),
                            border:
                                Border.all(color: const Color(0xFFDDE2EE)),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: Color(0xFF505050)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: RentalPrimaryButton(label: saveLabel, onTap: onSave),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Edit Title Card (Name, Description, Price, Location) ──

  void _showEditTitleCardSheet() {
    final nameCtrl = TextEditingController(text: p.propertyName);
    final descCtrl = TextEditingController(text: p.description);
    final locCtrl = TextEditingController(text: p.displayLocation);

    final hasRange = p.hasPriceRange;
    // `p.price` / `priceRange.min` / `priceRange.max` are strings now;
    // skip the "0" placeholder so the edit sheet doesn't pre-fill a
    // useless zero when the property was created without a price.
    final priceCtrl = TextEditingController(
      text: hasRange || p.price.isEmpty || p.price == '0' ? '' : p.price,
    );
    final fromCtrl = TextEditingController(
      text: hasRange ? p.priceRange!.min : '',
    );
    final toCtrl = TextEditingController(
      text: hasRange ? p.priceRange!.max : '',
    );

    bool isRange = hasRange;

    _openEditSheet(
      title: AppStrings.editPropertyDetails.tr,
      children: [
        RentalLabeledField(
          label: AppStrings.propertyNameLabel.tr,
          hint: AppStrings.enterPropertyName.tr,
          controller: nameCtrl,
          maxLength: 70,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.description.tr,
          hint: AppStrings.enterDescription.tr,
          controller: descCtrl,
          maxLines: 4,
          maxLength: 2000,
        ),
        const SizedBox(height: 16),
        StatefulBuilder(
          builder: (ctx, setLocal) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RentalChipSelector(
                  label: AppStrings.priceTypeLabel.tr,
                  options: [
                    AppStrings.fixedPrice.tr,
                    AppStrings.priceRangeLabel.tr,
                  ],
                  initialIndex: isRange ? 1 : 0,
                  onChanged: (i) => setLocal(() => isRange = i == 1),
                ),
                const SizedBox(height: 16),
                if (!isRange)
                  RentalLabeledField(
                    label: AppStrings.price.tr,
                    hint: AppStrings.enterPrice.tr,
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                  )
                else ...[
                  RentalLabeledField(
                    label: AppStrings.minimumPrice.tr,
                    hint: AppStrings.enterMinPrice.tr,
                    controller: fromCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  RentalLabeledField(
                    label: AppStrings.maximumPrice.tr,
                    hint: AppStrings.enterMaxPrice.tr,
                    controller: toCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.propertyLocationLabel.tr,
          hint: AppStrings.enterAddress.tr,
          controller: locCtrl,
          maxLines: 2,
        ),
      ],
      onSave: () {
        final updates = <String, dynamic>{
          'propertyName': nameCtrl.text.trim(),
          'description': descCtrl.text.trim(),
        };

        if (isRange) {
          updates['priceRange'] = {
            'min': int.tryParse(fromCtrl.text.trim()) ?? 0,
            'max': int.tryParse(toCtrl.text.trim()) ?? 0,
          };
        } else {
          updates['price'] = int.tryParse(priceCtrl.text.trim()) ?? 0;
        }

        final typeKey = _subTypeKey();
        if (typeKey != null) {
          updates[typeKey] = {'propertyLocation': locCtrl.text.trim()};
        }

        _updateFields(updates);
      },
    );
  }

  // ── Edit Listed By (Name + Role) ──

  void _showEditListedBySheet() {
    final nameCtrl = TextEditingController(text: p.listedByName ?? '');
    int roleIdx = _indexOf(PropertyController.listedByOptions, _listedBy);
    // New Projects has no `listedBy` role on its sub-model — only the
    // free-text name is editable there.
    final hasRole = _subTypeHasListedBy;

    _openEditSheet(
      title: AppStrings.editListedBy.tr,
      children: [
        RentalLabeledField(
          label: AppStrings.listerName.tr,
          hint: AppStrings.enterName.tr,
          controller: nameCtrl,
          maxLength: 70,
        ),
        if (hasRole) ...[
          const SizedBox(height: 16),
          RentalChipSelector(
            label: AppStrings.filterLabelListedBy.tr,
            options: PropertyController.listedByOptions,
            initialIndex: roleIdx,
            onChanged: (i) => roleIdx = i,
          ),
        ],
      ],
      onSave: () {
        final updates = <String, dynamic>{
          'listedByName': nameCtrl.text.trim(),
        };
        // The role lives on the type-specific sub-model. Re-send the
        // whole sub-model (with only `listedBy` swapped) so the PUT
        // doesn't wipe its other fields.
        if (hasRole) {
          final key = _subTypeKey();
          final existing = _currentSubTypeJson();
          if (key != null && existing != null) {
            existing['listedBy'] = PropertyController.listedByOptions[roleIdx];
            updates[key] = existing;
          }
        }
        _updateFields(updates);
      },
    );
  }

  // ── Edit Images ──

  void _showEditImagesSheet() {
    final newPaths = <String>[];

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setLocal) {
          final allImages = [...p.propertyImages];
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDE2EE),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CustomText(
                              AppStrings.editPhotos.tr,
                              fontSize: SizeConfig.large18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mainTextColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF4F6FA),
                                border: Border.all(
                                    color: const Color(0xFFDDE2EE)),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 18, color: Color(0xFF505050)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          AppStrings.currentPhotosFmt.trParams(
                              {'count': '${allImages.length}'}),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                        ),
                        const SizedBox(height: 10),
                        if (allImages.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                            itemCount: allImages.length,
                            itemBuilder: (_, i) => ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                allImages[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.06),
                                  child: const Center(
                                      child: Icon(
                                          Icons.broken_image_outlined,
                                          size: 24)),
                                ),
                              ),
                            ),
                          ),
                        if (newPaths.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          CustomText(
                            AppStrings.newPhotosFmt.trParams(
                                {'count': '${newPaths.length}'}),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                          ),
                          const SizedBox(height: 10),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                            ),
                            itemCount: newPaths.length,
                            itemBuilder: (_, i) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(newPaths[i]),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setLocal(
                                        () => newPaths.removeAt(i)),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _photoPickTile(
                                icon: Icons.camera_alt_outlined,
                                label: AppStrings.cameraLabel.tr,
                                onTap: () async {
                                  final path =
                                      await PhotoPickerService.pickFromCamera(
                                          ctx);
                                  if (path != null) {
                                    setLocal(() => newPaths.add(path));
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _photoPickTile(
                                icon: Icons.photo_library_outlined,
                                label: AppStrings.galleryLabel.tr,
                                onTap: () async {
                                  final paths = await PhotoPickerService
                                      .pickMultipleFromGallery(ctx,
                                          maxImages: 4);
                                  if (paths != null && paths.isNotEmpty) {
                                    setLocal(() => newPaths.addAll(paths));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (newPaths.isNotEmpty)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: RentalPrimaryButton(
                        label: AppStrings.uploadPhotosCta.tr,
                        onTap: () => _uploadImages(newPaths),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Widget _photoPickTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F0FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.primaryColor),
            const SizedBox(height: 6),
            CustomText(
              label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Property Specs ──

  void _showEditSpecsSheet() {
    switch (p.propertyType) {
      case 'HouseAndApartment':
        _showHouseSpecsSheet();
        break;
      case 'LandAndPlots':
        _showLandSpecsSheet();
        break;
      case 'ShopAndOffices':
        _showShopSpecsSheet();
        break;
      case 'NewProjectsAndProperties':
        _showNewProjectSpecsSheet();
        break;
      case 'PGAndGuestHouse':
        _showPgSpecsSheet();
        break;
    }
  }

  void _showHouseSpecsSheet() {
    final ha = p.houseAndApartment;
    int typeIdx =
        _indexOf(PropertyController.haTypeOptions, ha?.houseApartmentType);
    int bhkIdx = _indexOf(PropertyController.bhkOptions, ha?.bhk);
    int bathIdx = _indexOf(PropertyController.bathroomOptions, ha?.bathrooms);
    int furnIdx =
        _indexOf(PropertyController.furnishingOptions, ha?.furnishing);
    int availIdx =
        _indexOf(PropertyController.availabilityOptions, ha?.availabilityStatus);
    int listedIdx =
        _indexOf(PropertyController.listedByOptions, ha?.listedBy);
    int bachIdx =
        _indexOf(PropertyController.bachelorOptions, ha?.bachelorsAllowed);
    int parkIdx =
        _indexOf(PropertyController.parkingOptions, ha?.carParking);
    int faceIdx = _indexOf(PropertyController.facingOptions, ha?.facing);

    final areaCtrl = TextEditingController(text: ha?.areaDetails ?? '');
    final maintCtrl = TextEditingController(text: ha?.maintenance ?? '');
    final floorsCtrl = TextEditingController(text: ha?.totalFloors ?? '');

    final isRent = p.listingType == 'Rent';

    _openEditSheet(
      title: AppStrings.editPropertyDetails.tr,
      children: [
        RentalChipSelector(
          label: AppStrings.typeLabel.tr,
          options: PropertyController.haTypeOptions,
          initialIndex: typeIdx,
          onChanged: (i) => typeIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelBHK.tr,
          options: PropertyController.bhkOptions,
          initialIndex: bhkIdx,
          onChanged: (i) => bhkIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelBathrooms.tr,
          options: PropertyController.bathroomOptions,
          initialIndex: bathIdx,
          onChanged: (i) => bathIdx = i,
        ),
        const SizedBox(height: 16),
        if (isRent) ...[
          RentalChipSelector(
            label: AppStrings.filterLabelFurnishing.tr,
            options: PropertyController.furnishingOptions,
            initialIndex: furnIdx,
            onChanged: (i) => furnIdx = i,
          ),
          const SizedBox(height: 16),
          RentalChipSelector(
            label: AppStrings.filterLabelBachelors.tr,
            options: PropertyController.bachelorOptions,
            initialIndex: bachIdx,
            onChanged: (i) => bachIdx = i,
          ),
        ] else ...[
          RentalChipSelector(
            label: AppStrings.filterLabelAvailability.tr,
            options: PropertyController.availabilityOptions,
            initialIndex: availIdx,
            onChanged: (i) => availIdx = i,
          ),
        ],
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelListedBy.tr,
          options: PropertyController.listedByOptions,
          initialIndex: listedIdx,
          onChanged: (i) => listedIdx = i,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.areaDetailsLabel.tr,
          hint: AppStrings.egArea1200SqFt.tr,
          controller: areaCtrl,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.maintenanceMonthlyLabel.tr,
          hint: AppStrings.enterAmount.tr,
          controller: maintCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.totalFloorsLabel.tr,
          hint: AppStrings.enterTotalFloors.tr,
          controller: floorsCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelCarParking.tr,
          options: PropertyController.parkingOptions,
          initialIndex: parkIdx,
          onChanged: (i) => parkIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelFacing.tr,
          options: PropertyController.facingOptions,
          initialIndex: faceIdx,
          onChanged: (i) => faceIdx = i,
        ),
      ],
      onSave: () {
        final model = HouseAndApartment(
          propertyLocation: p.displayLocation,
          houseApartmentType: PropertyController.haTypeOptions[typeIdx],
          bhk: PropertyController.bhkOptions[bhkIdx],
          bathrooms: PropertyController.bathroomOptions[bathIdx],
          listedBy: PropertyController.listedByOptions[listedIdx],
          areaDetails: areaCtrl.text.trim().isNotEmpty
              ? areaCtrl.text.trim()
              : null,
          maintenance: maintCtrl.text.trim().isNotEmpty
              ? maintCtrl.text.trim()
              : null,
          totalFloors: floorsCtrl.text.trim().isNotEmpty
              ? floorsCtrl.text.trim()
              : null,
          carParking: PropertyController.parkingOptions[parkIdx],
          facing: PropertyController.facingOptions[faceIdx],
          availabilityStatus: !isRent
              ? PropertyController.availabilityOptions[availIdx]
              : null,
          furnishing: isRent
              ? PropertyController.furnishingOptions[furnIdx]
              : null,
          bachelorsAllowed: isRent
              ? PropertyController.bachelorOptions[bachIdx]
              : null,
        );
        _updateFields({'houseAndApartment': model.toJson()});
      },
    );
  }

  void _showLandSpecsSheet() {
    final lp = p.landAndPlots;
    int projIdx =
        _indexOf(PropertyController.lpProjectTypeOptions, lp?.projectType);
    int listedIdx =
        _indexOf(PropertyController.listedByOptions, lp?.listedBy);
    int faceIdx = _indexOf(PropertyController.facingOptions, lp?.facing);

    final areaCtrl =
        TextEditingController(text: lp?.plotAreaDetails?.totalArea ?? '');
    final lenCtrl =
        TextEditingController(text: lp?.plotAreaDetails?.length ?? '');
    final brCtrl =
        TextEditingController(text: lp?.plotAreaDetails?.breadth ?? '');

    _openEditSheet(
      title: AppStrings.editLandDetails.tr,
      children: [
        RentalChipSelector(
          label: AppStrings.projectTypeLabel.tr,
          options: PropertyController.lpProjectTypeOptions,
          initialIndex: projIdx,
          onChanged: (i) => projIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelListedBy.tr,
          options: PropertyController.listedByOptions,
          initialIndex: listedIdx,
          onChanged: (i) => listedIdx = i,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.plotAreaLabel.tr,
          hint: AppStrings.totalAreaHint.tr,
          controller: areaCtrl,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.lengthLabel.tr,
          hint: AppStrings.enterLength.tr,
          controller: lenCtrl,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.breadthLabel.tr,
          hint: AppStrings.enterBreadth.tr,
          controller: brCtrl,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelFacing.tr,
          options: PropertyController.facingOptions,
          initialIndex: faceIdx,
          onChanged: (i) => faceIdx = i,
        ),
      ],
      onSave: () {
        final model = LandAndPlots(
          propertyLocation: p.displayLocation,
          projectType: PropertyController.lpProjectTypeOptions[projIdx],
          listedBy: PropertyController.listedByOptions[listedIdx],
          plotAreaDetails: PlotAreaDetails(
            totalArea: areaCtrl.text.trim(),
            length: lenCtrl.text.trim(),
            breadth: brCtrl.text.trim(),
          ),
          facing: PropertyController.facingOptions[faceIdx],
        );
        _updateFields({'landAndPlots': model.toJson()});
      },
    );
  }

  void _showShopSpecsSheet() {
    final so = p.shopAndOffices;
    int furnIdx =
        _indexOf(PropertyController.furnishingOptions, so?.furnishing);
    int statusIdx = _indexOf(
        PropertyController.soProjectStatusOptions, so?.projectStatus);
    int listedIdx =
        _indexOf(PropertyController.listedByOptions, so?.listedBy);
    int parkIdx =
        _indexOf(PropertyController.parkingOptions, so?.carParkings);
    int washIdx =
        _indexOf(PropertyController.washroomOptions, so?.washrooms);

    final areaCtrl =
        TextEditingController(text: so?.superBuiltupArea ?? '');
    final maintCtrl = TextEditingController(text: so?.maintenance ?? '');

    _openEditSheet(
      title: AppStrings.editShopDetails.tr,
      children: [
        RentalChipSelector(
          label: AppStrings.filterLabelFurnishing.tr,
          options: PropertyController.furnishingOptions,
          initialIndex: furnIdx,
          onChanged: (i) => furnIdx = i,
        ),
        if (p.listingType == 'Sell') ...[
          const SizedBox(height: 16),
          RentalChipSelector(
            label: AppStrings.filterLabelProjectStatus.tr,
            options: PropertyController.soProjectStatusOptions,
            initialIndex: statusIdx,
            onChanged: (i) => statusIdx = i,
          ),
        ],
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelListedBy.tr,
          options: PropertyController.listedByOptions,
          initialIndex: listedIdx,
          onChanged: (i) => listedIdx = i,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.superBuiltUpArea.tr,
          hint: AppStrings.enterAreaHint.tr,
          controller: areaCtrl,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.maintenanceMonthlyLabel.tr,
          hint: AppStrings.enterAmount.tr,
          controller: maintCtrl,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelCarParking.tr,
          options: PropertyController.parkingOptions,
          initialIndex: parkIdx,
          onChanged: (i) => parkIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelWashrooms.tr,
          options: PropertyController.washroomOptions,
          initialIndex: washIdx,
          onChanged: (i) => washIdx = i,
        ),
      ],
      onSave: () {
        final model = ShopAndOffices(
          propertyLocation: p.displayLocation,
          furnishing: PropertyController.furnishingOptions[furnIdx],
          listedBy: PropertyController.listedByOptions[listedIdx],
          superBuiltupArea: areaCtrl.text.trim(),
          carParkings: PropertyController.parkingOptions[parkIdx],
          washrooms: PropertyController.washroomOptions[washIdx],
          projectStatus: p.listingType == 'Sell'
              ? PropertyController.soProjectStatusOptions[statusIdx]
              : null,
          maintenance: maintCtrl.text.trim().isNotEmpty
              ? maintCtrl.text.trim()
              : null,
        );
        _updateFields({'shopAndOffices': model.toJson()});
      },
    );
  }

  void _showNewProjectSpecsSheet() {
    final np = p.newProjectsAndProperties;
    int projIdx =
        _indexOf(PropertyController.propertyKindOptions, np?.projectType);
    int statusIdx = _indexOf(
        PropertyController.availabilityOptions, np?.projectStatus);
    int typeIdx = _indexOf(
        PropertyController.npPropertyTypeOptions, np?.typeOfProperty);
    int towerIdx =
        _indexOf(PropertyController.towersOptions, np?.noOfTowers);
    int floorIdx =
        _indexOf(PropertyController.floorsOptions, np?.noOfFloors);
    int faceIdx = _indexOf(PropertyController.facingOptions, np?.facing);

    final areaCtrl = TextEditingController(text: np?.area ?? '');
    final builderCtrl = TextEditingController(
        text: np?.projectLaunchInformation?.builderName ?? '');
    final reraCtrl = TextEditingController(
        text: np?.projectLaunchInformation?.reraRegistrationNumber ?? '');
    final amenCtrl = TextEditingController(
        text: np?.keyAmenities?.join(', ') ?? '');

    _openEditSheet(
      title: AppStrings.editProjectDetails.tr,
      children: [
        RentalChipSelector(
          label: AppStrings.projectTypeLabel.tr,
          options: PropertyController.propertyKindOptions,
          initialIndex: projIdx,
          onChanged: (i) => projIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelProjectStatus.tr,
          options: PropertyController.availabilityOptions,
          initialIndex: statusIdx,
          onChanged: (i) => statusIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelPropertyType.tr,
          options: PropertyController.npPropertyTypeOptions,
          initialIndex: typeIdx,
          onChanged: (i) => typeIdx = i,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.areaLabel.tr,
          hint: AppStrings.enterAreaHint.tr,
          controller: areaCtrl,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.builderNameLabel.tr,
          hint: AppStrings.enterBuilderName.tr,
          controller: builderCtrl,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.reraRegistrationNo.tr,
          hint: AppStrings.enterReraNumber.tr,
          controller: reraCtrl,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.noOfTowersLabel.tr,
          options: PropertyController.towersOptions,
          initialIndex: towerIdx,
          onChanged: (i) => towerIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.noOfFloorsLabel.tr,
          options: PropertyController.floorsOptions,
          initialIndex: floorIdx,
          onChanged: (i) => floorIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelFacing.tr,
          options: PropertyController.facingOptions,
          initialIndex: faceIdx,
          onChanged: (i) => faceIdx = i,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.keyAmenitiesLabel.tr,
          hint: AppStrings.egSwimmingPoolGymPark.tr,
          controller: amenCtrl,
        ),
      ],
      onSave: () {
        final model = NewProjectsAndProperties(
          propertyLocation: p.displayLocation,
          projectType: PropertyController.propertyKindOptions[projIdx],
          projectStatus: PropertyController.availabilityOptions[statusIdx],
          typeOfProperty:
              PropertyController.npPropertyTypeOptions[typeIdx],
          area: areaCtrl.text.trim(),
          projectLaunchInformation: ProjectLaunchInfo(
            builderName: builderCtrl.text.trim().isNotEmpty
                ? builderCtrl.text.trim()
                : null,
            reraRegistrationNumber: reraCtrl.text.trim().isNotEmpty
                ? reraCtrl.text.trim()
                : null,
          ),
          noOfTowers: PropertyController.towersOptions[towerIdx],
          noOfFloors: PropertyController.floorsOptions[floorIdx],
          facing: PropertyController.facingOptions[faceIdx],
          keyAmenities: amenCtrl.text.trim().isNotEmpty
              ? amenCtrl.text
                  .trim()
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
              : null,
        );
        _updateFields(
            {'newProjectsAndProperties': model.toJson()});
      },
    );
  }

  void _showPgSpecsSheet() {
    final pg = p.pgAndGuestHouse;
    int subIdx =
        _indexOf(PropertyController.pgSubtypeOptions, pg?.subType);
    int roomIdx =
        _indexOf(PropertyController.pgRoomTypeOptions, pg?.roomType);
    int bathIdx = _indexOf(
        PropertyController.attachedBathroomOptions, pg?.attachedBathroom);
    int furnIdx =
        _indexOf(PropertyController.furnishingOptions, pg?.furnishing);
    int listedIdx =
        _indexOf(PropertyController.listedByOptions, pg?.listedBy);
    int parkIdx =
        _indexOf(PropertyController.parkingOptions, pg?.carParking);
    int mealIdx =
        _indexOf(PropertyController.mealsOptions, pg?.mealsIncluded);

    final amenCtrl = TextEditingController(
        text: pg?.keyAmenities?.join(', ') ?? '');

    _openEditSheet(
      title: AppStrings.editPgDetails.tr,
      children: [
        RentalChipSelector(
          label: AppStrings.subtypeLabel.tr,
          options: PropertyController.pgSubtypeOptions,
          initialIndex: subIdx,
          onChanged: (i) => subIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelRoomType.tr,
          options: PropertyController.pgRoomTypeOptions,
          initialIndex: roomIdx,
          onChanged: (i) => roomIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelAttachedBathroom.tr,
          options: PropertyController.attachedBathroomOptions,
          initialIndex: bathIdx,
          onChanged: (i) => bathIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelFurnishing.tr,
          options: PropertyController.furnishingOptions,
          initialIndex: furnIdx,
          onChanged: (i) => furnIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelListedBy.tr,
          options: PropertyController.listedByOptions,
          initialIndex: listedIdx,
          onChanged: (i) => listedIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.filterLabelCarParking.tr,
          options: PropertyController.parkingOptions,
          initialIndex: parkIdx,
          onChanged: (i) => parkIdx = i,
        ),
        const SizedBox(height: 16),
        RentalChipSelector(
          label: AppStrings.mealsIncludedLabel.tr,
          options: PropertyController.mealsOptions,
          initialIndex: mealIdx,
          onChanged: (i) => mealIdx = i,
        ),
        const SizedBox(height: 16),
        RentalLabeledField(
          label: AppStrings.keyAmenitiesLabel.tr,
          hint: AppStrings.egWifiLaundryAc.tr,
          controller: amenCtrl,
        ),
      ],
      onSave: () {
        final model = PGAndGuestHouse(
          propertyLocation: p.displayLocation,
          subType: PropertyController.pgSubtypeOptions[subIdx],
          roomType: PropertyController.pgRoomTypeOptions[roomIdx],
          attachedBathroom:
              PropertyController.attachedBathroomOptions[bathIdx],
          furnishing: PropertyController.furnishingOptions[furnIdx],
          listedBy: PropertyController.listedByOptions[listedIdx],
          carParking: PropertyController.parkingOptions[parkIdx],
          mealsIncluded: PropertyController.mealsOptions[mealIdx],
          keyAmenities: amenCtrl.text.trim().isNotEmpty
              ? amenCtrl.text
                  .trim()
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
              : null,
        );
        _updateFields({'pgAndGuestHouse': model.toJson()});
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // UPDATE API
  // ═══════════════════════════════════════════════════════════

  Future<void> _updateFields(Map<String, dynamic> updates) async {
    if (p.id == null) {
      commonSnackBar(message: AppStrings.cannotUpdatePropertyIdMissing.tr);
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final repo = PropertyRepo();
      final response = await repo.updateProperty(p.id!, updates);

      if (response.isSuccess) {
        final fetchResponse = await repo.getPropertyById(p.id!);
        Get.back(); // close loading
        if (fetchResponse.isSuccess && fetchResponse.data != null) {
          setState(() {
            _property = PropertyModel.fromJson(
              fetchResponse.data is Map<String, dynamic>
                  ? fetchResponse.data
                  : fetchResponse.data as Map<String, dynamic>,
            );
          });
        }
        Get.back(); // close bottom sheet
        commonSnackBar(message: AppStrings.updatedSuccessfully.tr);
      } else {
        Get.back(); // close loading
        commonSnackBar(
            message: response.message ?? AppStrings.updateFailed.tr);
      }
    } catch (e) {
      Get.back(); // close loading
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    }
  }

  Future<void> _uploadImages(List<String> localPaths) async {
    if (p.id == null || localPaths.isEmpty) return;

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final body = <String, dynamic>{};
      final images = <dio.MultipartFile>[];
      for (final path in localPaths) {
        images.add(await dio.MultipartFile.fromFile(path));
      }
      body['propertyImages'] = images;

      final repo = PropertyRepo();
      final response =
          await repo.updateProperty(p.id!, body, isMultipart: true);

      if (response.isSuccess) {
        final fetchResponse = await repo.getPropertyById(p.id!);
        Get.back(); // close loading
        if (fetchResponse.isSuccess && fetchResponse.data != null) {
          setState(() {
            _property = PropertyModel.fromJson(
              fetchResponse.data as Map<String, dynamic>,
            );
          });
        }
        Get.back(); // close bottom sheet
        commonSnackBar(message: AppStrings.photosUploadedSuccessfully.tr);
      } else {
        Get.back(); // close loading
        commonSnackBar(
            message: response.message ?? AppStrings.uploadFailed.tr);
      }
    } catch (e) {
      Get.back(); // close loading
      commonSnackBar(message: AppStrings.somethingWentWrong.tr);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // DATA EXTRACTORS
  // ═══════════════════════════════════════════════════════════

  List<(IconData, String)> _extractHighlights() {
    final result = <(IconData, String)>[];
    final ha = p.houseAndApartment;
    final lp = p.landAndPlots;
    final so = p.shopAndOffices;
    final np = p.newProjectsAndProperties;
    final pg = p.pgAndGuestHouse;

    if (ha != null) {
      if (ha.areaDetails != null && ha.areaDetails!.isNotEmpty) {
        result.add((Icons.square_foot, ha.areaDetails!));
      }
      if (ha.bathrooms != null) {
        result.add((
          Icons.bathtub_outlined,
          AppStrings.chipBathroomsFmt.trParams({'value': ha.bathrooms!}),
        ));
      }
      if (ha.totalFloors != null) {
        result.add((
          Icons.layers_outlined,
          AppStrings.chipFloorsFmt.trParams({'value': ha.totalFloors!}),
        ));
      }
      if (ha.bhk != null) {
        result.add((
          Icons.bed_outlined,
          AppStrings.chipBhkFmt.trParams({'value': ha.bhk!}),
        ));
      }
    } else if (lp != null) {
      final plot = lp.plotAreaDetails;
      if (plot?.totalArea != null) {
        result.add((Icons.square_foot, plot!.totalArea!));
      }
      if (plot?.length != null) {
        result.add((
          Icons.straighten,
          AppStrings.chipLengthFmt.trParams({'value': plot!.length!}),
        ));
      }
      if (plot?.breadth != null) {
        result.add((
          Icons.straighten,
          AppStrings.chipBreadthFmt.trParams({'value': plot!.breadth!}),
        ));
      }
    } else if (so != null) {
      if (so.superBuiltupArea != null) {
        result.add((Icons.square_foot, so.superBuiltupArea!));
      }
      if (so.washrooms != null) {
        result.add((
          Icons.bathtub_outlined,
          AppStrings.chipWashroomPluralFmt
              .trParams({'value': so.washrooms!}),
        ));
      }
      if (so.carParkings != null) {
        result.add((
          Icons.local_parking,
          AppStrings.chipParkingFmt.trParams({'value': so.carParkings!}),
        ));
      }
    } else if (np != null) {
      if (np.area != null) {
        result.add((Icons.square_foot, np.area!));
      }
      if (np.noOfTowers != null) {
        result.add((
          Icons.apartment_outlined,
          AppStrings.chipTowersFmt.trParams({'value': np.noOfTowers!}),
        ));
      }
      if (np.noOfFloors != null) {
        result.add((
          Icons.layers_outlined,
          AppStrings.chipFloorsFmt.trParams({'value': np.noOfFloors!}),
        ));
      }
    } else if (pg != null) {
      if (pg.roomType != null) {
        result.add((Icons.meeting_room_outlined, pg.roomType!));
      }
      if (pg.furnishing != null) {
        result.add((Icons.chair_outlined, pg.furnishing!));
      }
    }
    return result;
  }

  List<(String, String)> _extractPropertyInfo() {
    final result = <(String, String)>[];
    final ha = p.houseAndApartment;
    final lp = p.landAndPlots;
    final so = p.shopAndOffices;
    final np = p.newProjectsAndProperties;
    final pg = p.pgAndGuestHouse;

    if (ha != null) {
      _add(result, AppStrings.typeLabel.tr, ha.houseApartmentType);
      _add(result, AppStrings.filterLabelBHK.tr, ha.bhk);
      _add(result, AppStrings.filterLabelBathrooms.tr, ha.bathrooms);
      _add(result, AppStrings.filterLabelAvailability.tr,
          ha.availabilityStatus);
      _add(result, AppStrings.filterLabelFurnishing.tr, ha.furnishing);
      _add(result, AppStrings.filterLabelListedBy.tr, ha.listedBy);
      _add(result, AppStrings.filterLabelBachelors.tr, ha.bachelorsAllowed);
      _add(result, AppStrings.areaDetailsLabel.tr, ha.areaDetails);
      _add(result, AppStrings.maintenanceMonthlyLabel.tr, ha.maintenance);
      _add(result, AppStrings.totalFloorsLabel.tr, ha.totalFloors);
      _add(result, AppStrings.filterLabelCarParking.tr, ha.carParking);
      _add(result, AppStrings.filterLabelFacing.tr, ha.facing);
    } else if (lp != null) {
      _add(result, AppStrings.projectTypeLabel.tr, lp.projectType);
      _add(result, AppStrings.filterLabelListedBy.tr, lp.listedBy);
      final plot = lp.plotAreaDetails;
      if (plot != null) {
        _add(result, AppStrings.plotAreaLabel.tr, plot.totalArea);
        _add(result, AppStrings.lengthLabel.tr, plot.length);
        _add(result, AppStrings.breadthLabel.tr, plot.breadth);
      }
      _add(result, AppStrings.filterLabelFacing.tr, lp.facing);
    } else if (so != null) {
      _add(result, AppStrings.filterLabelFurnishing.tr, so.furnishing);
      _add(result, AppStrings.filterLabelProjectStatus.tr, so.projectStatus);
      _add(result, AppStrings.filterLabelListedBy.tr, so.listedBy);
      _add(result, AppStrings.superBuiltUpArea.tr, so.superBuiltupArea);
      _add(result, AppStrings.maintenanceMonthlyLabel.tr, so.maintenance);
      _add(result, AppStrings.filterLabelCarParking.tr, so.carParkings);
      _add(result, AppStrings.filterLabelWashrooms.tr, so.washrooms);
    } else if (np != null) {
      _add(result, AppStrings.projectTypeLabel.tr, np.projectType);
      _add(result, AppStrings.filterLabelProjectStatus.tr, np.projectStatus);
      _add(result, AppStrings.filterLabelPropertyType.tr, np.typeOfProperty);
      _add(result, AppStrings.areaLabel.tr, np.area);
      final launch = np.projectLaunchInformation;
      if (launch != null) {
        _add(result, AppStrings.builderNameLabel.tr, launch.builderName);
        _add(result, AppStrings.reraNoLabel.tr,
            launch.reraRegistrationNumber);
      }
      _add(result, AppStrings.noOfTowersLabel.tr, np.noOfTowers);
      _add(result, AppStrings.noOfFloorsLabel.tr, np.noOfFloors);
      _add(result, AppStrings.filterLabelFacing.tr, np.facing);
      _addAmenities(result, np.keyAmenities);
    } else if (pg != null) {
      _add(result, AppStrings.subtypeLabel.tr, pg.subType);
      _add(result, AppStrings.filterLabelRoomType.tr, pg.roomType);
      _add(result, AppStrings.filterLabelAttachedBathroom.tr,
          pg.attachedBathroom);
      _add(result, AppStrings.filterLabelFurnishing.tr, pg.furnishing);
      _add(result, AppStrings.filterLabelListedBy.tr, pg.listedBy);
      _add(result, AppStrings.filterLabelCarParking.tr, pg.carParking);
      _add(result, AppStrings.mealsIncludedLabel.tr, pg.mealsIncluded);
      _addAmenities(result, pg.keyAmenities);
    }
    return result;
  }

  void _add(List<(String, String)> list, String label, String? value) {
    if (value != null && value.isNotEmpty) {
      list.add((label, value));
    }
  }

  void _addAmenities(List<(String, String)> list, List<String>? amenities) {
    if (amenities != null && amenities.isNotEmpty) {
      list.add((AppStrings.keyAmenitiesLabel.tr, amenities.join(', ')));
    }
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════

  int _indexOf(List<String> options, String? value) {
    if (value == null) return 0;
    final idx = options.indexOf(value);
    return idx >= 0 ? idx : 0;
  }

  /// Lister role pulled from whichever type-specific sub-model is
  /// present. New Projects carries no `listedBy`, so it yields null.
  String? get _listedBy =>
      p.houseAndApartment?.listedBy ??
      p.landAndPlots?.listedBy ??
      p.shopAndOffices?.listedBy ??
      p.pgAndGuestHouse?.listedBy;

  /// True when the current sub-model has a `listedBy` role field.
  bool get _subTypeHasListedBy =>
      p.houseAndApartment != null ||
      p.landAndPlots != null ||
      p.shopAndOffices != null ||
      p.pgAndGuestHouse != null;

  /// JSON of the current type-specific sub-model, used to re-send the
  /// full object when only one field (e.g. `listedBy`) changes.
  Map<String, dynamic>? _currentSubTypeJson() {
    if (p.houseAndApartment != null) return p.houseAndApartment!.toJson();
    if (p.landAndPlots != null) return p.landAndPlots!.toJson();
    if (p.shopAndOffices != null) return p.shopAndOffices!.toJson();
    if (p.newProjectsAndProperties != null) {
      return p.newProjectsAndProperties!.toJson();
    }
    if (p.pgAndGuestHouse != null) return p.pgAndGuestHouse!.toJson();
    return null;
  }

  String? _subTypeKey() {
    switch (p.propertyType) {
      case 'HouseAndApartment':
        return 'houseAndApartment';
      case 'LandAndPlots':
        return 'landAndPlots';
      case 'ShopAndOffices':
        return 'shopAndOffices';
      case 'NewProjectsAndProperties':
        return 'newProjectsAndProperties';
      case 'PGAndGuestHouse':
        return 'pgAndGuestHouse';
    }
    return null;
  }
}
