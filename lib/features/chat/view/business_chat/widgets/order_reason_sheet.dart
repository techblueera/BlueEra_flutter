import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// What the user picked in [showOrderReasonSheet].
class OrderReasonChoice {
  final String reasonCode;
  final String? comment;

  const OrderReasonChoice({required this.reasonCode, this.comment});
}

/// Reason picker for cancel / reject / reject-payment.
///
/// **The list comes from `/actions` → `cancellationReasons[]`, already scoped
/// to the caller's role.** It is never hard-coded: a customer must not be able
/// to pick `ITEM_UNAVAILABLE`, and the server would refuse it with
/// `INVALID_REASON` anyway (guide §9).
///
/// When [reasons] is empty the sheet degrades to a free-text-only form and
/// submits [fallbackReasonCode] — better than blocking the user because the
/// list hadn't loaded, and the server still validates.
Future<OrderReasonChoice?> showOrderReasonSheet(
  BuildContext context, {
  required String title,
  required List<OrderCancellationReason> reasons,
  String confirmLabel = 'Confirm',
  String fallbackReasonCode = 'OTHER',
  String commentHint = 'Add a note (optional)',
  bool destructive = true,
}) {
  return showModalBottomSheet<OrderReasonChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _OrderReasonSheet(
      title: title,
      reasons: reasons,
      confirmLabel: confirmLabel,
      fallbackReasonCode: fallbackReasonCode,
      commentHint: commentHint,
      destructive: destructive,
    ),
  );
}

class _OrderReasonSheet extends StatefulWidget {
  final String title;
  final List<OrderCancellationReason> reasons;
  final String confirmLabel;
  final String fallbackReasonCode;
  final String commentHint;
  final bool destructive;

  const _OrderReasonSheet({
    required this.title,
    required this.reasons,
    required this.confirmLabel,
    required this.fallbackReasonCode,
    required this.commentHint,
    required this.destructive,
  });

  @override
  State<_OrderReasonSheet> createState() => _OrderReasonSheetState();
}

class _OrderReasonSheetState extends State<_OrderReasonSheet> {
  String? _selected;
  final TextEditingController _comment = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.reasons.length == 1) _selected = widget.reasons.first.code;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  OrderCancellationReason? get _selectedReason {
    for (final r in widget.reasons) {
      if (r.code == _selected) return r;
    }
    return null;
  }

  void _submit() {
    final hasList = widget.reasons.isNotEmpty;
    if (hasList && _selected == null) {
      setState(() => _error = 'Pick a reason to continue');
      return;
    }
    final reason = _selectedReason;
    final comment = _comment.text.trim();
    if (reason?.requiresComment == true && comment.isEmpty) {
      setState(() => _error = 'This reason needs a short note');
      return;
    }
    if (!hasList && comment.isEmpty) {
      setState(() => _error = 'Tell them why, in a few words');
      return;
    }
    Navigator.of(context).pop(OrderReasonChoice(
      reasonCode: _selected ?? widget.fallbackReasonCode,
      comment: comment.isEmpty ? null : comment,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.destructive ? Colors.red : AppColors.primaryColor;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        widget.title,
                        fontSize: SizeConfig.size16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.reasons.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: CustomText(
                            'Tell the other person what happened.',
                            fontSize: SizeConfig.size13,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ...widget.reasons.map(
                        (r) => RadioListTile<String>(
                          value: r.code,
                          groupValue: _selected,
                          activeColor: accent,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onChanged: (v) => setState(() {
                            _selected = v;
                            _error = null;
                          }),
                          title: CustomText(
                            r.label,
                            fontSize: SizeConfig.size14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.mainTextColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _comment,
                        maxLines: 3,
                        maxLength: 300,
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                        decoration: InputDecoration(
                          hintText: widget.commentHint,
                          counterText: '',
                          contentPadding: const EdgeInsets.all(12),
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
                            borderSide: BorderSide(color: accent),
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
