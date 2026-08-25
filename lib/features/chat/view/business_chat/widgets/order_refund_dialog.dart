import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The shop's "I sent the refund" dialog.
///
/// With direct UPI the customer paid the **shop's own VPA**. The platform
/// never held a paisa of it, has no balance to reverse and no gateway to call.
/// So this dialog collects the shop's own transfer reference — and submitting
/// it is a *claim*, exactly like the customer's original screenshot was a
/// claim. It does **not** close the refund; only the customer's
/// `CONFIRM_REFUND_RECEIVED` does (guide §3.6.1).
///
/// Returns true when the claim was recorded.
Future<bool> showRefundSentDialog(
  BuildContext context, {
  required String orderId,
  String? service,
  num? amount,
  String? customerUpiId,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _RefundSentDialog(
      orderId: orderId,
      service: service,
      amount: amount,
      customerUpiId: customerUpiId,
    ),
  );
  return ok ?? false;
}

class _RefundSentDialog extends StatefulWidget {
  final String orderId;
  final String? service;
  final num? amount;
  final String? customerUpiId;

  const _RefundSentDialog({
    required this.orderId,
    this.service,
    this.amount,
    this.customerUpiId,
  });

  @override
  State<_RefundSentDialog> createState() => _RefundSentDialogState();
}

class _RefundSentDialogState extends State<_RefundSentDialog> {
  final TextEditingController _reference = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _submitting = false;
  String? _referenceError;

  @override
  void dispose() {
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ref = _reference.text.trim();
    if (ref.isEmpty) {
      setState(() => _referenceError =
          'Enter the reference number of the transfer you sent.');
      return;
    }
    setState(() {
      _submitting = true;
      _referenceError = null;
    });

    final res = await OrderLifecycleController.instance.markRefundSent(
      widget.orderId,
      refundReference: ref,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      service: widget.service,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res.ok) {
      Navigator.of(context).pop(true);
      return;
    }
    if (res.code == OrderErrorCode.refundReferenceRequired) {
      setState(() => _referenceError = 'A valid reference number is required.');
      return;
    }
    if (res.isStaleState) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _referenceError = res.message?.isNotEmpty == true
        ? res.message!
        : 'Could not record the refund. Try again.');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.reply_rounded, color: AppColors.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      'Record the refund you sent',
                      fontSize: SizeConfig.size16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              CustomText(
                'The customer confirms when the money reaches them. Until then '
                'this order stays open.',
                fontSize: SizeConfig.size12,
                color: AppColors.secondaryTextColor,
              ),
              const SizedBox(height: 16),

              // Amount — read-only. It is what the customer actually paid.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CustomText(
                      'Amount to return',
                      fontSize: SizeConfig.size13,
                      color: AppColors.secondaryTextColor,
                    ),
                    const Spacer(),
                    CustomText(
                      widget.amount == null
                          ? '—'
                          : '₹${_money(widget.amount!)}',
                      fontSize: SizeConfig.size16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                    ),
                  ],
                ),
              ),

              if ((widget.customerUpiId ?? '').isNotEmpty) ...[
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: widget.customerUpiId!));
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CustomText(
                          'Send to',
                          fontSize: SizeConfig.size13,
                          color: AppColors.secondaryTextColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomText(
                            widget.customerUpiId!,
                            fontSize: SizeConfig.size14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mainTextColor,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.copy_rounded,
                            size: 18, color: AppColors.primaryColor),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              TextField(
                controller: _reference,
                enabled: !_submitting,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) {
                  if (_referenceError != null) {
                    setState(() => _referenceError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'UTR / reference of your transfer',
                  isDense: true,
                  errorText: _referenceError,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                enabled: !_submitting,
                maxLines: 2,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Note for the customer (optional)',
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
                    borderSide: const BorderSide(color: AppColors.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: CustomText(
                      'Cancel',
                      fontSize: SizeConfig.size14,
                      color: AppColors.secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : CustomText(
                            'I sent the refund',
                            fontSize: SizeConfig.size14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _money(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}
