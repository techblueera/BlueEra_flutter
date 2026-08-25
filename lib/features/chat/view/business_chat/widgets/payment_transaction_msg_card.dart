import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/view/business_chat/widgets/order_reason_sheet.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Renders a `payment_transaction` chat message — a payment recorded against a
/// Payment QR (UTR + amount + screenshot).
///
/// **The wording is the point.** A payment the payee has not yet confirmed is
/// a *claim*, not money in the bank. The card therefore never says "Payment
/// Received" for a `pending` transaction — the payer's side reads "Payment
/// sent · awaiting confirmation" and the payee's reads "Says they paid". That
/// single choice is what stops a shop handing over goods on a screenshot
/// (guide §3.3).
///
/// For the payee it also puts **amount paid next to amount due**, amber when
/// they differ, and offers the two decisions — because the whole point is that
/// the shop checks their own bank app before tapping, and the comparison has
/// to be effortless.
class PaymentTransactionMsgCard extends StatefulWidget {
  final Messages message;
  final String time;
  final bool isReceive;

  const PaymentTransactionMsgCard({
    super.key,
    required this.message,
    required this.time,
    required this.isReceive,
  });

  @override
  State<PaymentTransactionMsgCard> createState() =>
      _PaymentTransactionMsgCardState();
}

class _PaymentTransactionMsgCardState extends State<PaymentTransactionMsgCard> {
  bool _acting = false;

  Messages get message => widget.message;
  String get time => widget.time;

  /// True when the current user is the PAYEE — the one who has to decide.
  bool get isReceive => widget.isReceive;

  String? get _screenshotUrl {
    final list = message.url;
    if (list == null || list.isEmpty) return null;
    return list.first.url;
  }

  /// `pending` until the payee decides. An absent status is treated as pending
  /// — never as settled.
  String get _status =>
      (message.metadata?.paymentTxnStatus ?? 'pending').toLowerCase();

  bool get _isPending => _status == 'pending' || _status == 'submitted';
  bool get _isVerified => _status == 'verified' || _status == 'approved';
  bool get _isRejected => _status == 'rejected';

  /// Order this payment belongs to, when it was recorded against one.
  String get _orderRef => message.metadata?.paymentOrderRef ?? '';

  num? get _expected => message.metadata?.paymentExpectedAmount;

  bool get _mismatch {
    final flagged = message.metadata?.paymentAmountMismatch;
    if (flagged != null) return flagged;
    final due = _expected;
    final paid = message.metadata?.amount;
    if (due == null || paid == null) return false;
    return (due - paid).abs() > 0.009;
  }

  /// The payee confirms the money arrived. For an order-linked payment this
  /// goes through the ORDER service, which is what advances the order state
  /// machine — the bare transaction endpoint would leave the order stuck.
  Future<void> _verify() async {
    if (_orderRef.isEmpty) {
      commonSnackBar(message: 'This payment is not linked to an order.');
      return;
    }
    setState(() => _acting = true);
    final res = await OrderLifecycleController.instance.verifyPayment(
      _orderRef,
      amountReceived: message.metadata?.amount,
      service: message.metadata?.paymentOrderService,
    );
    if (!mounted) return;
    setState(() {
      _acting = false;
      if (res.ok) message.metadata?.paymentTxnStatus = 'verified';
    });
  }

  Future<void> _reject() async {
    if (_orderRef.isEmpty) {
      commonSnackBar(message: 'This payment is not linked to an order.');
      return;
    }
    final choice = await showOrderReasonSheet(
      context,
      title: 'Why is the payment not confirmed?',
      reasons: const [],
      confirmLabel: 'Not received',
      commentHint: 'e.g. Nothing has reached my account yet',
    );
    if (choice == null || !mounted) return;

    setState(() => _acting = true);
    final res = await OrderLifecycleController.instance.rejectPayment(
      _orderRef,
      reason: choice.comment ?? choice.reasonCode,
      service: message.metadata?.paymentOrderService,
    );
    if (!mounted) return;
    setState(() {
      _acting = false;
      if (res.ok) message.metadata?.paymentTxnStatus = 'rejected';
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatThemeController = Get.find<ChatThemeController>();
    final meta = message.metadata;
    final amount = meta?.amount;
    final utr = meta?.utrNo ?? '';
    final screenshot = _screenshotUrl;

    final bgColor = isReceive
        ? chatThemeController.receiveMessageBgColor.value
        : chatThemeController.myMessageBgColor.value;
    final onColor = isReceive ? AppColors.mainTextColor : Colors.white;
    final subColor = isReceive ? AppColors.grayText : Colors.white70;

    return Align(
      alignment: isReceive ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: SizeConfig.screenWidth * 0.66,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomRight: Radius.circular(isReceive ? 12 : 0),
            bottomLeft: Radius.circular(isReceive ? 0 : 12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon + title + amount
            Padding(
              padding:
                  const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 6),
              child: Row(
                children: [
                  Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      color: (isReceive ? AppColors.primaryColor : Colors.white)
                          .withValues(alpha: isReceive ? 0.12 : 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPending
                          ? Icons.pending_actions
                          : _isRejected
                              ? Icons.error_outline
                              : (isReceive
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded),
                      size: 18,
                      color: isReceive ? AppColors.primaryColor : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomText(
                      _title,
                      fontWeight: FontWeight.w700,
                      fontSize: SizeConfig.size14,
                      color: onColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (amount != null)
                    CustomText(
                      '₹${_formatAmount(amount)}',
                      fontWeight: FontWeight.w800,
                      fontSize: SizeConfig.size16,
                      color: onColor,
                    ),
                ],
              ),
            ),
            // UTR
            if (utr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    CustomText(
                      'UTR: ',
                      fontSize: SizeConfig.size12,
                      color: subColor,
                      fontWeight: FontWeight.w500,
                    ),
                    Expanded(
                      child: CustomText(
                        utr,
                        fontSize: SizeConfig.size12,
                        color: subColor,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // Amount paid vs amount due, side by side. Amber when they
            // differ — the shop must see the discrepancy before deciding, not
            // discover it in their bank app afterwards.
            if (_expected != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: (_mismatch ? const Color(0xFFE9A100) : onColor)
                        .withValues(alpha: isReceive ? 0.10 : 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _amountCell('They paid', amount, onColor,
                            subColor),
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: subColor.withValues(alpha: 0.4),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      Expanded(
                        child: _amountCell(
                            'Order total', _expected, onColor, subColor),
                      ),
                    ],
                  ),
                ),
              ),
            if (_mismatch)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: CustomText(
                  'The amount does not match the order total.',
                  fontSize: SizeConfig.size11,
                  fontWeight: FontWeight.w600,
                  color: isReceive ? const Color(0xFFA96A00) : Colors.white,
                ),
              ),

            // Status line — never let a pending claim read as settled.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: CustomText(
                _statusLine,
                fontSize: SizeConfig.size11,
                fontWeight: FontWeight.w600,
                color: subColor,
                maxLines: 2,
              ),
            ),

            const SizedBox(height: 8),
            // Screenshot preview
            if (screenshot != null && screenshot.isNotEmpty)
              GestureDetector(
                onTap: () => _showScreenshot(context, screenshot),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  constraints: const BoxConstraints(maxHeight: 180),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black12,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    screenshot,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 120,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryColor),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 120,
                      child: Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            // The payee's two decisions. Shown only while the payment is
            // pending AND it belongs to an order — verifying advances the
            // order state machine, so a payment with no order has nothing to
            // advance.
            if (isReceive && _isPending && _orderRef.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton(
                          onPressed: _acting ? null : _reject,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: CustomText(
                            'Not received',
                            fontSize: SizeConfig.size12,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: _acting ? null : _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B9E4B),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                          child: _acting
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : CustomText(
                                  'Payment received',
                                  fontSize: SizeConfig.size12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Time + read info
            Padding(
              padding: const EdgeInsets.only(right: 10, top: 4, bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  timeAndReadInfoWidget(
                    message: message,
                    isMyMessage: message.myMessage ?? false,
                    time: time,
                    timeColor: isReceive ? Colors.black45 : Colors.white70,
                    indicateColor:
                        message.messageRead == 1 ? Colors.blue : Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The headline. A `pending` transaction is a claim from the payer, and the
  /// payee's side must say exactly that.
  String get _title {
    if (_isRejected) return 'Payment not confirmed';
    if (_isVerified) return isReceive ? 'Payment received' : 'Payment verified';
    return isReceive ? 'Says they paid' : 'Payment sent';
  }

  String get _statusLine {
    if (_isRejected) {
      return isReceive
          ? 'You said this payment did not arrive.'
          : 'The shop could not confirm this payment.';
    }
    if (_isVerified) {
      return isReceive ? 'Confirmed by you' : 'Confirmed by the shop ✓';
    }
    return isReceive
        ? 'Check your bank app, then confirm or refuse.'
        : 'Waiting for the shop to confirm your payment';
  }

  Widget _amountCell(String label, num? value, Color onColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label, fontSize: SizeConfig.size10, color: subColor),
        CustomText(
          value == null ? '—' : '₹${_formatAmount(value)}',
          fontSize: SizeConfig.size14,
          fontWeight: FontWeight.w800,
          color: onColor,
        ),
      ],
    );
  }

  /// Trims a trailing `.0` so whole rupees read cleanly (₹499 not ₹499.0).
  String _formatAmount(num value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  void _showScreenshot(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                radius: 16,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
