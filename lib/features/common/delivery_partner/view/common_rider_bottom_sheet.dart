import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommonBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final double? height;

  /// Optional control before the title — a back arrow for sheets whose
  /// content has stages, so "go back a step" and "close the sheet" are two
  /// different buttons rather than one.
  final Widget? leading;

  /// Size the sheet to its content instead of a fixed fraction of the screen.
  ///
  /// The fixed height is right for sheets whose content is always about the
  /// same size. It is wrong for a sheet whose content changes stage — a short
  /// form and a long one then both get the same box, so one floats in dead
  /// space. With this on the sheet is as tall as it needs to be, capped at
  /// [_maxHeightFraction] of the screen, and scrolls past that.
  ///
  /// Off by default so the existing fixed-height callers are untouched.
  final bool fitContent;

  const CommonBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.height,
    this.leading,
    this.fitContent = false,
  });

  /// A content-fitted sheet still has to leave the page behind it visible.
  static const double _maxHeightFraction = 0.9;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    // NOTHING here handles the keyboard, on purpose. GetX's sheet route
    // already wraps the sheet in `Padding(bottom: viewInsets.bottom)`, so it
    // is lifted clear of the keyboard before this widget lays out. Adding the
    // inset again here pushed the content up by twice the keyboard height AND
    // shrank the box by the same amount — which is what made the short
    // Aadhaar-number form start scrolling inside its own sheet.
    //
    // `padding.bottom` (not `viewPadding.bottom`) is the gesture bar: it
    // collapses to zero once the keyboard covers it, so the gap stays the
    // same size whether or not the keyboard is up.
    final double bottomPadding =
        fitContent ? media.padding.bottom + SizeConfig.size30 : 20.0;

    return Container(
      height: fitContent ? null : (height ?? media.size.height * 0.6),
      // Clamped by the route's own constraints, so with the keyboard up this
      // resolves to the space above it rather than overflowing the screen.
      constraints: fitContent
          ? BoxConstraints(maxHeight: media.size.height * _maxHeightFraction)
          : null,
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: fitContent ? MainAxisSize.min : MainAxisSize.max,
        children: [
          // Grab handle — the standard "this panel is draggable" mark, and it
          // gives the sheet a top edge of its own instead of starting cold on
          // the title row.
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: SizeConfig.size12),
              decoration: BoxDecoration(
                color: AppColors.greyE5,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              if (leading != null) leading!,
              Expanded(
                child: CustomText(
                  title,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              InkWell(
                onTap: () => Get.back(),
                child: const Icon(Icons.close),
              ),
            ],
          ),

          SizedBox(
            height: SizeConfig.size10,
          ),
          // Content. Flexible (not Expanded) when fitting, so the column can
          // end above the bottom of the screen instead of filling it.
          Flexible(
            fit: fitContent ? FlexFit.loose : FlexFit.tight,
            child: SingleChildScrollView(
              child: Padding(
                // The filler keeps a fixed-height sheet's last field clear of
                // the gesture bar. A fitted sheet ends where its content
                // does, so the same filler would just be a gap.
                padding: EdgeInsets.only(
                    bottom: fitContent ? 0 : SizeConfig.size60),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
