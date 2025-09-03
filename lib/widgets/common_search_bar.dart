import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';

class CommonSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onClearCallback;
  final Function(String value)? onChange;
  final VoidCallback? onSearchTap;
  final Color? backgroundColor;
  final String? hintText;
  final double? borderRadius;
  final bool? isShowCursor;

  const CommonSearchBar({
    super.key,
    required this.controller,
    this.onClearCallback,
    this.onChange,
    this.onSearchTap,
    this.backgroundColor,
    this.hintText,
    this.borderRadius,
    this.isShowCursor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SizeConfig.size40,
      // width: SizeConfig.screenWidth,
      // margin: EdgeInsets.only(left: SizeConfig.size15),
      padding: controller.text.isEmpty ? null : EdgeInsets.only(left: SizeConfig.size15),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.greyD3,
        borderRadius: BorderRadius.circular(borderRadius ?? 10.0),
      ),
      alignment: Alignment.center,
      child: TextFormField(onChanged: onChange,
        autofocus: false,
        showCursor: isShowCursor,
        controller: controller,
        style: TextStyle(color: AppColors.black, fontSize: SizeConfig.medium),
        onTap: onSearchTap ?? () {},
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hintText ?? "Search here..",
          hintStyle: TextStyle(fontSize: SizeConfig.medium, color: AppColors.secondaryTextColor),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          prefixIcon: controller.text.isEmpty
              ? Padding(
            padding: EdgeInsets.symmetric(horizontal: SizeConfig.size8, vertical: SizeConfig.size5),
            child: LocalAssets(imagePath: AppIconAssets.chat_search, imgColor: AppColors.mainTextColor),
          )
              : null,
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
            onTap: onClearCallback,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: Icon(Icons.clear, color: AppColors.black28, size: SizeConfig.paddingXL),
            ),
          )
              : null,
          isDense: true,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
