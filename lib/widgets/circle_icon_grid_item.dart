import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CircleIconGridItem extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;
  final Color? imgColor;

  const CircleIconGridItem({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.imgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: Colors.red,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            double diameter = constraints.maxWidth * 0.75;
            double iconSize = diameter * 0.6;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.center,
                  height: diameter,
                  width: diameter,
                  decoration: const BoxDecoration(
                    color: AppColors.skyBlueE4,
                    shape: BoxShape.circle,
                  ),
                  child: CachedNetworkImage(
                    imageUrl: icon,
                    height: iconSize,
                    width: iconSize,
                    color: imgColor,
                    // fit: BoxFit.contain,
                    placeholder: (context, url) => SizedBox(
                      height: iconSize,
                      width: iconSize,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.broken_image,
                      size: iconSize,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  label,
                  textAlign: TextAlign.center,
                  fontSize: SizeConfig.small11,
                  color: AppColors.blue6B,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// class IconGridItem extends StatelessWidget {
//   final String label;
//   final String icon;
//   final VoidCallback onTap;
//   final Color? imgColor;
//
//   const IconGridItem({
//     super.key,
//     required this.label,
//     required this.icon,
//     required this.onTap,
//     this.imgColor,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       // color: Colors.red,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(10.0),
//               decoration: const BoxDecoration(
//                 color: AppColors.skyBlueE4,
//                 shape: BoxShape.circle,
//               ),
//               child: LocalAssets(
//                 imagePath: icon,
//                 imgColor: imgColor,
//                 height: SizeConfig.size30,
//                 width: SizeConfig.size30,
//               ),
//             ),
//             SizedBox(height: SizeConfig.size6),
//             CustomText(
//               label,
//               textAlign: TextAlign.center,
//               fontSize: SizeConfig.small11,
//               color: AppColors.blue6B,
//               fontWeight: FontWeight.w600,
//               maxLines: 2,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
