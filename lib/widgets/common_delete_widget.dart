import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class CommonDeleteWidget extends StatelessWidget {
  final Color? imgColor;
  final VoidCallback? voidCallback;
  const CommonDeleteWidget({super.key, this.imgColor, this.voidCallback});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: voidCallback,
      child: LocalAssets(imagePath: AppIconAssets.deleteIcon, imgColor: imgColor),
    );
  }
}
