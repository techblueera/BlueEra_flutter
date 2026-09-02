import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// A tap-to-open list of options, built LAZILY.
///
/// ## Why this exists
///
/// The hours editors across the app each rendered their time fields as a
/// `DropdownButton` fed the whole day in 15- or 30-minute steps. A
/// DropdownButton builds every one of its items up front — and lays them all
/// out in a hidden stack to size itself — so a seven-day editor with an open
/// and a close field per day built 7 × 2 × 48 = 672 rows (1,344 where the steps
/// are 15 minutes) before it could paint anything, each row an icon plus a
/// [CustomText], which runs a `.tr` lookup per build. Those screens took
/// seconds to appear, and paid the same cost again on every `setState`.
///
/// Here the closed field is whatever the caller draws — usually a label — and
/// the options are built by a `ListView.builder` for ONE field, only when it is
/// tapped, and only for the rows on screen.
///
/// Generic over the option type because the callers disagree on it: some hold
/// `TimeOfDay`, others a `"09:00"` string, others `"09:00 AM"`. [labelOf] turns
/// whichever it is into the row text.
///
/// Returns the chosen option, or null if the sheet was dismissed.
Future<T?> showOptionPickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required T? selected,
  required String Function(T) labelOf,
  IconData? leadingIcon = Icons.access_time_rounded,
  int visibleRows = 7,
}) {
  const rowHeight = 48.0;
  final selectedIndex = selected == null ? -1 : options.indexOf(selected);

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: SizeConfig.size12),
            CustomText(
              title,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
            ),
            SizedBox(height: SizeConfig.size8),
            Container(height: 1, color: AppColors.greyE5),
            SizedBox(
              // Capped so the sheet stays a list to scroll rather than a
              // full-screen takeover for a two-tap edit.
              height: rowHeight * visibleRows,
              child: ListView.builder(
                itemExtent: rowHeight,
                controller: ScrollController(
                  // Opens on the current value with three rows of context above
                  // it, so the common edit — a step or two either side — is
                  // under the thumb instead of twenty rows away.
                  initialScrollOffset:
                      selectedIndex <= 3 ? 0 : (selectedIndex - 3) * rowHeight,
                ),
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final option = options[i];
                  final isSelected = i == selectedIndex;
                  return InkWell(
                    onTap: () => Navigator.of(sheetContext).pop(option),
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding:
                          EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                      color: isSelected
                          ? AppColors.primaryColor.withValues(alpha: 0.08)
                          : null,
                      child: Row(
                        children: [
                          if (leadingIcon != null) ...[
                            Icon(
                              leadingIcon,
                              size: 16,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.secondaryTextColor,
                            ),
                            SizedBox(width: SizeConfig.size8),
                          ],
                          Expanded(
                            child: CustomText(
                              labelOf(option),
                              fontSize: 13.5,
                              fontWeight:
                                  isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.mainTextColor,
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_rounded,
                                size: 18, color: AppColors.primaryColor),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: SizeConfig.size8),
          ],
        ),
      );
    },
  );
}
