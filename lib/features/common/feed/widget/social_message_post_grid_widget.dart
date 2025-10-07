import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final subTitle;

  const SocialImageGrid(
      {super.key, required this.imageUrls, required this.subTitle});

  @override
  Widget build(BuildContext context) {
    final count = imageUrls.length;

    if (count == 0) return const SizedBox();

    // Single image
    if (count == 1) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: netWorkImage(urlLink: imageUrls[0], index: 0, heightImg: 300));
    }
    // Four images → 2x2 grid
    if (count == 2) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          return ClipRRect(
              borderRadius: index == 0
                  ? BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12))
                  : BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12)),
              child: netWorkImage(
                  urlLink: imageUrls[index], index: index, heightImg: 0));
        },
      );
    }

    // Three images → 1 landscape + 2 below
    if (count == 3)
      return AspectRatio(
        aspectRatio: 16 / 9,
        // Adjust overall height ratio (looks better like Twitter)
        child: Row(
          children: [
            // Left large image
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12)),
                child: netWorkImage(
                    urlLink: imageUrls[0],
                    index: 0,
                    heightImg: double.infinity),
              ),
            ),
            const SizedBox(width: 4),
            // Right side - 2 stacked images
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        imageUrls[1],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        imageUrls[2],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

    // Four images → 2x2 grid
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
        itemBuilder: (context, index) {
          return ClipRRect(
              borderRadius: index == 0
                  ? BorderRadius.only(
                      topLeft: Radius.circular(12),
                    )
                  : index == 1
                      ? BorderRadius.only(
                          topRight: Radius.circular(12),
                        )
                      : index == 2
                          ? BorderRadius.only(bottomLeft: Radius.circular(12))
                          : BorderRadius.only(bottomRight: Radius.circular(12)),
              child: netWorkImage(
                  urlLink: imageUrls[index], index: index, heightImg: 180));
        },
      );
    }

    // 5 or more → 2x2 + overlay with +X on last image
    if (count > 4) {
      final maxImages = 4;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count > maxImages ? maxImages : count,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1.3,
        ),
        itemBuilder: (context, index) {
          if (index == maxImages - 1 && count > maxImages) {
            return InkWell(
              onTap: () => onTapImage(indexOfImage: index),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                      borderRadius: index == 0
                          ? BorderRadius.only(
                              topLeft: Radius.circular(12),
                            )
                          : index == 1
                              ? BorderRadius.only(
                                  topRight: Radius.circular(12),
                                )
                              : index == 2
                                  ? BorderRadius.only(
                                      bottomLeft: Radius.circular(12))
                                  : BorderRadius.only(
                                      bottomRight: Radius.circular(12)),
                      child: netWorkImage(
                          urlLink: imageUrls[index],
                          index: index,
                          heightImg: 0)),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: CustomText(
                        '+${count - maxImages}',
                        color: Colors.white,
                        fontSize: SizeConfig.size28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return ClipRRect(
              borderRadius: index == 0
                  ? BorderRadius.only(
                topLeft: Radius.circular(12),
              )
                  : index == 1
                  ? BorderRadius.only(
                topRight: Radius.circular(12),
              )
                  : index == 2
                  ? BorderRadius.only(
                  bottomLeft: Radius.circular(12))
                  : BorderRadius.only(
                  bottomRight: Radius.circular(12)),
              child: netWorkImage(
                  urlLink: imageUrls[index], index: index, heightImg: 0));
        },
      );
    }

    return const SizedBox();
  }

  netWorkImage(
      {required String urlLink, required int index, double? heightImg}) {
    return InkWell(
      onTap: () => onTapImage(indexOfImage: index),
      child: CachedNetworkImage(
        imageUrl: urlLink,
        fit: BoxFit.cover,
        width: Get.width,
        height: heightImg?.toDouble() ?? 300,
        // color: Colors.white,
        placeholder: (context, _) => Center(
          child: LocalAssets(
            imagePath: AppIconAssets.place_holder_image,
            boxFix: BoxFit.cover,
          ),
        ),
        errorWidget: (context, _, __) => LocalAssets(
          imagePath: AppIconAssets.place_holder_image,
          boxFix: BoxFit.cover,
        ),
      ),
    );
  }

  onTapImage({required int indexOfImage}) {
    Get.to(
      ImageViewScreen(
        subTitle: subTitle ?? "",
        appBarTitle: "Image Viewer",
        imageUrls: imageUrls,
        initialIndex: indexOfImage,
      ),
    );
  }
}
