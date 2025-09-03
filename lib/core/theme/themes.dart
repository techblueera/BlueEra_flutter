// themes.dart
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';

class AppThemes {
  // static final ThemeData darkTheme = ThemeData(
  //   fontFamily: AppConstants.OpenSans,
  //   appBarTheme: AppBarTheme(backgroundColor: AppColors.black28),
  //   scaffoldBackgroundColor: AppColors.blue3F,
  //   colorScheme: ColorScheme.dark(
  //       primary: AppColors.primaryColor,
  //       secondary: AppColors.black28,
  //       outline: Colors.grey,
  //       onSecondary: AppColors.whiteE2 // good for borders
  //       ),
  //   textTheme: TextTheme(
  //     bodyMedium: TextStyle(fontSize: SizeConfig.medium, color: Colors.white), // Default text
  //   ),
  //   textSelectionTheme: TextSelectionThemeData(
  //     cursorColor: Colors.white,
  //     selectionColor: Colors.white.withValues(alpha: 0.51),
  //     selectionHandleColor: Colors.white, // Drag handle
  //   ),
  //   inputDecorationTheme: InputDecorationTheme(
  //     isDense: true,
  //     fillColor: AppColors.black28,
  //     filled: true,
  //     hintStyle: TextStyle(color: AppColors.grey9B, fontSize: SizeConfig.medium, fontWeight: FontWeight.w400),
  //     labelStyle: TextStyle(fontSize: SizeConfig.medium, color: AppColors.white, fontWeight: FontWeight.w600),
  //     errorBorder:
  //         OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.red)),
  //     border:
  //         OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.black28)),
  //     focusedBorder: OutlineInputBorder(
  //       borderSide: BorderSide(width: 1.0, color: AppColors.black28),
  //       borderRadius: BorderRadius.circular(10),
  //     ),
  //     disabledBorder: OutlineInputBorder(
  //       borderSide: BorderSide(width: 1.0, color: AppColors.black28),
  //       borderRadius: BorderRadius.circular(10),
  //     ),
  //     enabledBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(10),
  //       borderSide: BorderSide(
  //         color: AppColors.black28,
  //         width: 1.0,
  //       ),
  //     ),
  //     errorMaxLines: 2,
  //   ),
  // );

  static final ThemeData light = ThemeData(
    hoverColor: Colors.grey,
    fontFamily: AppConstants.OpenSans,
    appBarTheme: AppBarTheme(backgroundColor: Colors.white),
    scaffoldBackgroundColor: AppColors.appBackgroundColor,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryColor,
      onSurface: AppColors.black,
      outline: AppColors.greyAF,
      surface: AppColors.white,
      secondary: AppColors.whiteED,
      tertiary: AppColors.redLightOut,
      onTertiary: AppColors.greenDarkOut,
      inversePrimary: AppColors.greenLightOut,
      inverseSurface: AppColors.secondaryTextColor
      // secondary: AppColors.black28,
      // outline: Colors.grey,
      // onSecondary: AppColors.whiteE2 // good for borders
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(fontSize: SizeConfig.medium, color: Colors.black), // Default text
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.black,
      selectionColor: Colors.black.withValues(alpha: 0.51),
      selectionHandleColor: Colors.black, // Drag handle
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white, // ✅ Set bottom sheet color to white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    iconTheme: IconThemeData(color: Colors.black),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      fillColor: AppColors.white,
      filled: true,
      hintStyle: TextStyle(color: AppColors.grey9A, fontWeight: FontWeight.w400,fontSize: SizeConfig.large),
      labelStyle: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
      disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              width: 1,
              color: AppColors.greyE5)
      ),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              width: 1,
              color: AppColors.greyE5)
      ),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              width: 1,
              color: AppColors.greyE5)
      ),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              width: 1,
              color: AppColors.greyE5)
      ),
      errorBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.red)),

      errorMaxLines: 2,
    ),
  );
}
