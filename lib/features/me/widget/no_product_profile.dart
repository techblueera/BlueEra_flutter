import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_image_assets.dart';
import '../../../widgets/local_assets.dart';
class NoProfileDetailsFound extends StatelessWidget {
  const NoProfileDetailsFound({super.key, required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          LocalAssets(
            imagePath: AppImageAssets.noMeContent,
          ),
          SizedBox(
            height: SizeConfig.size10,
          ),
          CustomText(content)
        ],
      ),
    );
  }
}
