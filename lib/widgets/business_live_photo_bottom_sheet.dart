import 'dart:ui';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

final _slotConfigs = [
  {'label': 'Storefront / Exterior\n(Roadside)', 'image': AppImageAssets.storefrontExterior},
  {'label': 'Interior / Inside\nthe Shop', 'image': AppImageAssets.interiorInsideShop},
  {'label': 'Billing Counter\n/ Reception Area', 'image': AppImageAssets.billingCounterReceptionArea},
  {'label': 'Products / Services\nDisplay', 'image': AppImageAssets.productServiceDisplay},
];

void showBusinessLivePhotoBottomSheetIfNeeded({
  required BuildContext context,
  required ViewBusinessDetailsController controller,
}) {
  final livePhotos = controller.businessProfileDetails.value?.data?.livePhotos;
  final hasPhotos = livePhotos != null && livePhotos.any((p) => p.trim().isNotEmpty);
  if (!hasPhotos) {
    _showLivePhotoBottomSheet(context: context, controller: controller);
  }
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
    builder: (ctx) {
      return _LivePhotoBottomSheetContent(controller: controller);
    },
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
                    const CustomText('Business Live Photos',
                        fontSize: 18, fontWeight: FontWeight.bold),
                    const SizedBox(height: 4),
                    CustomText(
                      'Add photos to help customers find your business',
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
                    'If You Want To Make Your Business Live, You Must Share At Least One Live Photo.',
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GetBuilder<ViewBusinessDetailsController>(
            id: 'livePhotos',
            builder: (_) {
              final photos = controller.businessProfileDetails.value?.data?.livePhotos ?? [];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _slotConfigs.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10,
                  mainAxisSpacing: 10, childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final config = _slotConfigs[index];
                  final hasPhoto = index < photos.length && photos[index].trim().isNotEmpty;
                  final photoUrl = hasPhoto ? photos[index] : null;
                  return _LivePhotoSlot(
                    index: index,
                    label: config['label']!,
                    placeholderImage: config['image']!,
                    photoUrl: photoUrl,
                    controller: controller,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LivePhotoSlot extends StatelessWidget {
  final int index;
  final String label;
  final String placeholderImage;
  final String? photoUrl;
  final ViewBusinessDetailsController controller;

  const _LivePhotoSlot({
    required this.index,
    required this.label,
    required this.placeholderImage,
    required this.photoUrl,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null;

    return GestureDetector(
      onTap: hasPhoto ? null : () => _handleUpload(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade200),
                errorWidget: (_, __, ___) => _buildPlaceholder(),
              )
            else
              _buildPlaceholder(),

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

            if (hasPhoto)
              Positioned(
                top: 6, right: 6,
                child: GestureDetector(
                  onTap: () => _handleDelete(),
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
      context, cropAspectRatio: CropAspectRatio(width: 3, height: 4),
    );
    if (imgStr != null) {
      AppLoader.show(message: 'Uploading photo...');
      await controller.saveBusinessImages(imgStr, controller);
      await controller.viewBusinessProfile();
      controller.update(['livePhotos']);
      AppLoader.hide();
    }
  }

  Future<void> _handleDelete() async {
    AppLoader.show(message: 'Removing photo...');
    await controller.deleteLiveStoreImage({'image_url': photoUrl});
    await controller.viewBusinessProfile();
    controller.update(['livePhotos']);
    AppLoader.hide();
  }
}
