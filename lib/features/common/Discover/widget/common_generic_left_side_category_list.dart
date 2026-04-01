import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/local_assets.dart';

class CommonGenericLeftSideCategoryList<T> extends StatelessWidget {
  final List<T> items;
  final String Function(T item) getLabel;
  final String Function(T item) getIcon;
  final bool Function(T item) isSelected;
  final Function(T item, int index) onTap;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const  CommonGenericLeftSideCategoryList({
    super.key,
    required this.items,
    required this.getLabel,
    required this.getIcon,
    required this.isSelected,
    required this.onTap,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? SizeConfig.screenWidth * 0.18,
      height: SizeConfig.screenHeight,
      color: AppColors.white,
      child: ListView.builder(
        itemCount: items.length,
        padding: padding ?? EdgeInsets.only(bottom: SizeConfig.size30),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final item = items[index];

          return Obx(() {
            final bool selected = isSelected(item);
            final String label = getLabel(item);
            final String icon = getIcon(item);

            return InkWell(
              onTap: () => onTap(item, index),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: selected ? 10 : 6,  horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.white : null,
                    gradient: selected
                        ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.skyBlueE4,
                        AppColors.skyBlueE4.withValues(alpha: 0.3),
                      ],
                    ) : null,
                    border: selected
                        ? const Border(
                      left: BorderSide(
                        color: AppColors.primaryColor,
                        width: 3,
                        style: BorderStyle.solid,
                      ),
                    )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        padding: EdgeInsets.all(6),
                        height: selected ? 60 : 50,
                        width: selected ? 60 : 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? null : AppColors.skyBlueE4,
                        ),
                        child: isNetworkImage(icon)
                            ? CachedNetworkImage(
                          imageUrl: icon,
                          height: selected ? 60 : 50,
                          width: selected ? 60 : 50,
                          // fit: BoxFit.cover,
                          placeholder: (context, url) => const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : LocalAssets(
                          imagePath: icon,
                          height: selected ? 60 : 50,
                          width: selected ? 60 : 50,
                          // boxFix: BoxFit.cover, // Ensure image scales correctly
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        style: TextStyle(
                          fontSize: selected ? 11 : 10,
                          fontWeight: FontWeight.w600,
                          color: selected ? AppColors.mainTextColor : AppColors.secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          // Remove style here since AnimatedDefaultTextStyle handles it
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}