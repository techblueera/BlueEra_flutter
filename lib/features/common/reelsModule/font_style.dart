import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:flutter/material.dart';

abstract class AppFontStyle {
  static styleW400(Color? color, double? fontSize) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      fontFamily: AppConstants.OpenSans,
    );
  }

  static styleW500(Color? color, double? fontSize) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      fontFamily: AppConstants.OpenSans,
    );
  }

  static styleW600(Color color, double fontSize) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      fontFamily: AppConstants.OpenSans,
    );
  }

  static styleW700(Color? color, double? fontSize) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      fontFamily:AppConstants.OpenSans
    );
  }

  static styleW800(Color? color, double? fontSize) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      fontFamily:AppConstants.OpenSans,
    );
  }

  static styleW900(Color? color, double? fontSize) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      fontFamily: AppConstants.OpenSans,
    );
  }

  static appBarStyle() {
    return const TextStyle(
      fontSize: 21,
      letterSpacing: 0.4,
      fontFamily:AppConstants.OpenSans,
      fontWeight: FontWeight.bold,
    );
  }
}
