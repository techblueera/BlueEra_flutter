import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class HotelHomeGalleryWidget extends StatelessWidget {
  final List<Photos>? photos;

  const HotelHomeGalleryWidget({super.key, this.photos});

  @override
  Widget build(BuildContext context) {
    final List<String> all = photos
            ?.expand((p) => p.imageReferences ?? <String>[])
            .toList() ??
        [];

    if (all.isEmpty) return const SizedBox.shrink();

    final count = all.length;

    // ── 1 image: full-width card ──────────────────────────────────────────
    if (count == 1) {
      return _tap(context, 0, all,
          child: _img(all[0],
              height: 220,
              radius: BorderRadius.circular(12)));
    }

    // ── 2 images: side by side ────────────────────────────────────────────
    if (count == 2) {
      return Row(
        children: [
          Expanded(
            child: _tap(context, 0, all,
                child: _img(all[0],
                    height: 180,
                    radius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ))),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _tap(context, 1, all,
                child: _img(all[1],
                    height: 180,
                    radius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ))),
          ),
        ],
      );
    }

    // ── 3 images: 1 big left + 2 vertical right ───────────────────────────
    if (count == 3) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: _tap(context, 0, all,
                  child: _img(all[0],
                      height: double.infinity,
                      radius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ))),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: _tap(context, 1, all,
                        child: _img(all[1],
                            height: double.infinity,
                            radius: const BorderRadius.only(
                              topRight: Radius.circular(12),
                            ))),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: _tap(context, 2, all,
                        child: _img(all[2],
                            height: double.infinity,
                            radius: const BorderRadius.only(
                              bottomRight: Radius.circular(12),
                            ))),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ── 4 images: 2×2 grid ────────────────────────────────────────────────
    if (count == 4) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1.3,
        ),
        itemBuilder: (context, index) => _tap(context, index, all,
            child: _img(all[index],
                height: double.infinity,
                radius: _corner(index))),
      );
    }

    // ── 5+ images: 2×2 + +n overlay ──────────────────────────────────────
    const visible = 4;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final isLast = index == visible - 1;
        return _tap(context, index, all,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _img(all[index],
                    height: double.infinity, radius: _corner(index)),
                if (isLast)
                  ClipRRect(
                    borderRadius: _corner(index),
                    child: Container(
                      color: Colors.black54,
                      alignment: Alignment.center,
                      child: Text(
                        '+${count - visible}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ));
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

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

  Widget _img(String url,
      {double? height, required BorderRadius radius}) {
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

  BorderRadius _corner(int index) {
    switch (index) {
      case 0:
        return const BorderRadius.only(topLeft: Radius.circular(12));
      case 1:
        return const BorderRadius.only(topRight: Radius.circular(12));
      case 2:
        return const BorderRadius.only(bottomLeft: Radius.circular(12));
      default:
        return const BorderRadius.only(bottomRight: Radius.circular(12));
    }
  }
}
