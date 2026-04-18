import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StoreLivePhotoWidget extends StatelessWidget {
  final List<String> livePhotos;
  final String? natureOfBusiness;
  final double height;
  final Function({
  required int index,
  required List<String> storeImage,
  required String natureOfBusiness,
  }) onViewFullScreen;

  const StoreLivePhotoWidget({
    Key? key,
    required this.livePhotos,
    required this.onViewFullScreen,
    this.natureOfBusiness,
    this.height = 160,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final businessName = natureOfBusiness ?? 'OTHER';
    final count = livePhotos.length;

    if (count == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _buildLayout(businessName),
    );
  }

  Widget _buildLayout(String businessName) {
    if (livePhotos.length == 1) {
      // Single image full width
      return _buildImage(
        index: 0,
        height: height,
        width: double.infinity,
        businessName: businessName,
      );
    }

    if (livePhotos.length == 2) {
      // Two images side by side
      return Row(
        children: [
          Expanded(
            child: _buildImage(
              index: 0,
              height: height,
              businessName: businessName,
            ),
          ),
          const SizedBox(width: 1),
          Expanded(
            child: _buildImage(
              index: 1,
              height: height,
              businessName: businessName,
            ),
          ),
        ],
      );
    }

    if (livePhotos.length == 3) {
      // One large left + two stacked right
      return Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.white, width: 1),
                ),
              ),
              child: _buildImage(
                index: 0,
                height: height,
                businessName: businessName,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _buildImage(
                  index: 1,
                  height: height / 2 - 0.5,
                  businessName: businessName,
                ),
                const SizedBox(height: 1),
                _buildImage(
                  index: 2,
                  height: height / 2 - 0.5,
                  businessName: businessName,
                ),
              ],
            ),
          ),
        ],
      );
    }

    // 4+ images — 2x2 grid
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildImage(
                index: 0,
                height: height / 2 - 0.5,
                businessName: businessName,
              ),
            ),
            const SizedBox(width: 1),
            Expanded(
              child: _buildImage(
                index: 1,
                height: height / 2 - 0.5,
                businessName: businessName,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Row(
          children: [
            Expanded(
              child: _buildImage(
                index: 2,
                height: height / 2 - 0.5,
                businessName: businessName,
              ),
            ),
            const SizedBox(width: 1),
            Expanded(
              child: _buildImage(
                index: 3,
                height: height / 2 - 0.5,
                businessName: businessName,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImage({
    required int index,
    required double height,
    double? width,
    required String businessName,
  }) {
    final imageUrl = (index < livePhotos.length) ? livePhotos[index] : '';

    return GestureDetector(
      onTap: () => onViewFullScreen(
        index: index,
        storeImage: livePhotos,
        natureOfBusiness: businessName,
      ),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        height: height,
        width: SizeConfig.screenWidth,
        fit: BoxFit.cover,
        memCacheWidth: 600,
        memCacheHeight: 600,
        fadeInDuration: const Duration(milliseconds: 100),
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) => LocalAssets(
          imagePath: AppIconAssets.place_holder_image, boxFix: BoxFit.fill),
        errorWidget: (context, url, error) => LocalAssets(
          imagePath: AppIconAssets.place_holder_image, boxFix: BoxFit.fill),
      ),
    );
  }
}
