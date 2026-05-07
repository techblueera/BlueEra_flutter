import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// One of the four required vehicle photos. Each slot maps to a
/// pre-existing `RxList<File>` on [DeliveryPartnerController].
///
/// The original screen had separate left + right side sections; the
/// new design merges them into one "Side" slot which writes into
/// [DeliveryPartnerController.vehicleRightSideImages] (the left list
/// is no longer touched by this surface).
enum _VehicleSlot {
  front('Front'),
  back('Back'),
  side('Side'),
  numberPlate('Number Plate');

  const _VehicleSlot(this.label);
  final String label;
}

class VehicleImagesRidingWidget extends StatefulWidget {
  const VehicleImagesRidingWidget({super.key});

  @override
  State<VehicleImagesRidingWidget> createState() =>
      _VehicleImagesRidingWidgetState();
}

class _VehicleImagesRidingWidgetState
    extends State<VehicleImagesRidingWidget> {
  final controller = Get.put(DeliveryPartnerController());

  // ─── slot dispatch ────────────────────────────────────────────────
  RxList<File> _imagesFor(_VehicleSlot slot) {
    switch (slot) {
      case _VehicleSlot.front:
        return controller.vehicleFrontImages;
      case _VehicleSlot.back:
        return controller.vehicleBackImages;
      case _VehicleSlot.side:
        return controller.vehicleRightSideImages;
      case _VehicleSlot.numberPlate:
        return controller.vehicleNumberPlateImages;
    }
  }

  // Pick exactly ONE photo via the single-image helper
  // ([CommonImageUploadTile.pickImage] → SelectProfilePictureDialog),
  // then write it as the only entry in the slot's RxList. Mutating
  // the RxList notifies the wrapping Obx, no GetBuilder ids needed.
  Future<void> _onAdd(_VehicleSlot slot) async {
    final selected = await CommonImageUploadTile.pickImage(
      context: context,
      title: slot.label,
    );
    if (selected == null || selected.isEmpty) return;
    final imageList = _imagesFor(slot);
    imageList
      ..clear()
      ..add(File(selected));
  }

  void _onRemove(_VehicleSlot slot) {
    _imagesFor(slot).clear();
  }

  // ─── BUILD ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SingleChildScrollView(
          // A single Obx covers loading-state absorption AND tile
          // reactivity — every list we read inside the closure is an
          // RxList<File>, so add/remove triggers a clean rebuild.
          child: Obx(() {
            final filledCount = _VehicleSlot.values
                .where((s) => _imagesFor(s).isNotEmpty)
                .length;
            return AbsorbPointer(
              absorbing:
                  controller.isRiderVehicleImagesLoading.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntro(filledCount),
                  SizedBox(height: SizeConfig.size16),
                  _buildGrid(),
                  SizedBox(height: SizeConfig.size20),
                  CustomBtn(
                    title: controller
                            .isRiderVehicleImagesLoading.value
                        ? null
                        : AppStrings.nextButton,
                    onTap: () => controller
                        .ridersOnboardingVehicleImagesApi(),
                    radius: 12.0,
                    bgColor: AppColors.primaryColor,
                    isLoading:
                        controller.isRiderVehicleImagesLoading.value,
                  ),
                  SizedBox(height: SizeConfig.size12),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── INTRO ROW ─────────────────────────────────────────────────────
  // Eyebrow rule + headline on the left; animated count chip on the
  // right that flips from primary-outline to primary-filled when the
  // grid hits 4 / 4.
  Widget _buildIntro(int filledCount) {
    final allDone = filledCount == 4;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 1.4,
                    color: AppColors.primaryColor.withValues(alpha: 0.55),
                  ),
                  const SizedBox(width: 8),
                  CustomText(
                    'VEHICLE PHOTOS',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryColor,
                    letterSpacing: 1.4,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              CustomText(
                'Capture the four required angles',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                letterSpacing: -0.2,
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: filledCount.toDouble()),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) {
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: allDone
                    ? AppColors.primaryColor
                    : AppColors.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryColor
                      .withValues(alpha: allDone ? 1 : 0.25),
                  width: 0.8,
                ),
                boxShadow: allDone
                    ? [
                        BoxShadow(
                          color: AppColors.primaryColor
                              .withValues(alpha: 0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (allDone) ...[
                    const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                  ],
                  CustomText(
                    '${v.toInt()} / 4',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w800,
                    color: allDone
                        ? Colors.white
                        : AppColors.primaryColor,
                    letterSpacing: 0.4,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── 2 × 2 GRID ────────────────────────────────────────────────────
  Widget _buildGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSlotTile(_VehicleSlot.front)),
            const SizedBox(width: 12),
            Expanded(child: _buildSlotTile(_VehicleSlot.back)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSlotTile(_VehicleSlot.side)),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSlotTile(_VehicleSlot.numberPlate),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlotTile(_VehicleSlot slot) {
    final images = _imagesFor(slot);
    final hasImage = images.isNotEmpty;
    return AspectRatio(
      aspectRatio: 1,
      child: hasImage
          ? _buildFilledTile(slot, images.first)
          : _buildEmptyTile(slot),
    );
  }

  // Empty slot — viewfinder reticle. Dashed primary border, soft
  // primary-tinted fill, centered camera glyph + slot label + hint.
  Widget _buildEmptyTile(_VehicleSlot slot) {
    return GestureDetector(
      onTap: () => _onAdd(slot),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: AppColors.primaryColor.withValues(alpha: 0.45),
                  radius: 16,
                  strokeWidth: 1.4,
                  dashLength: 6,
                  gapLength: 5,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor
                          .withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      size: 20,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomText(
                    slot.label,
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainTextColor,
                    letterSpacing: 0.4,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    'Tap to upload',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryTextColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filled slot — thumbnail with dark bottom gradient holding the
  // label, top-right primary check chip, soft primary glow shadow.
  // Tap opens the polished view dialog.
  Widget _buildFilledTile(_VehicleSlot slot, File file) {
    return GestureDetector(
      onTap: () => _showPhotoViewDialog(slot, file),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF5F7FA),
                    child: Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: AppColors.secondaryTextColor,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom dark gradient + label + zoom hint
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.fromLTRB(10, 18, 10, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: CustomText(
                          slot.label,
                          fontSize: SizeConfig.small,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              // Top-right primary-color check chip
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor
                            .withValues(alpha: 0.40),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── VIEW DIALOG ───────────────────────────────────────────────────
  // Header with uppercase title + close pill, body with
  // pinch-zoom-able image (InteractiveViewer + Image.file), and two
  // actions: Replace (re-pick → addImages) and Remove (clear slot).
  void _showPhotoViewDialog(_VehicleSlot slot, File file) {
    final maxImageHeight = MediaQuery.of(context).size.height * 0.55;
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.10),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
              const BoxShadow(
                color: Color(0x14001120),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogHeader(slot.label.toUpperCase()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(maxHeight: maxImageHeight),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.file(
                          file,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            height: 200,
                            color: const Color(0xFFF5F7FA),
                            child: Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                size: 44,
                                color:
                                    AppColors.secondaryTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.zoom_in_rounded,
                        size: 14,
                        color: AppColors.secondaryTextColor,
                      ),
                      const SizedBox(width: 4),
                      CustomText(
                        'Pinch to zoom',
                        fontSize: SizeConfig.small,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDialogReplaceBtn(slot),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDialogRemoveBtn(slot),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierColor: Colors.black.withValues(alpha: 0.55),
    );
  }

  Widget _buildDialogHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomText(
              title,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
              letterSpacing: 0.6,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      AppColors.primaryColor.withValues(alpha: 0.22),
                  width: 0.6,
                ),
              ),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogReplaceBtn(_VehicleSlot slot) {
    return InkWell(
      onTap: () {
        Get.back();
        _onAdd(slot);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh_rounded,
              size: 16,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 6),
            CustomText(
              'Replace',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogRemoveBtn(_VehicleSlot slot) {
    return InkWell(
      onTap: () {
        Get.back();
        _onRemove(slot);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            CustomText(
              'Remove',
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DASHED BORDER PAINTER ───────────────────────────────────────────
// Renders a dashed outline that follows the rounded-rectangle path of
// the empty photo slot — the "viewfinder reticle" cue. Avoids the
// solid-frame look so the empty state reads as a placeholder, not a
// failed render.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final next =
            (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(
          metric.extractPath(distance, next),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}
