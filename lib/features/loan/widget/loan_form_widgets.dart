import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palette for the Quick Loan Apply form.
///
/// Literal values rather than [AppColors] tokens, for the same reason the
/// account-plan surface keeps its own: this form is drawn to a specific comp
/// (`assets/loan_first.jpeg`, `assets/loan_first_below.jpeg`,
/// `assets/loan_second_final.jpeg`) — a pale blue-grey page carrying white
/// cards, each field a soft grey plate with no visible border until it is
/// wrong. Only the CTA and the selected states are saturated.
abstract class LoanPalette {
  /// The pale periwinkle page behind the cards.
  static const Color canvas = Color(0xFFE9EEF8);

  static const Color card = Color(0xFFFFFFFF);

  /// A select control's resting fill — the flat grey plate in the comp.
  ///
  /// This once covered the text inputs too, on the reasoning that the cards are
  /// the white surface and the fields are recesses cut into them, so a white
  /// field would vanish into its own card. The text inputs have since moved to
  /// the app's shared [CommonTextField] by request, which draws white on a drop
  /// shadow — the shadow is what keeps it off its card. The plate stays for the
  /// dropdowns and the DOB parts, which have no shared equivalent.
  static const Color fieldFill = Color(0xFFF4F6FA);
  static const Color fieldBorder = Color(0xFFE6E9F0);

  static const Color heading = Color(0xFF121826);
  static const Color label = Color(0xFF3D4557);
  static const Color hint = Color(0xFF98A0B4);

  /// Selected chip / selected profession card. Pairs with
  /// [AppColors.primaryColor] as the border — the comp's only saturated
  /// states besides the CTA.
  static const Color selectedFill = Color(0xFFE7F3FF);

  static const Color error = Color(0xFFC0392B);

  // ── Type scale, read off the comp ───────────────────────────────
  /// "Personal Details" / "Loan Details".
  static double get sectionTitle => SizeConfig.size20;

  /// "Enter your basic personal information".
  static double get sectionSubtitle => SizeConfig.size13;

  /// "Name", "Date Of Birth" — the line above each control.
  static double get fieldLabel => SizeConfig.size14;

  /// Typed values and placeholders.
  static double get fieldText => SizeConfig.size16;
}

/// One white section card — the icon + title + subtitle header from the comp,
/// then the fields.
class LoanSectionCard extends StatelessWidget {
  const LoanSectionCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  /// The section's illustrated glyph — an [AppIconAssets] SVG, drawn at its
  /// authored 32x32 and **never tinted**: the artwork is two-tone (app blue
  /// over dark ink) and an `imgColor` would flatten it to one colour.
  final String iconPath;

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: LoanPalette.card,
        borderRadius: BorderRadius.circular(SizeConfig.size16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalAssets(
                imagePath: iconPath,
                height: SizeConfig.size32,
                width: SizeConfig.size32,
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      title,
                      fontSize: LoanPalette.sectionTitle,
                      fontWeight: FontWeight.w800,
                      color: LoanPalette.heading,
                      maxLines: 2,
                    ),
                    SizedBox(height: SizeConfig.size2),
                    CustomText(
                      subtitle,
                      fontSize: LoanPalette.sectionSubtitle,
                      fontWeight: FontWeight.w500,
                      color: LoanPalette.hint,
                      height: 1.3,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size16),
          ...children,
        ],
      ),
    );
  }
}

/// The label + control + error stack every field in the comp shares.
///
/// The error line is what gives the plate its only border: fields are
/// borderless at rest, so a red rim is unambiguous rather than one shade among
/// several.
class LoanField extends StatelessWidget {
  const LoanField({
    super.key,
    required this.label,
    required this.child,
    this.error,
  });

  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final hasError = (error ?? '').isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(bottom: SizeConfig.size14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            label,
            fontSize: LoanPalette.fieldLabel,
            fontWeight: FontWeight.w500,
            color: LoanPalette.label,
          ),
          SizedBox(height: SizeConfig.size6),
          child,
          if (hasError) ...[
            SizedBox(height: SizeConfig.size4),
            CustomText(
              error!,
              fontSize: SizeConfig.size11,
              fontWeight: FontWeight.w600,
              color: LoanPalette.error,
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }
}

/// The grey plate the SELECT controls sit on — shared so a dropdown and the
/// three DOB parts read as the same control.
///
/// The text fields no longer use it: they are [CommonTextField], the app's
/// shared input, which brings its own white-with-shadow plate. So this form
/// deliberately shows two surfaces — white for anything you type into, grey for
/// anything you pick from — rather than the single grey plate of the comp.
BoxDecoration loanPlateDecoration({bool hasError = false}) => BoxDecoration(
      color: LoanPalette.fieldFill,
      borderRadius: BorderRadius.circular(SizeConfig.size10),
      border: Border.all(
        color: hasError ? LoanPalette.error : LoanPalette.fieldBorder,
      ),
    );

/// A dropdown on the shared plate. `T` is whatever the caller stores; [label]
/// renders it.
class LoanDropdown<T> extends StatelessWidget {
  const LoanDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.hint,
    required this.onChanged,
    this.hasError = false,
  });

  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final String hint;
  final ValueChanged<T?> onChanged;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    // DropdownButton ASSERTS that `value` matches exactly one item, and throws
    // otherwise — which would blank the whole step the way the profession Row
    // did, rather than degrade.
    //
    // Not a can't-happen: [items] is server-driven for residence types (they
    // come from `GET /loan-applications/options`), so a value that was a legal
    // option when it was picked can stop being one under the user. Falling back
    // to the hint is the honest render for that — the field reads as unset,
    // which it now effectively is, and the validator says so on submit.
    final safeValue = items.where((e) => e == value).length == 1 ? value : null;

    return Container(
      decoration: loanPlateDecoration(hasError: hasError),
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isExpanded: true,
          isDense: false,
          borderRadius: BorderRadius.circular(SizeConfig.size10),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: LoanPalette.label, size: SizeConfig.size24),
          hint: CustomText(
            hint,
            fontSize: LoanPalette.fieldText,
            fontWeight: FontWeight.w400,
            color: LoanPalette.hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(
                value: item,
                child: CustomText(
                  itemLabel(item),
                  fontSize: LoanPalette.fieldText,
                  fontWeight: FontWeight.w500,
                  color: LoanPalette.heading,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// One of the two profession cards — "Salaried" / "Self-Employed".
///
/// A card rather than a radio because the choice carries a sentence of
/// explanation under it, and because it is the single control that decides
/// which half of the form the applicant fills in.
class LoanProfessionCard extends StatelessWidget {
  const LoanProfessionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size12,
        ),
        decoration: BoxDecoration(
          color: selected ? LoanPalette.selectedFill : LoanPalette.fieldFill,
          borderRadius: BorderRadius.circular(SizeConfig.size12),
          border: Border.all(
            color: selected ? AppColors.primaryColor : LoanPalette.fieldBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              title,
              fontSize: SizeConfig.size16,
              fontWeight: FontWeight.w800,
              color: LoanPalette.heading,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              subtitle,
              fontSize: SizeConfig.size11,
              fontWeight: FontWeight.w400,
              color: LoanPalette.label,
              textAlign: TextAlign.center,
              height: 1.3,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

/// A tenure pill — "3 Months", "12 Months".
class LoanChoiceChip extends StatelessWidget {
  const LoanChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size10,
        ),
        decoration: BoxDecoration(
          color: selected ? LoanPalette.selectedFill : LoanPalette.fieldFill,
          borderRadius: BorderRadius.circular(SizeConfig.size20),
          border: Border.all(
            color: selected ? AppColors.primaryColor : LoanPalette.fieldBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: CustomText(
          label,
          fontSize: SizeConfig.size14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primaryColor : LoanPalette.label,
        ),
      ),
    );
  }
}

/// A square checkbox with a rich label beside it — the "No Existing EMI" and
/// terms rows.
///
/// **Must be given a BOUNDED width.** The label is [Flexible] so a long one
/// wraps instead of overflowing, and a flex child under unbounded width is an
/// assertion, not a soft failure — it aborts layout and every ancestor up to
/// the enclosing scroll view then reports "RenderBox was not laid out".
///
/// A direct child of a Column is already bounded. A child of a **Row** is not:
/// non-flex children of a Row are laid out with an unbounded max width, so
/// wrap it in a [Flexible] or [Expanded] there.
class LoanCheckRow extends StatelessWidget {
  const LoanCheckRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.child,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget child;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: SizeConfig.size20,
            height: SizeConfig.size20,
            decoration: BoxDecoration(
              color: value ? AppColors.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(SizeConfig.size4),
              border: Border.all(
                color: value ? AppColors.primaryColor : LoanPalette.hint,
                width: 1.5,
              ),
            ),
            child: value
                ? Icon(Icons.check_rounded,
                    size: SizeConfig.size14, color: AppColors.white)
                : null,
          ),
          SizedBox(width: SizeConfig.size8),
          Flexible(child: child),
        ],
      ),
    );
  }
}

/// Forces PAN to uppercase as it is typed, rather than only at send time — the
/// applicant should see the value the backend will store.
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
