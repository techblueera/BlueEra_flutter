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

  final Map<int, bool> _loadingSlots = {};

  void _setLoading(int index, bool loading) {
    setState(() {
      _loadingSlots[index] = loading;
    });
  }

  bool _isLoading(int index) => _loadingSlots[index] ?? false;

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
          GetBuilder<ViewBusinessDetailsController>(
            id: 'livePhotos',
            builder: (_) {
              final photos = widget.controller
                      .businessProfileDetails.value?.data?.livePhotos ??
                  [];

              // MediaQuery.removePadding strips the inherited top inset
              // that GridView.builder otherwise picks up as implicit
              // scroll padding — which was causing a ~30+ px ghost gap
              // between the title and the first photo row.
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
                    final hasPhoto = index < photos.length &&
                        photos[index].isNotEmpty;
                    final photoUrl =
                        hasPhoto ? photos[index] : null;
                    final config = _slotConfig[index];

                    return _buildPhotoSlot(
                      context: ctx,
                      index: index,
                      photoUrl: photoUrl,
                      label: config['label']!,
                      placeholderImage: config['image']!,
                      allPhotos: photos,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot({
    required BuildContext context,
    required int index,
    required String? photoUrl,
    required String label,
    required String placeholderImage,
    required List<String> allPhotos,
  }) {
    final bool hasPhoto = photoUrl != null;
    final bool isLoading = _isLoading(index);

    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              if (hasPhoto) {
                navigatePushTo(
                  context,
                  ImageViewScreen(
                    appBarTitle: AppStrings.imageViewer,
                    subTitle: '',
                    imageUrls: allPhotos,
                    initialIndex: index,
                  ),
                );
              } else {
                final imgStr =
                    await PhotoPickerService.pickFromCamera(
                  context,
                  cropAspectRatio: CropAspectRatio(width: 3, height: 4),
                );
                if (imgStr != null) {
                  _setLoading(index, true);
                  await widget.controller
                      .saveBusinessImages(imgStr, widget.controller);
                  widget.controller.update(['livePhotos']);
                  _setLoading(index, false);
                }
              }
            },
      child: Stack(
        children: [
          // Base container
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.expand(
              child: hasPhoto
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) =>
                          _buildPlaceholderContent(placeholderImage),
                    )
                  : _buildBlurredPlaceholder(placeholderImage),
            ),
          ),

          // Label at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
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

          // Camera icon overlay for empty slots
          if (!hasPhoto && !isLoading)
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

          // Delete button for uploaded photos
          if (hasPhoto && !isLoading)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () async {
                  _setLoading(index, true);
                  final data = {ApiKeys.image_url: photoUrl};
                  await widget.controller.deleteLiveStoreImage(data);
                  widget.controller.businessProfileDetails.value?.data
                      ?.livePhotos
                      ?.removeAt(index);
                  widget.controller.update(['livePhotos']);
                  _setLoading(index, false);
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
                  child: const Icon(Icons.close,
                      size: 14, color: Colors.grey),
                ),
              ),
            ),

          // Loading overlay
          if (isLoading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
