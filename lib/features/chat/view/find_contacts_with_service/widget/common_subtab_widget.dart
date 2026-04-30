import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';

class CommonSubTabWidget extends StatelessWidget {
  final String title;
  final int index;
  final int selectedIndex;
  final String? icon;
  final VoidCallback onTap;

  const CommonSubTabWidget({
    super.key,
    required this.title,
    required this.onTap,
    this.icon,
    required this.index,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: onTap,
      child:
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: CustomText(
          title,
          textAlign: TextAlign.center,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade700,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          decoration: TextDecoration.underline,
          decorationColor: isSelected ? AppColors.primaryColor : Colors.black,
        ),
      )
      // AnimatedContainer(
      //   duration: const Duration(milliseconds: 200),
      //   curve: Curves.easeOut,
      //   height: SizeConfig.size114,
      //   width: SizeConfig.size100,
      //   margin: const EdgeInsets.symmetric(horizontal: 4),
      //   decoration: BoxDecoration(
      //     color: AppColors.white,
      //     borderRadius: BorderRadius.circular(14),
      //     border: Border.all(
      //       color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
      //       width: isSelected ? 1.5 : 1,
      //     ),
      //     boxShadow: isSelected
      //         ? [
      //             BoxShadow(
      //               color: AppColors.primaryColor.withValues(alpha: 0.12),
      //               blurRadius: 10,
      //               offset: const Offset(0, 3),
      //             ),
      //           ]
      //         : [
      //             BoxShadow(
      //               color: Colors.black.withValues(alpha: 0.04),
      //               blurRadius: 6,
      //               offset: const Offset(0, 2),
      //             ),
      //           ],
      //   ),
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: [
      //       // if (icon != null)
      //       //   Container(
      //       //     padding: const EdgeInsets.all(6),
      //       //     decoration: BoxDecoration(
      //       //       color: isSelected
      //       //           ? AppColors.primaryColor.withValues(alpha: 0.08)
      //       //           : Colors.grey.shade50,
      //       //       shape: BoxShape.circle,
      //       //     ),
      //       //     child: LocalAssets(
      //       //       boxFix: BoxFit.cover,
      //       //       height: 36,
      //       //       width: 36,
      //       //       imagePath: icon ?? '',
      //       //     ),
      //       //   ),
      //       // const SizedBox(height: 8),
      //       Padding(
      //         padding: const EdgeInsets.symmetric(horizontal: 4),
      //         child: CustomText(
      //           title,
      //           textAlign: TextAlign.center,
      //           fontSize: 10,
      //           fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      //           color: isSelected ? AppColors.primaryColor : Colors.grey.shade700,
      //           maxLines: 2,
      //           overflow: TextOverflow.ellipsis,
      //         ),
      //       ),
      //     ],
      //   ),
      // ),
    );
  }
}
