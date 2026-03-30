import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class DiscoverLabGalleryWidget extends StatelessWidget {
  final List<Galleries> galleries;

  const DiscoverLabGalleryWidget({super.key, required this.galleries});

  @override
  Widget build(BuildContext context) {
    final List<String> allImages = galleries
        .expand((g) => g.imageUrls ?? <String>[])
        .where((url) => url.isNotEmpty)
        .toList();

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.gallery),
          const SizedBox(height: 12),
          if (allImages.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: EmptyStateWidget(
                message: "No photos available",
                imageSize: 60,
              ),
            )
          else
            _buildGalleryLayout(context, allImages),
        ],
      ),
    );
  }

  Widget _buildGalleryLayout(BuildContext context, List<String> images) {
    final display = images.length > 4 ? images.sublist(0, 4) : images;
    final extra = images.length > 4 ? images.length - 4 : 0;

    void openViewer(int index) => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.gallery,
            appBarTitle: AppStrings.gallery,
            imageUrls: images,
            initialIndex: index,
          ),
        );

    Widget imgTile(int index, {bool showOverlay = false}) {
      return GestureDetector(
        onTap: () => openViewer(index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: display[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, _) => LocalAssets(
                  imagePath: AppIconAssets.place_holder_image,
                  boxFix: BoxFit.cover,
                ),
                errorWidget: (context, _, __) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image_outlined,
                      color: Colors.grey[400], size: 32),
                ),
              ),
              if (showOverlay && extra > 0)
                Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  alignment: Alignment.center,
                  child: CustomText(
                    '+$extra',
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    const double height = 220;
    const double gap = 4;

    // 1 image - full width
    if (display.length == 1) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: imgTile(0),
      );
    }

    // 2 images - side by side
    if (display.length == 2) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: imgTile(0)),
            const SizedBox(width: gap),
            Expanded(child: imgTile(1)),
          ],
        ),
      );
    }

    // 3 images - 1 large left, 2 stacked right
    if (display.length == 3) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: imgTile(0)),
            const SizedBox(width: gap),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: imgTile(1)),
                  const SizedBox(height: gap),
                  Expanded(child: imgTile(2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4+ images - 2x2 grid with +N overlay on last cell
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: imgTile(0)),
                const SizedBox(width: gap),
                Expanded(child: imgTile(1)),
              ],
            ),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: imgTile(2)),
                const SizedBox(width: gap),
                Expanded(child: imgTile(3, showOverlay: extra > 0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
