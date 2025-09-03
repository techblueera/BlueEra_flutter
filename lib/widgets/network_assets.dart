import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/widgets/common_loader.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:octo_image/octo_image.dart';

class NetWorkOcToAssets extends StatelessWidget {
  const NetWorkOcToAssets(
      {Key? key,
      this.height = 0,
      required this.imgUrl,
      this.boxFit,
      this.scale})
      : super(key: key);
  final String? imgUrl;
  final BoxFit? boxFit;
  final double? scale;
  final double? height;
  @override
  Widget build(BuildContext context) {
    return OctoImage(
      fit: boxFit ?? BoxFit.cover,
      image: NetworkImage("$imgUrl", scale: scale ?? 1),
      progressIndicatorBuilder: (context, progress) {
        return showShimmer(height: height);
      },
      errorBuilder: (context, error, stacktrace) => LocalAssets(
        imagePath: AppImageAssets.noImageFound,
        boxFix: BoxFit.cover,
      ),
    );
  }
}
