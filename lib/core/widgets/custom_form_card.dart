import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

import '../../widgets/common_box_shadow.dart';

class CustomFormCard extends StatelessWidget {
  final Widget? child;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final bool? isBorderAvailable;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;

  const CustomFormCard({
    super.key,
    required this.child,
    this.width,
    this.padding,
    this.isBorderAvailable=false,
    this.margin,
    this.color,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      margin: margin,
      padding: padding ?? EdgeInsets.all(SizeConfig.size15),
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(10.0),
        border: border,
        boxShadow: (isBorderAvailable??false)?[
          BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 5,
          spreadRadius: 0.5,
          offset: Offset(-5, 0), // 👈 Left side shadow
        ),
          BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 5,
          spreadRadius: 0.5,
          offset: Offset(5, 0), // 👈 Left side shadow
        ),
        ]:null,
      ),
      child: child,
    );
  }
}
class CustomFormCardBGImg extends StatelessWidget {
  final Widget? child;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final String? bgImage;
  final bool? isBorderAvailable;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;

  const CustomFormCardBGImg({
    super.key,
    required this.child,
    this.width,
    this.padding,
    this.isBorderAvailable=false,
    this.margin,
    this.bgImage,
    this.color,
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      margin: margin,
      padding: padding ?? EdgeInsets.all(SizeConfig.size15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        // --- Added Background Image ---
        image: DecorationImage(
          image: AssetImage('assets/images/$bgImage'), // Or NetworkImage('url')
          fit: BoxFit.cover, // This ensures the image fills the container
        ),
      ),
      child: child,
    );
  }
}
