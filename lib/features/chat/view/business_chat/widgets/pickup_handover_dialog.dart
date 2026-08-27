import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The shop's handover dialog: 6-character uppercase pickup code, plus — for a
/// cash order — a "I have collected ₹X in cash" checkbox that is **checked by
/// default**. One tap then records both the goods leaving and the money
/// arriving, so a busy shop cannot forget half of it (guide §3.4).
///
/// Error handling is by `code`, never by message text:
///
/// | code | HTTP | what happens here |
/// |---|---|---|
/// | `PICKUP_CODE_MISMATCH` | 403 | field shakes, message shown, dialog stays open |
/// | `ACTION_NOT_AVAILABLE` | 409 | usually an unverified UPI payment — closes with "Confirm the payment first." |
/// | `CASH_NOT_COLLECTED`   | 409 | only reachable with the box unchecked; inline note |
///
/// Returns true when the handover succeeded.
Future<bool> showPickupHandoverDialog(
  BuildContext context, {
  required String orderId,
  String? service,
  bool isCashOrder = false,
  num? cashAmount,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PickupHandoverDialog(
      orderId: orderId,
      service: service,
      isCashOrder: isCashOrder,
      cashAmount: cashAmount,
    ),
  );
  return result ?? false;
}

class _PickupHandoverDialog extends StatefulWidget {
  final String orderId;
  final String? service;
  final bool isCashOrder;
  final num? cashAmount;

  const _PickupHandoverDialog({
    required this.orderId,
    this.service,
    required this.isCashOrder,
    this.cashAmount,
  });

  @override
  State<_PickupHandoverDialog> createState() => _PickupHandoverDialogState();
}

class _PickupHandoverDialogState extends State<_PickupHandoverDialog>
    with SingleTickerProviderStateMixin {
  static const int _codeLength = 6;

  final TextEditingController _code = TextEditingController();
  final FocusNode _focus = FocusNode();
  late final AnimationController _shakeController;
  bool _collectedCash = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_error != null) setState(() => _error = null);
    // Auto-submit the moment six characters are in — the shop is holding a bag
    // in the other hand.
    if (value.length == _codeLength && !_submitting) _submit();
  }

  Future<void> _submit() async {
    final code = _code.text.trim().toUpperCase();
    if (code.length != _codeLength) {
      _fail('Enter the customer\'s 6-character code.');
      return;
    }
    setState(() => _submitting = true);

    final controller = OrderLifecycleController.instance;
    final res = await controller.confirmHandover(
      widget.orderId,
      pickupCode: code,
      collectedCash: widget.isCashOrder ? _collectedCash : null,
      service: widget.service,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res.ok) {
      Navigator.of(context).pop(true);
      return;
    }

    switch (res.code) {
      case OrderErrorCode.pickupCodeMismatch:
        _fail('That code doesn\'t match this order.');
        break;
      case OrderErrorCode.cashNotCollected:
        _fail('Tick the cash box once you have the money.');
        break;
      case OrderErrorCode.actionNotAvailable:
      case OrderErrorCode.paymentConflict:
        // Almost always an unverified UPI payment. Close — the fix is on the
        // payment card, not in this dialog.
        Navigator.of(context).pop(false);
        break;
      case OrderErrorCode.network:
        _fail('Network problem. Tap Confirm to try again.');
        break;
      default:
        _fail(res.message?.isNotEmpty == true
            ? res.message!
            : 'Could not confirm the handover. Try again.');
    }
  }

  void _fail(String message) {
    setState(() {
      _error = message;
      _submitting = false;
    });
    // Shake plus a heavy haptic (guide §3.5). A shop counter is loud and the
    // phone is often not being looked at — the wrong code has to be felt.
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded,
                    color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    'Confirm handover',
                    fontSize: SizeConfig.size16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            CustomText(
              'Ask the customer for their 6-character pickup code.',
              fontSize: SizeConfig.size13,
              color: AppColors.secondaryTextColor,
            ),
            const SizedBox(height: 16),

            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                // Damped sine — three shakes that die out, rather than a jerk.
                final t = _shakeController.value;
                final dx = t == 0
                    ? 0.0
                    : 10 * (1 - t) * _sin(t * 3 * 2 * 3.1415926);
                return Transform.translate(
                    offset: Offset(dx, 0), child: child);
              },
              child: TextField(
                controller: _code,
                focusNode: _focus,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                maxLength: _codeLength,
                enabled: !_submitting,
                onChanged: _onChanged,
                onSubmitted: (_) => _submit(),
                style: TextStyle(
                  fontSize: SizeConfig.size26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 10,
                  fontFamily: 'monospace',
                  color: AppColors.mainTextColor,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  _UpperCaseFormatter(),
                ],
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '––––––',
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.greyE5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _error == null ? AppColors.greyE5 : Colors.red,
                      width: _error == null ? 1 : 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _error == null ? AppColors.primaryColor : Colors.red,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: CustomText(
                  _error!,
                  fontSize: SizeConfig.size12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),

            if (widget.isCashOrder) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _collectedCash,
                onChanged: _submitting
                    ? null
                    : (v) => setState(() => _collectedCash = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.primaryColor,
                dense: true,
                title: CustomText(
                  widget.cashAmount != null
                      ? 'I have collected ₹${_money(widget.cashAmount!)} in cash'
                      : 'I have collected the cash',
                  fontSize: SizeConfig.size13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mainTextColor,
                ),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _submitting ? null : () => Navigator.of(context).pop(false),
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
                          'Confirm',
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
    );
  }

  static String _money(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

  /// Small local sine so the file doesn't pull in dart:math for one call.
  static double _sin(double x) {
    // Taylor series is plenty for the shake amplitude; keep x in [-π, π].
    const twoPi = 6.283185307179586;
    x = x % twoPi;
    if (x > 3.141592653589793) x -= twoPi;
    final x2 = x * x;
    return x * (1 - x2 / 6 + x2 * x2 / 120 - x2 * x2 * x2 / 5040);
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
