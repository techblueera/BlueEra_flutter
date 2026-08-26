import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/payment_qr_controller.dart';
import 'package:BlueEra/features/chat/auth/model/order_lifecycle_model.dart';
import 'package:BlueEra/features/chat/auth/model/payment_qr_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The customer's UPI payment sheet for an order.
///
/// Step 1 shows the shop's QR, its UPI id and **the exact amount due**
/// (`paymentSummary.amountDue`). Step 2 — behind "I have paid" — collects the
/// three things that make the claim checkable: **UTR number** (required),
/// **amount paid** (pre-filled with the amount due, editable) and a
/// **screenshot** (required). Then it posts
/// `POST /api/orders/:id/payment/submit`.
///
/// Every failure is branched on `code`, never on message text (guide §3.3):
///
/// | code | HTTP | UI |
/// |---|---|---|
/// | `UTR_ALREADY_USED` | 409 | red inline on the UTR field, **sheet stays open** |
/// | `TOO_MANY_PAYMENT_ATTEMPTS` | 429 | close, "Please contact the shop." |
/// | `ACTION_NOT_AVAILABLE` | 409 | close, refresh, "This order has changed…" |
/// | `UTR_REQUIRED` / `SCREENSHOT_REQUIRED` / `INVALID_AMOUNT` | 400 | inline field errors |
///
/// A successful response may still carry `warning` (e.g. paid less than due).
/// That is an **amber note on the card, not an error** — the submission
/// succeeded and the shop will see the same mismatch.
///
/// Returns true when the payment was submitted.
Future<bool> showOrderPaymentSheet(
  BuildContext context, {
  required String orderId,
  String? service,
  /// The shop's user id — used to look up their registered payment QR.
  String? payeeUserId,
  num? amountDue,
  String? shopName,
}) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) => _OrderPaymentSheet(
      orderId: orderId,
      service: service,
      payeeUserId: payeeUserId,
      amountDue: amountDue,
      shopName: shopName,
    ),
  );
  return ok ?? false;
}

class _OrderPaymentSheet extends StatefulWidget {
  final String orderId;
  final String? service;
  final String? payeeUserId;
  final num? amountDue;
  final String? shopName;

  const _OrderPaymentSheet({
    required this.orderId,
    this.service,
    this.payeeUserId,
    this.amountDue,
    this.shopName,
  });

  @override
  State<_OrderPaymentSheet> createState() => _OrderPaymentSheetState();
}

class _OrderPaymentSheetState extends State<_OrderPaymentSheet> {
  final PaymentQrController _qrController =
      getOrPut(() => PaymentQrController(), permanent: true);

  final TextEditingController _utr = TextEditingController();
  final TextEditingController _amount = TextEditingController();

  PaymentQr? _payeeQr;
  bool _loadingQr = false;
  bool _showForm = false;
  bool _submitting = false;

  File? _screenshot;
  String? _utrError;
  String? _amountError;
  String? _screenshotError;

  /// The order total, from `data.payment.amountDue` — the only place money
  /// lives (guide §2.3). `/actions` carries none, so [_hydrateAmount] pulls it
  /// from `/track` when the card has never seen an action response.
  num? get _amountDue {
    final summary =
        OrderLifecycleController.instance.stateOf(widget.orderId)?.paymentSummary;
    return summary?.amountDue ?? widget.amountDue;
  }

  @override
  void initState() {
    super.initState();
    final due = _amountDue;
    if (due != null && due > 0) _amount.text = _money(due);
    _hydrateAmount();
    _loadPayeeQr();
  }

  /// Never show the customer a blank or guessed figure to pay against.
  Future<void> _hydrateAmount() async {
    if (_amountDue != null) return;
    await OrderLifecycleController.instance
        .ensurePayment(widget.orderId, service: widget.service);
    if (!mounted) return;
    final due = _amountDue;
    // Don't stamp over a figure the customer has already edited.
    if (due != null && due > 0 && _amount.text.trim().isEmpty) {
      _amount.text = _money(due);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _utr.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadPayeeQr() async {
    final payee = widget.payeeUserId ?? '';
    if (payee.isEmpty) return;
    setState(() => _loadingQr = true);
    final qr = await _qrController.fetchPayeeQr(payee);
    if (!mounted) return;
    setState(() {
      _payeeQr = qr;
      _loadingQr = false;
    });
  }

  /// Standard scannable UPI payload. The amount is included so the payer's app
  /// pre-fills the exact figure — a mismatch is the single most common cause
  /// of a payment the shop then has to reject.
  String _upiPayString(String vpa) {
    final due = _amountDue;
    return Uri.parse('upi://pay').replace(queryParameters: {
      'pa': vpa,
      'pn': widget.shopName ?? 'Shop',
      'cu': 'INR',
      if (due != null && due > 0) 'am': _money(due),
      'tn': 'Order ${widget.orderId}',
    }).toString();
  }

  Future<void> _pickScreenshot() async {
    PhotoPickerService.showSourceChooserDialog(
      context,
      'Upload payment screenshot',
      onCamera: () {
        Navigator.pop(context);
        _pick(ImageSource.camera);
      },
      onGallery: () {
        Navigator.pop(context);
        _pick(ImageSource.gallery);
      },
    );
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null || !mounted) return;
    setState(() {
      _screenshot = File(picked.path);
      _screenshotError = null;
    });
  }

  Future<void> _submit() async {
    final utr = _utr.text.trim();
    final amountText = _amount.text.trim();
    final parsedAmount = num.tryParse(amountText);

    setState(() {
      _utrError = utr.isEmpty ? 'Enter the reference number from your bank app.' : null;
      _amountError = (parsedAmount == null || parsedAmount <= 0)
          ? 'Enter the amount you paid.'
          : null;
      _screenshotError =
          _screenshot == null ? 'Attach a screenshot of the payment.' : null;
    });
    if (_utrError != null || _amountError != null || _screenshotError != null) {
      return;
    }

    setState(() => _submitting = true);

    // Screenshot first — a failed upload must not create a half-submitted
    // payment the shop then sees with no proof attached.
    final uploaded = await _qrController.uploadImageToS3(_screenshot!);
    if (!mounted) return;
    if (uploaded?.publicUrl == null) {
      setState(() {
        _submitting = false;
        _screenshotError = 'Could not upload the screenshot. Try again.';
      });
      return;
    }

    final res = await OrderLifecycleController.instance.submitPayment(
      widget.orderId,
      utrNo: utr,
      amountPaid: parsedAmount!,
      screenshotUrl: uploaded!.publicUrl!,
      paymentQrId: _payeeQr?.id,
      upiId: _payeeQr?.upiId,
      service: widget.service,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res.ok) {
      // `warning` (e.g. "you entered ₹450 but the order is ₹500") is a
      // successful outcome with a caveat. Surface it, don't reverse anything.
      final warning = res.model?.warning ?? res.raw?['warning']?.toString();
      Navigator.of(context).pop(true);
      commonSnackBar(
        message: (warning != null && warning.isNotEmpty)
            ? warning
            : 'Payment sent to the shop for confirmation',
      );
      return;
    }

    switch (res.code) {
      case OrderErrorCode.utrAlreadyUsed:
        setState(() => _utrError =
            'This reference number has already been used. Check your bank app '
            'and enter the correct one.');
        break;
      case OrderErrorCode.utrRequired:
        setState(() => _utrError = 'A reference number is required.');
        break;
      case OrderErrorCode.invalidAmount:
        setState(() => _amountError = 'That amount is not valid for this order.');
        break;
      case OrderErrorCode.screenshotRequired:
        setState(() =>
            _screenshotError = 'A screenshot of the payment is required.');
        break;
      case OrderErrorCode.tooManyPaymentAttempts:
        Navigator.of(context).pop(false);
        commonSnackBar(message: 'Please contact the shop.');
        break;
      case OrderErrorCode.actionNotAvailable:
      case OrderErrorCode.paymentConflict:
      case OrderErrorCode.orderTerminal:
        // The controller already refreshed from /actions.
        Navigator.of(context).pop(false);
        commonSnackBar(
            message: 'This order has changed — please check again.');
        break;
      case OrderErrorCode.network:
        setState(() => _screenshotError =
            'Network problem. Tap "I have paid" to try again — it is safe to '
            'retry.');
        break;
      default:
        setState(() => _utrError = res.message?.isNotEmpty == true
            ? res.message!
            : 'Could not submit the payment. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                _amountDueBlock(),
                const SizedBox(height: 16),
                if (!_showForm) ..._qrStep() else ..._formStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 0: the amount, always visible ────────────────────────────────

  Widget _amountDueBlock() {
    final due = _amountDue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  'Amount due',
                  fontSize: SizeConfig.size12,
                  color: AppColors.secondaryTextColor,
                ),
                if ((widget.shopName ?? '').isNotEmpty)
                  CustomText(
                    'to ${widget.shopName}',
                    fontSize: SizeConfig.size12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
              ],
            ),
          ),
          CustomText(
            due == null ? '—' : '₹${_money(due)}',
            fontSize: SizeConfig.size22,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryColor,
          ),
        ],
      ),
    );
  }

  // ── Step 1: scan and pay ───────────────────────────────────────────────

  List<Widget> _qrStep() {
    final vpa = _payeeQr?.upiId;
    final qrImage = _payeeQr?.qrImageUrl;
    final qrSize = SizeConfig.screenWidth * 0.44;

    return [
      if (_loadingQr)
        SizedBox(
          height: qrSize + 40,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          ),
        )
      else if (vpa == null || vpa.isEmpty)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomText(
            'This shop hasn\'t added a UPI id yet. Ask them for their UPI '
            'details, pay, then record it below.',
            fontSize: SizeConfig.size13,
            color: AppColors.mainTextColor,
          ),
        )
      else ...[
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.greyE5, width: 1.5),
            ),
            // Prefer the shop's own uploaded QR image; fall back to a generated
            // one from their VPA so payment is never blocked on an image.
            child: (qrImage != null && qrImage.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: qrImage,
                    width: qrSize,
                    height: qrSize,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) => QrImageView(
                      data: _upiPayString(vpa),
                      size: qrSize,
                      version: QrVersions.auto,
                      gapless: true,
                    ),
                  )
                : QrImageView(
                    data: _upiPayString(vpa),
                    size: qrSize,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    gapless: true,
                  ),
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Clipboard.setData(ClipboardData(text: vpa));
            commonSnackBar(message: 'UPI ID copied');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    vpa,
                    fontSize: SizeConfig.size14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.copy_rounded,
                    size: 20, color: AppColors.primaryColor),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 18),
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () => setState(() => _showForm = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: CustomText(
            'I have paid',
            fontSize: SizeConfig.size15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 8),
      CustomText(
        'Pay first, then record the details so the shop can confirm it.',
        fontSize: SizeConfig.size11,
        color: AppColors.secondaryTextColor,
        textAlign: TextAlign.center,
      ),
    ];
  }

  // ── Step 2: record the payment ─────────────────────────────────────────

  List<Widget> _formStep() {
    return [
      Row(
        children: [
          InkWell(
            onTap: _submitting ? null : () => setState(() => _showForm = false),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.arrow_back, size: 20),
            ),
          ),
          const SizedBox(width: 6),
          CustomText(
            'Record your payment',
            fontSize: SizeConfig.size16,
            fontWeight: FontWeight.w700,
            color: AppColors.mainTextColor,
          ),
        ],
      ),
      const SizedBox(height: 14),
      TextField(
        controller: _utr,
        enabled: !_submitting,
        textCapitalization: TextCapitalization.characters,
        onChanged: (_) {
          if (_utrError != null) setState(() => _utrError = null);
        },
        decoration: _decoration(
          label: 'UTR / reference number',
          hint: 'From your UPI app\'s transaction details',
          error: _utrError,
          icon: Icons.receipt_long_outlined,
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _amount,
        enabled: !_submitting,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d{0,7}(\.\d{0,2})?')),
        ],
        onChanged: (_) {
          if (_amountError != null) setState(() => _amountError = null);
        },
        decoration: _decoration(
          label: 'Amount paid (₹)',
          error: _amountError,
          icon: Icons.currency_rupee_rounded,
        ),
      ),
      const SizedBox(height: 12),
      _screenshotPicker(),
      const SizedBox(height: 18),
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : CustomText(
                  'Send to the shop',
                  fontSize: SizeConfig.size15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
        ),
      ),
      const SizedBox(height: 10),
      CustomText(
        'The shop checks their bank app and confirms. You\'ll see it here.',
        fontSize: SizeConfig.size11,
        color: AppColors.secondaryTextColor,
        textAlign: TextAlign.center,
      ),
    ];
  }

  Widget _screenshotPicker() {
    final file = _screenshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: _submitting ? null : _pickScreenshot,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _screenshotError == null
                    ? AppColors.greyE5
                    : Colors.red,
              ),
            ),
            child: Row(
              children: [
                if (file != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(file,
                        width: 52, height: 52, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.primaryColor),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomText(
                    file == null
                        ? 'Attach payment screenshot'
                        : 'Screenshot attached — tap to change',
                    fontSize: SizeConfig.size13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.grayText),
              ],
            ),
          ),
        ),
        if (_screenshotError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: CustomText(
              _screenshotError!,
              fontSize: SizeConfig.size12,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
      ],
    );
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    String? error,
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      errorMaxLines: 3,
      isDense: true,
      prefixIcon:
          icon == null ? null : Icon(icon, size: 20, color: AppColors.primaryColor),
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
    );
  }

  static String _money(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}
