import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders a flattened gallery from the hotel's per-category [Photos]
/// albums. The layout adapts to the total image count:
///
///   1 image  → full-width card
///   2 images → side-by-side
///   3 images → 1 large left + 2 stacked right
///   4 images → 2×2 grid
///   5+ images → 2×2 grid with a `+n` overlay on the last visible cell
///
/// Tapping any tile opens [ImageViewScreen] with the full flattened list.
class HotelHomeGalleryWidget extends StatelessWidget {
  final List<Photos>? photos;

  const HotelHomeGalleryWidget({super.key, this.photos});

  // Layout tokens — single source of truth for tile spacing and radius.
  static const double _radius = 12;
  static const double _gap = 4;
  static const int _gridVisible = 4;

  static const BorderRadius _topLeft =
      BorderRadius.only(topLeft: Radius.circular(_radius));
  static const BorderRadius _topRight =
      BorderRadius.only(topRight: Radius.circular(_radius));
  static const BorderRadius _bottomLeft =
      BorderRadius.only(bottomLeft: Radius.circular(_radius));
  static const BorderRadius _bottomRight =
      BorderRadius.only(bottomRight: Radius.circular(_radius));
  static const BorderRadius _leftPair =
      BorderRadius.only(
        topLeft: Radius.circular(_radius),
        bottomLeft: Radius.circular(_radius),
      );
  static const BorderRadius _rightPair =
      BorderRadius.only(
        topRight: Radius.circular(_radius),
        bottomRight: Radius.circular(_radius),
      );

  @override
  Widget build(BuildContext context) {
    final all = photos?.expand((p) => p.imageReferences ?? <String>[]).toList() ??
        const <String>[];

    if (all.isEmpty) return const SizedBox.shrink();

    switch (all.length) {
      case 1:
        return _buildOne(context, all);
      case 2:
        return _buildTwo(context, all);
      case 3:
        return _buildThree(context, all);
      default:
        return _buildGrid(context, all);
    }
  }

  // ── Layouts ────────────────────────────────────────────────────────────────

  Widget _buildOne(BuildContext context, List<String> all) {
    return _tap(
      context,
      0,
      all,
      child: _img(all[0], height: 220, radius: BorderRadius.circular(_radius)),
    );
  }

  Widget _buildTwo(BuildContext context, List<String> all) {
    return Row(
      children: [
        Expanded(
          child: _tap(context, 0, all,
              child: _img(all[0], height: 180, radius: _leftPair)),
        ),
        const SizedBox(width: _gap),
        Expanded(
          child: _tap(context, 1, all,
              child: _img(all[1], height: 180, radius: _rightPair)),
        ),
      ],
    );
  }

  Widget _buildThree(BuildContext context, List<String> all) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _tap(context, 0, all,
                child: _img(all[0],
                    height: double.infinity, radius: _leftPair)),
          ),
          const SizedBox(width: _gap),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _tap(context, 1, all,
                      child: _img(all[1],
                          height: double.infinity, radius: _topRight)),
                ),
                const SizedBox(height: _gap),
                Expanded(
                  child: _tap(context, 2, all,
                      child: _img(all[2],
                          height: double.infinity, radius: _bottomRight)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 4-up grid; when there are more than 4 images, the last visible cell
  /// gets a translucent `+n` overlay tappable to the full viewer.
  Widget _buildGrid(BuildContext context, List<String> all) {
    final count = all.length;
    final showOverlay = count > _gridVisible;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _gridVisible,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: _gap,
        mainAxisSpacing: _gap,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final isLast = index == _gridVisible - 1;
        final tile = _img(all[index],
            height: double.infinity, radius: _corner(index));

        if (!(showOverlay && isLast)) {
          return _tap(context, index, all, child: tile);
        }

        return _tap(
          context,
          index,
          all,
          child: Stack(
            fit: StackFit.expand,
            children: [
              tile,
              ClipRRect(
                borderRadius: _corner(index),
                child: Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: Text(
                    '+${count - _gridVisible}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _tap(BuildContext context, int index, List<String> all,
      {required Widget child}) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: all,
            initialIndex: index,
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _img(String url, {double? height, required BorderRadius radius}) {
    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        placeholder: (context, _) => LocalAssets(
          imagePath: AppIconAssets.place_holder_image,
          boxFix: BoxFit.cover,
        ),
        errorWidget: (context, _, __) => LocalAssets(
          imagePath: AppIconAssets.place_holder_image,
          boxFix: BoxFit.cover,
        ),
      ),
    );
  }

  /// Per-cell corner radius for the 2×2 grid: only the outer corners are
  /// rounded so adjacent tiles butt up cleanly.
  BorderRadius _corner(int index) {
    switch (index) {
      case 0:
        return _topLeft;
      case 1:
        return _topRight;
      case 2:
        return _bottomLeft;
      default:
        return _bottomRight;
    }
  }
}
