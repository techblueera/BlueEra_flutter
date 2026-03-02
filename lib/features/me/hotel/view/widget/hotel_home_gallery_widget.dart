import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HotelHomeGalleryWidget extends StatelessWidget {
  final List<Photos>? photos;

  const HotelHomeGalleryWidget({super.key, this.photos});

  @override
  Widget build(BuildContext context) {
    // 1. Consolidate all imageReferences into a single List<String>
    final List<String> allImages = photos
            ?.expand((photo) => photo.imageReferences ?? <String>[])
            .toList() ??
        [];

    if (allImages.isEmpty) return const SizedBox.shrink();

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(
            title: AppStrings.gallery,
          ),
          const SizedBox(height: 16),
          StaggeredGrid.count(
            crossAxisCount: 4, // Total grid columns
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: List.generate(
                allImages.length > 10 ? 10 : allImages.length, (index) {
              // Logic to replicate the pattern in your image:
              // Large Vertical (index 0), Two small (index 1,2), Large Horizontal (index 3)...
              int crossAxisCellCount = 2;
              num mainAxisCellCount = 2;

              if (index % 6 == 0 || index % 6 == 5) {
                // Large Vertical Tiles
                crossAxisCellCount = 2;
                mainAxisCellCount = 3;
              } else if (index % 6 == 3) {
                // Large Full-Width Horizontal Tile
                crossAxisCellCount = 4;
                mainAxisCellCount = 2;
              } else {
                // Standard Small Squares
                crossAxisCellCount = 2;
                mainAxisCellCount = 1.5;
              }

              return StaggeredGridTile.count(
                crossAxisCellCount: crossAxisCellCount,
                mainAxisCellCount: mainAxisCellCount,
                child: InkWell(
                  onTap: () {
                    navigatePushTo(
                      context,
                      ImageViewScreen(
                        subTitle: AppStrings.imageViewer,
                        appBarTitle: AppStrings.imageViewer,
                        imageUrls: allImages,
                        initialIndex: index,
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      allImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
