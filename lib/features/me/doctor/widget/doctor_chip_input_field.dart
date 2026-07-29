import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The "text field + Add button" input used by Degree, Specialization and
/// Language Spoken on the About Me form.
///
/// Each tap of Add appends one entry; added entries render below as removable
/// chips, and the whole list is sent as a JSON array.
///
/// De-duplication is case-insensitive to mirror the server, which collapses
/// "English" and "english" into one entry — matching it here means the list
/// does not visibly change after saving.
class DoctorChipInputField extends StatefulWidget {
  final String title;
  final String hintText;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  /// The server rejects more than 30 entries per field.
  final int maxEntries;

  const DoctorChipInputField({
    super.key,
    required this.title,
    required this.hintText,
    required this.values,
    required this.onChanged,
    this.maxEntries = 30,
  });

  @override
  State<DoctorChipInputField> createState() => _DoctorChipInputFieldState();
}

class _DoctorChipInputFieldState extends State<DoctorChipInputField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;
    final existing = widget.values;
    if (existing.length >= widget.maxEntries) return;
    final alreadyThere =
        existing.any((e) => e.toLowerCase() == raw.toLowerCase());
    if (alreadyThere) {
      _controller.clear();
      return;
    }
    widget.onChanged([...existing, raw]);
    _controller.clear();
  }

  void _remove(String value) {
    widget.onChanged(widget.values.where((e) => e != value).toList());
  }

  @override
  Widget build(BuildContext context) {
    final atLimit = widget.values.length >= widget.maxEntries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          widget.title,
          fontSize: SizeConfig.medium,
          fontWeight: FontWeight.w500,
          color: AppColors.mainTextColor,
        ),
        SizedBox(height: SizeConfig.size8),
        // Field and Add button share a row and match in height, as in the
        // design: pale filled input, outlined blue "Add".
        //
        // IntrinsicHeight is required, not cosmetic: this row lives in a
        // scroll view, so its vertical constraint is unbounded, and a
        // horizontal Row with `stretch` would try to size children to
        // infinity ("RenderBox was not laid out"). IntrinsicHeight resolves
        // the row to the tallest child first, which keeps the button matched
        // to the field at any text scale — a hardcoded height would not.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !atLimit,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _add(),
                  style: TextStyle(
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      fontSize: SizeConfig.medium,
                      color: AppColors.grey99,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FB),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size14,
                      vertical: SizeConfig.size14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE3E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE3E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.primaryColor),
                    ),
                  ),
                ),
              ),
              SizedBox(width: SizeConfig.size10),
              InkWell(
                onTap: atLimit ? null : _add,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(horizontal: SizeConfig.size20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: atLimit
                          ? AppColors.primaryColor.withValues(alpha: 0.4)
                          : AppColors.primaryColor,
                    ),
                  ),
                  child: CustomText(
                    AppStrings.add.tr,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w600,
                    color: atLimit
                        ? AppColors.primaryColor.withValues(alpha: 0.4)
                        : AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.values.isNotEmpty) ...[
          SizedBox(height: SizeConfig.size10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.values
                .map(
                  (value) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size12,
                      vertical: SizeConfig.size6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: CustomText(
                            value,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: SizeConfig.size6),
                        InkWell(
                          onTap: () => _remove(value),
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
