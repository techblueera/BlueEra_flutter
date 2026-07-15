import 'dart:io';
import 'dart:ui';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const int _maxPhotos = 4;

// Slot labels resolve via `.tr` at sheet-build time, so keep this as a
// function rather than a top-level const list — runtime values can't be
// embedded in a `const`.
List<Map<String, String>> _buildSlotConfigs() => [
      {'label': AppStrings.slotStorefrontExterior.tr, 'image': AppImageAssets.storefrontExterior},
      {'label': AppStrings.slotInteriorInsideShop.tr, 'image': AppImageAssets.interiorInsideShop},
      {'label': AppStrings.slotBillingCounterReception.tr, 'image': AppImageAssets.billingCounterReceptionArea},
      {'label': AppStrings.slotProductsServicesDisplay.tr, 'image': AppImageAssets.productServiceDisplay},
    ];

void showBusinessLivePhotoBottomSheetIfNeeded({
  required BuildContext context,
  required ViewBusinessDetailsController controller,
}) {
  void evaluate() {
    if (!context.mounted) return;
    final livePhotos = controller.businessProfileDetails.value?.data?.livePhotos;
    final hasAnyPhoto = livePhotos != null && livePhotos.any((p) => p.trim().isNotEmpty);
    // Skip if any photo exists, OR if a sheet is already on screen
    // (the four admin screens all call this in postFrame, so a re-mount
    // shouldn't stack a second sheet on top of the open one).
    if (hasAnyPhoto || ModalRoute.of(context)?.isCurrent == false) return;
    _showLivePhotoBottomSheet(context: context, controller: controller);
  }

  // Profile already in memory — decide immediately.
  if (controller.businessProfileDetails.value != null) {
    evaluate();
    return;
  }

  // Profile still loading. The four admin screens call this from
  // postFrame in initState, before the permanent controller has
  // finished its first fetch. Treating null as "zero photos" would pop
  // the sheet for users who already have photos on the server — so wait
  // for the first non-null snapshot, then evaluate once.
  late final Worker worker;
  worker = ever(controller.businessProfileDetails, (val) {
    if (val != null) {
      worker.dispose();
      evaluate();
    }
  });
}

void _showLivePhotoBottomSheet({
  required BuildContext context,
  required ViewBusinessDetailsController controller,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _LivePhotoBottomSheetContent(controller: controller),
  );
}

class _LivePhotoBottomSheetContent extends StatelessWidget {
  final ViewBusinessDetailsController controller;

  const _LivePhotoBottomSheetContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(AppStrings.businessLivePhotos.tr,
                        fontSize: 18, fontWeight: FontWeight.bold),
                    const SizedBox(height: 4),
                    CustomText(
                      AppStrings.addPhotosToHelpCustomers.tr,
                      fontSize: 12, color: AppColors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    AppStrings.atLeastOneLivePhotoRequired.tr,
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            // Subscribe to both sources of truth — getLivePhotoAt reads
            // both, but touching them here ensures Obx rebuilds even
            // when GridView itemBuilder is lazy.
            controller.businessProfileDetails.value;
            controller.localUploadingPhotos.length;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _maxPhotos,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 10,
                mainAxisSpacing: 10, childAspectRatio: 1.1,
              ),
              itemBuilder: (ctx, index) {
                final config = _buildSlotConfigs()[index];
                final serverPhotos =
                    controller.businessProfileDetails.value?.data?.livePhotos ?? [];
                final serverUrl = (index < serverPhotos.length &&
                        serverPhotos[index].trim().isNotEmpty)
                    ? serverPhotos[index]
                    : null;
                return _LivePhotoSlot(
                  index: index,
                  label: config['label']!,
                  placeholderImage: config['image']!,
                  serverUrl: serverUrl,
                  localPath: controller.localUploadingPhotos[index],
                  controller: controller,
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _LivePhotoSlot extends StatelessWidget {
  final int index;
  final String label;
  final String placeholderImage;
  final String? serverUrl;
  final String? localPath;
  final ViewBusinessDetailsController controller;

  const _LivePhotoSlot({
    required this.index,
    required this.label,
    required this.placeholderImage,
    required this.serverUrl,
    required this.localPath,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final hasServer = serverUrl != null;
    final hasLocal = localPath != null;
    final hasPhoto = hasServer || hasLocal;

    return GestureDetector(
      onTap: hasPhoto ? null : () => _handleUpload(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageLayer(),

            if (!hasPhoto)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: LocalAssets(
                    imagePath: AppIconAssets.profile_camera_pic,
                    height: 20, width: 20,
                    imgColor: AppColors.secondaryTextColor,
                  ),
                ),
              ),

            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: CustomText(
                  label, fontSize: 11, fontWeight: FontWeight.w600,
                  color: Colors.white, textAlign: TextAlign.center,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // Delete is only available once the server has confirmed the
            // photo and we have a URL to send to the delete endpoint.
            if (hasServer)
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: _handleDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLayer() {
    // When the server URL is available, render it via CachedNetworkImage
    // but pass the local file as the placeholder/error fallback when we
    // still have it. This eliminates the grey flash between the local
    // preview and the network image finishing its download — the swap
    // becomes seamless because the placeholder is the same image.
    if (serverUrl != null) {
      final Widget fallback = localPath != null
          ? Image.file(File(localPath!), fit: BoxFit.cover)
          : Container(color: Colors.grey.shade200);
      return CachedNetworkImage(
        imageUrl: serverUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => localPath != null
            ? Image.file(File(localPath!), fit: BoxFit.cover)
            : _buildPlaceholder(),
      );
    }
    if (localPath != null) {
      return Image.file(File(localPath!), fit: BoxFit.cover);
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(placeholderImage, fit: BoxFit.cover),
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              color: AppColors.black.withValues(alpha: 0.35),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleUpload(BuildContext context) async {
    final imgStr = await PhotoPickerService.pickFromCamera(
      context, cropAspectRatio: const CropAspectRatio(width: 3, height: 4),
    );
    if (imgStr == null) return;

    // 1. Show picked photo in the slot immediately.
    controller.localUploadingPhotos[index] = imgStr;

    // 2. If this pick fills the last empty slot, close the sheet — the
    //    upload + refetch continues in the background and any other
    //    Obx widget (e.g. CommonBusinessLivePhoto) will pick up the
    //    new server URL automatically.
    int filledSlots = 0;
    for (int i = 0; i < _maxPhotos; i++) {
      if (controller.getLivePhotoAt(i) != null) filledSlots++;
    }
    final shouldAutoClose = filledSlots >= _maxPhotos;

    // 3. Upload behind the shared "Uploading Photo" loader (same as the inline
    //    profile widget), then close the sheet if this was the last slot.
    //    saveBusinessImages internally calls viewBusinessProfile, so
    //    businessProfileDetails (Rx) refreshes and every Obx rebuilds with the
    //    server URL — which is what the delete endpoint needs.
    await _runUpload(imgStr);

    if (shouldAutoClose && context.mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _runUpload(String imgStr) async {
    AppLoader.show(message: AppStrings.uploadingPhoto.tr);
    try {
      await controller.saveBusinessImages(imgStr, controller);
      // NOTE: do NOT remove localUploadingPhotos[index] here. The slot
      // uses it as the placeholder for CachedNetworkImage during the
      // download window — dropping it now would expose the grey
      // placeholder and cause the flash the user saw. Local entry is
      // cleared on delete (where it becomes obsolete) or rolled back
      // on error below.
      //
      // The first-live-photo → GPS-capture notice is triggered centrally in
      // ViewBusinessDetailsController.uploadLiveStoreImage (the single choke
      // point for every upload), so it also fires from the inline profile
      // widget and re-fires after photos are cleared back to zero.
    } catch (_) {
      controller.localUploadingPhotos.remove(index);
      Get.snackbar(
        AppStrings.uploadFailed.tr,
        AppStrings.couldNotSaveImage.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    } finally {
      AppLoader.hide();
    }
  }

  Future<void> _handleDelete() async {
    AppLoader.show(message: AppStrings.removingPhoto.tr);
    try {
      await controller.deleteLiveStoreImage({'image_url': serverUrl});
    } finally {
      controller.localUploadingPhotos.remove(index);
      AppLoader.hide();
    }
  }
}
