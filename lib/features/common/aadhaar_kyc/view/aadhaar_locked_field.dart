import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Green "Aadhaar Verified" caption pinned under a field the user can't edit.
///
/// Without it a greyed-out input reads as broken. With it, it reads as already
/// answered — by a document, which is the point.
class AadhaarLockedNote extends StatelessWidget {
  const AadhaarLockedNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: SizeConfig.size6),
      child: Row(
        children: [
          Icon(Icons.verified_user_rounded, size: 13, color: AppColors.green00),
          SizedBox(width: SizeConfig.size4),
          Expanded(
            child: CustomText(
              AppStrings.aadhaarVerified.tr,
              fontSize: SizeConfig.small,
              fontWeight: FontWeight.w600,
              color: AppColors.green00,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a form control that must not be edited because a verified Aadhaar is
/// the authority on its value — name, date of birth, gender.
///
/// The lock is applied from OUTSIDE the control on purpose: the dropdown and
/// the date picker have no disabled state of their own, and a text field's
/// `readOnly` doesn't dim it. [AbsorbPointer] swallows the taps, the fade says
/// something is off-limits, and [AadhaarLockedNote] says why. Pass
/// `locked: false` and the child renders exactly as it would unwrapped.
///
/// A text field can still take `readOnly: locked` in addition — that stops the
/// keyboard on a field which is otherwise reachable by focus traversal.
class AadhaarLockedField extends StatelessWidget {
  const AadhaarLockedField({
    super.key,
    required this.locked,
    required this.child,
  });

  final bool locked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AbsorbPointer(child: Opacity(opacity: 0.6, child: child)),
        const AadhaarLockedNote(),
      ],
    );
  }
}
