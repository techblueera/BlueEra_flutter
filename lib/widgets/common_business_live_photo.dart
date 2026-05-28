import 'dart:io';
import 'dart:ui';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/widgets/app_loader.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommonBusinessLivePhoto extends StatefulWidget {
  final ViewBusinessDetailsController controller;

  const CommonBusinessLivePhoto({
    super.key,
    required this.controller,
  });

  @override
  State<CommonBusinessLivePhoto> createState() =>
      _CommonBusinessLivePhotoState();
}

class _CommonBusinessLivePhotoState extends State<CommonBusinessLivePhoto> {
  static const int _maxPhotos = 4;

  static final List<Map<String, String>> _slotConfig = [
    {'label': 'Storefront / Exterior\n(Roadside)', 'image': AppImageAssets.storefrontExterior},
    {'label': 'Interior / Inside\nthe Shop', 'image': AppImageAssets.interiorInsideShop},
    {'label': 'Billing Counter\n/ Reception Area', 'image': AppImageAssets.billingCounterReceptionArea},
    {'label': 'Products / Services\nDisplay', 'image': AppImageAssets.productServiceDisplay},
  ];

  @override
  Widget build(BuildContext context) {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size10),
      margin: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText(
            'Business Live Photos',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 10),
          Obx(() {
            // Subscribe to both Rx sources read by getLivePhotoAt so this
            // grid stays in sync with uploads done elsewhere (e.g. the
            // BusinessLivePhotoBottomSheet).
            widget.controller.businessProfileDetails.value;
            widget.controller.localUploadingPhotos.length;

            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: _maxPhotos,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (ctx, index) {
                  final serverPhotos = widget.controller.businessProfileDetails
                          .value?.data?.livePhotos ??
                      [];
                  final serverUrl = (index < serverPhotos.length &&
                          serverPhotos[index].trim().isNotEmpty)
                      ? serverPhotos[index]
                      : null;
                  final localPath =
                      widget.controller.localUploadingPhotos[index];
                  final config = _slotConfig[index];

                  return _buildPhotoSlot(
                    context: ctx,
                    index: index,
                    serverUrl: serverUrl,
                    localPath: localPath,
                    label: config['label']!,
                    placeholderImage: config['image']!,
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot({
    required BuildContext context,
    required int index,
    required String? serverUrl,
    required String? localPath,
    required String label,
    required String placeholderImage,
  }) {
    final bool hasServer = serverUrl != null;
    final bool hasLocal = localPath != null;
    final bool hasPhoto = hasServer || hasLocal;
    final String? displayUrl = serverUrl ?? localPath;

    return GestureDetector(
      onTap: () async {
        if (hasPhoto) {
          final List<String> viewingUrls = [];
          for (int i = 0; i < _maxPhotos; i++) {
            final img = widget.controller.getLivePhotoAt(i);
            if (img != null) viewingUrls.add(img);
          }

          navigatePushTo(
            context,
            ImageViewScreen(
              appBarTitle: AppStrings.imageViewer,
              subTitle: '',
              imageUrls: viewingUrls,
              initialIndex:
                  displayUrl == null ? 0 : viewingUrls.indexOf(displayUrl),
            ),
          );
        } else {
          final imgStr = await PhotoPickerService.pickFromCamera(
            context,
            cropAspectRatio: const CropAspectRatio(width: 3, height: 4),
          );
          if (imgStr != null) {
            // Instantly show the local image — Rx map mutation rebuilds Obx
            widget.controller.localUploadingPhotos[index] = imgStr;

            // Show global loader overlay while background upload is completing
            AppLoader.show(message: 'Uploading photo...');
            await _startBackgroundUpload(imgStr, index);
            AppLoader.hide();
          }
        }
      },
      child: Stack(
        children: [
          // Photo rendering base layout. When the server URL is
          // available, pass the local file as CachedNetworkImage's
          // placeholder so the file→network swap is seamless instead of
          // flashing the grey download placeholder.
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.expand(
              child: hasServer
                  ? CachedNetworkImage(
                      imageUrl: serverUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => hasLocal
                          ? Image.file(File(localPath), fit: BoxFit.cover)
                          : Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => hasLocal
                          ? Image.file(File(localPath), fit: BoxFit.cover)
                          : _buildPlaceholderContent(placeholderImage),
                    )
                  : hasLocal
                      ? Image.file(File(localPath), fit: BoxFit.cover)
                      : _buildBlurredPlaceholder(placeholderImage),
            ),
          ),

          // Label text container at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
                label,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Camera icon overlay indicator for unselected slots
          if (!hasPhoto)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: LocalAssets(
                    imagePath: AppIconAssets.profile_camera_pic,
                    height: 20,
                    width: 20,
                    imgColor: AppColors.secondaryTextColor,
                  ),
                ),
              ),
            ),

          // Delete button (only displayed once the server has confirmed
          // the photo and we have a URL to send to the delete endpoint).
          if (hasServer)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () async {
                  AppLoader.show(message: 'Removing photo...');
                  try {
                    final data = {ApiKeys.image_url: serverUrl};
                    await widget.controller.deleteLiveStoreImage(data);
                  } finally {
                    // Drop any stale local fallback so Obx renders the
                    // refreshed server state cleanly.
                    widget.controller.localUploadingPhotos.remove(index);
                    AppLoader.hide();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
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
    );
  }

  Future<void> _startBackgroundUpload(String imgStr, int slotIndex) async {
    try {
      // saveBusinessImages internally refetches the profile, so the
      // server URL (needed by the delete endpoint) is available on
      // businessProfileDetails after this returns. We keep the local
      // entry around — the slot uses it as CachedNetworkImage's
      // placeholder so the file→network swap is seamless.
      await widget.controller.saveBusinessImages(imgStr, widget.controller);
    } catch (_) {
      widget.controller.localUploadingPhotos.remove(slotIndex);
    }
  }

  Widget _buildBlurredPlaceholder(String imageName) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imageName,
          fit: BoxFit.cover,
        ),
        ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              color: AppColors.black.withValues(alpha: 0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderContent(String imageName) {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
}