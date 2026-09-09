import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomText extends StatelessWidget {
  final String? title;
  final Color? color;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final double? fontSize;
  final TextAlign? textAlign;
  final double? height;
  final FontStyle? fontStyle;
  final TextOverflow? overflow;
  final int? maxLines;
  final TextDecoration? decoration;
  final double? letterSpacing;
  final Color? decorationColor;
  final TextDecorationStyle? decorationStyle;

  /// Optional text shadow, for labels that sit directly on imagery (e.g. the
  /// Discover folder captions over the blurred profile photo) and so have no
  /// guaranteed contrast from a background of their own.
  final List<Shadow>? shadows;

  const CustomText(
    this.title, {
    Key? key,
    this.color,
    this.fontWeight,
    this.fontFamily,
    this.fontSize,
    this.textAlign,
    this.height,
    this.fontStyle,
    this.maxLines,
    this.overflow,
    this.decoration = TextDecoration.none,
    this.letterSpacing,
    this.decorationColor,
    this.decorationStyle,
    this.shadows,
  }) : super(key: key);

  /// App-wide weight step-down.
  ///
  /// ~69% of this app's TextStyles ask for w600 or heavier (2254 x w600,
  /// 1572 x w700, 751 x w800, 691 x bold). That was written against a build
  /// where it never actually rendered: `AppConstants.OpenSans` used to be
  /// "Open Sans", which matched no bundled family, so every weight fell through
  /// to the platform font — and the old Android/Skia stack, with only static
  /// Roboto faces to choose from, quietly rounded w600 down to Medium and w800
  /// down to Bold. The design was tuned against that rounding.
  ///
  /// Once the family name was fixed and the real Open Sans 300-800 faces were
  /// bundled, those weights started rendering as written, and the whole app
  /// went visibly bold. This restores the previous rendered weight by asking
  /// for one step lighter than the call site requests.
  ///
  /// It is deliberately a lookup and not arithmetic, so every mapping is
  /// visible and w400/w300 are left alone rather than driven thinner.
  ///
  /// NOTE this makes `CustomText(fontWeight: w700)` render SemiBold, which is
  /// surprising if you don't know why. It is a compatibility shim, not a design
  /// system: the honest fix is to step the ~5357 call sites down and delete
  /// this. It also does NOT cover the ~1256 raw `Text(` widgets, which still
  /// render exactly what they ask for.
  // Keyed by `FontWeight.value` (100-900) rather than by FontWeight itself:
  // FontWeight overrides `==`, so it cannot be a const map key.
  static const Map<int, FontWeight> _lighten = {
    900: FontWeight.w700,
    800: FontWeight.w700,
    700: FontWeight.w600,
    600: FontWeight.w500,
    500: FontWeight.w400,
  };

  @override
  Widget build(BuildContext context) {
    return Text(
      title?.tr ?? "",
      textAlign: textAlign,
      maxLines: maxLines,
      softWrap: true,
      style: TextStyle(
        color: color ?? AppColors.black,
        fontFamily: fontFamily ?? AppConstants.OpenSans,
        fontWeight:
            _lighten[fontWeight?.value] ?? fontWeight ?? FontWeight.w400,
        fontSize: fontSize ?? SizeConfig.medium,
        height: height,
        fontStyle: fontStyle,
        overflow: overflow,
        decoration: decoration,
        letterSpacing: letterSpacing,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: 2,
        shadows: shadows,
      ),
    );
  }
}
