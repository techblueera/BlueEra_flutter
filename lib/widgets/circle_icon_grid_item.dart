import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
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
                  child: LocalAssets(
                    imagePath: icon,
                    imgColor: imgColor,
                    height: iconSize,
                    width: iconSize,
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
