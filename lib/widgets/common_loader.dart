
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

Widget showShimmer({double? height}) {
  return Shimmer.fromColors(
    baseColor: AppColors.white.withAlpha(51),
    highlightColor: Colors.grey.shade100,
    child: Container(
      color: Colors.white,
      height: height ?? 150,
      width:SizeConfig.screenWidth,
    ),
  );
}