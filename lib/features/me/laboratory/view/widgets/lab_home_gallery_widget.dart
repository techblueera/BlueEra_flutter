import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/laboratory/model/new_lab_full_details_res_model.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/service_home_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Mosaic-style gallery summary for the lab profile home. Flattens every
/// `Galleries.imageUrls` into a single list, then lays out the first
/// [_maxTiles] images in a repeating large-vertical → squares →
/// large-horizontal → squares → large-vertical pattern.
class LabHomeGalleryWidget extends StatelessWidget {
  final List<Galleries>? photos;

  const LabHomeGalleryWidget({super.key, this.photos});

  static const int _maxTiles = 10;
  static const int _gridCrossAxisCount = 4;

  @override
  Widget build(BuildContext context) {
    final allImages = photos
            ?.expand((photo) => photo.imageUrls ?? const <String>[])
            .toList() ??
        const <String>[];

    if (allImages.isEmpty) return const SizedBox.shrink();

    final tileCount =
        allImages.length > _maxTiles ? _maxTiles : allImages.length;

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ServiceHomeTitleWidget(title: AppStrings.gallery),
          const SizedBox(height: 16),
          StaggeredGrid.count(
            crossAxisCount: _gridCrossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: List.generate(
              tileCount,
              (index) => _buildGalleryTile(context, allImages, index),
            ),
          ),
        ],
      ),
    );
  }

  /// Pattern (per 6-tile cycle): index 0 & 5 → tall vertical (2×3),
  /// index 3 → full-width banner (4×2), everything else → square (2×1.5).
  ({int cross, num main}) _tileSpan(int index) {
    final slot = index % 6;
    if (slot == 0 || slot == 5) return (cross: 2, main: 3);
    if (slot == 3) return (cross: 4, main: 2);
    return (cross: 2, main: 1.5);
  }

  Widget _buildGalleryTile(
    BuildContext context,
    List<String> images,
    int index,
  ) {
    final span = _tileSpan(index);
    return StaggeredGridTile.count(
      crossAxisCellCount: span.cross,
      mainAxisCellCount: span.main,
      child: InkWell(
        onTap: () => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: images,
            initialIndex: index,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      ),
    );
  }
}
