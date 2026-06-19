import 'dart:io';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/upi_payment_controller.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Opens the payment bottom sheet showing a QR code with Download and
/// Make-Payment actions. [data] is encoded into the QR; pass an order id for a
/// unique-looking code, otherwise a placeholder is used.
///
/// When [userId] (the conversation person's id) is provided, the sheet calls
/// `wallet-service/wallet/user/{userId}/upi` on open and logs the response so
/// the QR can be built from the person's real UPI details.
///
/// [payeeVpa] / [payeeName] / [amount] are placeholder merchant values used
/// when building the QR if the backend hasn't exposed the real ones.
///
/// [conversationId] is required for the "Upload Screenshot" action — the picked
/// payment screenshot is sent as an image message into that conversation.
Future<void> showPaymentQrBottomSheet(
  BuildContext context, {
  String? data,
  String? userId,
  String? conversationId,
  String payeeVpa = 'merchant@upi',
  String payeeName = 'My Business',
  String amount = '100.00',
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      // Lift the whole sheet above the keyboard so the amount field stays
      // visible while typing.
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          // Scrollable so the tall QR content never overflows once the
          // keyboard shrinks the available height.
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PaymentQrPanel(
                    qrData: data,
                    userId: userId,
                    conversationId: conversationId,
                    payeeVpa: payeeVpa,
                    payeeName: payeeName,
                    amount: amount,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The reusable payment-details panel: payee QR code, copyable UPI id +
/// linked mobile number, a Download-QR action and an Upload-screenshot
/// (record payment) action. Used both inside [showPaymentQrBottomSheet] and
/// embedded directly under the chat's Payment tab.
///
/// Set [embedded] when rendering inline (e.g. inside a tab) so the
/// record-payment flow does NOT pop a route on completion — there's no sheet
/// to dismiss in that case.
class PaymentQrPanel extends StatefulWidget {
  final String? qrData;
  final String? userId;
  final String? conversationId;
  final String payeeVpa;
  final String payeeName;
  final String amount;
  final bool embedded;

  const PaymentQrPanel({
    super.key,
    this.qrData,
    this.userId,
    this.conversationId,
    this.payeeVpa = 'merchant@upi',
    this.payeeName = 'My Business',
    this.amount = '0',
    this.embedded = false,
  });

  @override
  State<PaymentQrPanel> createState() => _PaymentQrPanelState();
}

class _PaymentQrPanelState extends State<PaymentQrPanel>
    with SingleTickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();
  final RxBool _isSaving = false.obs;
  final UpiPaymentController _upiController = UpiPaymentController();

  // The chat controller owns the screenshot send (see
  // image-is-payment-flutter-integration-guide.md).
  final ChatViewController _chatController = Get.find<ChatViewController>();
  final TextEditingController _amountCtrl = TextEditingController();

  // Drives the blinking copy button.
  late final AnimationController _blinkController;
  late final Animation<double> _blink;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _blink = Tween<double>(begin: 1.0, end: 0.35).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );
    // Fetch the conversation person's UPI details so the QR reflects the
    // real payee. Response is logged inside the controller.
    if ((widget.userId ?? '').isNotEmpty) {
      _upiController.fetchUserUpi(widget.userId!);
    }
    // Prefill the amount from the caller (e.g. order total); the payer can edit.
    final initialAmount = num.tryParse(widget.amount);
    if (initialAmount != null && initialAmount > 0) {
      _amountCtrl.text = widget.amount;
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  /// The payee UPI id (VPA) to render/pay to. Prefers the fetched value;
  /// falls back to an explicitly passed [payeeVpa] only when there is no
  /// [userId] to look up (legacy callers).
  String? get _effectiveVpa {
    final fetched = _upiController.upiId.value;
    if (fetched != null && fetched.isNotEmpty) return fetched;
    if ((widget.userId ?? '').isEmpty) return widget.payeeVpa;
    return null;
  }

  /// Note shown to the UPI app for the transaction.
  String get _note => (widget.qrData != null && widget.qrData!.isNotEmpty)
      ? 'Order ${widget.qrData}'
      : 'Payment';

  /// Standard scannable UPI payload, e.g.
  /// `upi://pay?pa=himanshu@oksbi&pn=...&cu=INR`. Amount is intentionally
  /// omitted so the scanning app asks the payer for it.
  String _upiPayString(String vpa) {
    return Uri.parse('upi://pay').replace(queryParameters: {
      'pa': vpa,
      'pn': widget.payeeName,
      'cu': 'INR',
      if (widget.qrData != null && widget.qrData!.isNotEmpty)
        'tn': _note,
    }).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                'Scan to Pay',
                fontSize: SizeConfig.size16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
              const SizedBox(height: 4),
              CustomText(
                'Scan this QR code to complete your payment',
                fontSize: SizeConfig.size12,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // QR (wrapped in RepaintBoundary so it can be captured).
              // While the conversation person's UPI is loading we show a
              // spinner in the same footprint so the sheet doesn't jump.
              Obx(() {
                final qrSize = SizeConfig.screenWidth * 0.42;
                if (_upiController.isLoading.value) {
                  return SizedBox(
                    height: qrSize + 40,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    ),
                  );
                }

                final vpa = _effectiveVpa;
                if (vpa == null || vpa.isEmpty) {
                  return SizedBox(
                    height: qrSize + 40,
                    child: Center(
                      child: CustomText(
                        _upiController.errorMessage.value ??
                            'UPI ID not available',
                        fontSize: SizeConfig.size13,
                        color: AppColors.secondaryTextColor,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    RepaintBoundary(
                      key: _repaintKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.greyE5, width: 1.5),
                        ),
                        child: QrImageView(
                          data: _upiPayString(vpa),
                          version: QrVersions.auto,
                          size: qrSize,
                          errorCorrectionLevel: QrErrorCorrectLevel.H,
                          gapless: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Show the UPI id and (when available) the linked mobile
                    // number side by side on a single line.
                    Builder(builder: (_) {
                      final mobile = _upiController.mobileNumber.value ?? '';
                      if (mobile.isEmpty) {
                        return _copyableBox(vpa, copiedLabel: 'UPI ID copied');
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: _copyableBox(vpa,
                                copiedLabel: 'UPI ID copied'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _copyableBox(
                              mobile,
                              copiedLabel: 'Mobile number copied',
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                );
              }),
              const SizedBox(height: 20),

              // ── Upload payment screenshot (guide: is_payment image msg) ────
              // After paying via their UPI app, the payer optionally notes the
              // amount, then uploads the screenshot which is sent into the chat
              // as a payment message awaiting the owner's approval.
              _paymentField(
                controller: _amountCtrl,
                hint: 'Amount paid (₹)',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                icon: Icons.currency_rupee_rounded,
                // Only digits + a single decimal point, max 6 digits before
                // the decimal and up to 2 after (e.g. 999999.99).
                inputFormatters: [_AmountInputFormatter()],
              ),
              const SizedBox(height: 20),

              // Download QR / Upload-screenshot actions
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _actionButton(
                          icon: Icons.download_rounded,
                          label: 'Download',
                          isBusy: _isSaving.value,
                          filled: false,
                          onTap: _saveQrToGallery,
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => _actionButton(
                          icon: Icons.upload_file_rounded,
                          label: 'Upload Screenshot',
                          isBusy: _chatController.isSending.value,
                          filled: true,
                          onTap: _recordPayment,
                        )),
                  ),
                ],
              ),
            ],
    );
  }

  /// A bordered text field used for the amount input.
  Widget _paymentField({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(
        fontSize: SizeConfig.size14,
        fontWeight: FontWeight.w600,
        color: AppColors.mainTextColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppColors.primaryColor),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.greyE5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.greyE5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryColor),
        ),
      ),
    );
  }

  /// A value (UPI id or mobile number) shown inside a bordered box with a
  /// prominent, blinking blue copy button. Tapping anywhere on the box copies
  /// [value] to the clipboard and shows [copiedLabel] as a confirmation.
  Widget _copyableBox(String value, {required String copiedLabel}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _copyValue(value, copiedLabel),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: CustomText(
                  value,
                  fontSize: SizeConfig.size14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mainTextColor,
                ),
              ),
              const SizedBox(width: 10),
              FadeTransition(
                opacity: _blink,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.copy_rounded,
                    size: 22,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyValue(String value, String copiedLabel) async {
    await Clipboard.setData(ClipboardData(text: value));
    commonSnackBar(message: copiedLabel);
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool isBusy,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 48,
      child: filled
          ? ElevatedButton.icon(
              onPressed: isBusy ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(icon, size: 20, color: Colors.white),
              label: CustomText(
                label,
                fontSize: SizeConfig.size14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            )
          : OutlinedButton.icon(
              onPressed: isBusy ? null : onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primaryColor),
                    )
                  : Icon(icon, size: 20, color: AppColors.primaryColor),
              label: CustomText(
                label,
                fontSize: SizeConfig.size14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            ),
    );
  }

  Future<Uint8List?> _captureQrImage() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing payment QR: $e');
      return null;
    }
  }

  Future<File?> _writeQrToTempFile() async {
    final pngBytes = await _captureQrImage();
    if (pngBytes == null) return null;
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/payment_qr_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(pngBytes);
    return file;
  }

  Future<bool> _ensureGalleryAccess() async {
    final hasAccess = await Gal.hasAccess(toAlbum: true);
    if (hasAccess) return true;
    final granted = await Gal.requestAccess(toAlbum: true);
    if (granted) return true;
    _showPermissionSettingsDialog();
    return false;
  }

  void _showPermissionSettingsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: CustomText(
          AppStrings.permissionRequired.tr,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.mainTextColor,
        ),
        content: CustomText(
          Platform.isIOS
              ? AppStrings.photoLibraryAccessNeeded.tr
              : AppStrings.storagePermissionNeeded.tr,
          fontSize: 14,
          color: AppColors.secondaryTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: CustomText(
              AppStrings.cancel.tr,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await openAppSettings();
            },
            child: CustomText(
              AppStrings.openSettings.tr,
              fontSize: 14,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveQrToGallery() async {
    if (_isSaving.value) return;
    _isSaving.value = true;
    File? tempFile;
    try {
      final hasAccess = await _ensureGalleryAccess();
      if (!hasAccess) return;

      tempFile = await _writeQrToTempFile();
      if (tempFile == null) {
        commonSnackBar(message: AppStrings.failedToCaptureQrCode.tr);
        return;
      }

      await Gal.putImage(tempFile.path, album: 'BlueEra');
      commonSnackBar(message: AppStrings.qrCodeSavedToGallery.tr);
    } catch (e) {
      debugPrint('Error saving payment QR: $e');
      commonSnackBar(message: AppStrings.failedToSaveQrCode.tr);
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        await tempFile.delete();
      }
      _isSaving.value = false;
    }
  }

  /// Lets the payer pick a payment screenshot which is then sent into the chat
  /// as an `is_payment` image message awaiting the owner's approval (see
  /// image-is-payment-flutter-integration-guide.md).
  Future<void> _recordPayment() async {
    if ((widget.conversationId ?? '').isEmpty) {
      commonSnackBar(message: 'Unable to send payment screenshot');
      return;
    }

    // Amount is required before uploading the screenshot.
    final amount = _amountCtrl.text.trim();
    if (amount.isEmpty) {
      commonSnackBar(message: 'Enter the amount paid');
      return;
    }
    final parsed = num.tryParse(amount);
    if (parsed == null || parsed <= 0) {
      commonSnackBar(message: 'Enter a valid amount');
      return;
    }

    if (!mounted) return;
    PhotoPickerService.showSourceChooserDialog(
      context,
      'Upload Payment Screenshot',
      onCamera: () {
        Navigator.pop(context); // close the chooser
        _pickAndSend(ImageSource.camera);
      },
      onGallery: () {
        Navigator.pop(context); // close the chooser
        _pickAndSend(ImageSource.gallery);
      },
    );
  }

  /// Picks the screenshot from [source] and sends it as a payment message. The
  /// QR sheet closes as soon as a file is picked; [ChatViewController.
  /// sendPaymentScreenshot] handles the multipart upload, the `is_payment`
  /// flag, and rendering the awaiting-approval bubble in the chat.
  Future<void> _pickAndSend(ImageSource source) async {
    // The amount (validated in _recordPayment) becomes the screenshot's caption
    // so the owner sees what was paid. Captured before any pop disposes the
    // controller.
    final amount = _amountCtrl.text.trim();
    final note = 'Payment of ₹$amount';

    final XFile? picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    if (!mounted) return;
    // Close the QR sheet only when shown as a modal. Embedded under the
    // Payment tab there is no sheet route to pop.
    if (!widget.embedded) Navigator.pop(context);

    await _chatController.sendPaymentScreenshot(
      screenshot: File(picked.path),
      conversationId: widget.conversationId,
      note: note,
    );
  }
}

/// Restricts an amount field to numbers with at most one decimal point:
/// up to 6 digits before the decimal and up to 2 digits after
/// (e.g. `999999.99`). Rejects any edit that doesn't match.
class _AmountInputFormatter extends TextInputFormatter {
  static final RegExp _pattern = RegExp(r'^\d{0,6}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    return _pattern.hasMatch(text) ? newValue : oldValue;
  }
}
