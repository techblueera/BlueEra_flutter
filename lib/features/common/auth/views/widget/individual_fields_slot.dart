import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/widgets/inline_load_error.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The loading / failed / loaded switch every individual-fields picker goes
/// through — the expertise, art-and-skill and content-creator-field dropdowns,
/// in profile creation, profile setup and the designation sheet.
///
/// All nine of those sites used to spell out `isIndividualFieldLoading ? a : b`
/// and had no third branch, so a failed fetch fell through to the loaded one
/// and drew a picker over an empty list: nothing to choose, no reason given,
/// and no way to ask again short of backing out of the flow. Two of them also
/// indexed `arrIndividualFields[0]` on that empty list and threw a RangeError
/// mid-build, which took the screen down rather than the dropdown.
///
/// Lives as a widget rather than a method so the sites inside
/// `_showCategoryBottomSheet` — which are in a plain method, not a State — can
/// use the same thing.
class IndividualFieldsSlot extends StatelessWidget {
  const IndividualFieldsSlot({super.key, required this.picker});

  /// Built only in the loaded case, and INSIDE the `Obx`: it reads the list it
  /// is built from, so building it eagerly would read that list outside the
  /// reactive scope and pay for a widget the other two branches discard.
  final Widget Function() picker;

  @override
  Widget build(BuildContext context) {
    final authController = getOrPut(() => AuthController());

    return Obx(() {
      if (authController.isIndividualFieldLoading.value) {
        return Center(child: CircularProgressIndicator());
      }
      final error = authController.individualFieldsError.value;
      if (error != null) {
        return InlineLoadError(
          message: error,
          onRetry: authController.retryIndividualFields,
        );
      }
      return picker();
    });
  }
}
