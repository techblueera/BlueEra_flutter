import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Prep-time picker used by `ACCEPT_ORDER` and `SET_PREP_ETA`.
///
/// Returns the chosen minutes, or null if the shop backed out. On Accept the
/// ETA is optional — a shop that just wants the order in should be able to tap
/// through — so [allowSkip] adds a "Just accept" escape that returns `-1`,
/// which the caller turns into an accept with no `prepEtaMinutes`.
Future<int?> showPrepEtaSheet(
  BuildContext context, {
  String title = 'How long will it take?',
  String confirmLabel = 'Accept order',
  int? initialMinutes,
  bool allowSkip = true,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _PrepEtaSheet(
      title: title,
      confirmLabel: confirmLabel,
      initialMinutes: initialMinutes,
      allowSkip: allowSkip,
    ),
  );
}

/// Returned by [showPrepEtaSheet] when the shop chose to accept without
/// committing to a time.
const int kPrepEtaSkipped = -1;

class _PrepEtaSheet extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final int? initialMinutes;
  final bool allowSkip;

  const _PrepEtaSheet({
    required this.title,
    required this.confirmLabel,
    this.initialMinutes,
    required this.allowSkip,
  });

  @override
  State<_PrepEtaSheet> createState() => _PrepEtaSheetState();
}

class _PrepEtaSheetState extends State<_PrepEtaSheet> {
  static const List<int> _presets = [10, 15, 20, 30, 45, 60];

  late int _minutes = widget.initialMinutes ?? 20;
  final TextEditingController _custom = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _submit() {
    final typed = _custom.text.trim();
    int value = _minutes;
    if (typed.isNotEmpty) {
      final parsed = int.tryParse(typed);
      if (parsed == null || parsed <= 0 || parsed > 600) {
        setState(() => _error = 'Enter a time between 1 and 600 minutes');
        return;
      }
      value = parsed;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomText(
                  widget.title,
                  fontSize: SizeConfig.size16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
                const SizedBox(height: 4),
                CustomText(
                  'The customer sees this as "ready in about …".',
                  fontSize: SizeConfig.size12,
                  color: AppColors.secondaryTextColor,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((m) {
                    final selected = _custom.text.trim().isEmpty && _minutes == m;
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(() {
                        _minutes = m;
                        _custom.clear();
                        _error = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryColor
                              : AppColors.primaryColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryColor
                                : AppColors.greyE5,
                          ),
                        ),
                        child: CustomText(
                          '$m min',
                          fontSize: SizeConfig.size13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : AppColors.mainTextColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _custom,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  onChanged: (_) => setState(() => _error = null),
                  decoration: InputDecoration(
                    hintText: 'Or type minutes',
                    isDense: true,
                    prefixIcon: const Icon(Icons.timer_outlined,
                        size: 20, color: AppColors.primaryColor),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.greyE5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.greyE5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primaryColor),
                    ),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: CustomText(
                      _error!,
                      fontSize: SizeConfig.size12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B9E4B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: CustomText(
                      widget.confirmLabel,
                      fontSize: SizeConfig.size15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (widget.allowSkip)
                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(kPrepEtaSkipped),
                      child: CustomText(
                        'Just accept, I\'ll say later',
                        fontSize: SizeConfig.size13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
