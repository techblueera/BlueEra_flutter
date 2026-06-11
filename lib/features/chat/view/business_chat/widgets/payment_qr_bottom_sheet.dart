import 'dart:io';
import 'dart:ui' as ui;

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/chat_media_compression_service.dart';
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
    builder: (_) => _PaymentQrSheet(
      qrData: data,
      userId: userId,
      conversationId: conversationId,
      payeeVpa: payeeVpa,
      payeeName: payeeName,
      amount: amount,
    ),
  );
}

class _PaymentQrSheet extends StatefulWidget {
  final String? qrData;
  final String? userId;
  final String? conversationId;
  final String payeeVpa;
  final String payeeName;
  final String amount;

  const _PaymentQrSheet({
    this.qrData,
    this.userId,
    this.conversationId,
    required this.payeeVpa,
    required this.payeeName,
    required this.amount,
  });

  @override
  State<_PaymentQrSheet> createState() => _PaymentQrSheetState();
}

class _PaymentQrSheetState extends State<_PaymentQrSheet>
    with SingleTickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();
  final RxBool _isSaving = false.obs;
  final UpiPaymentController _upiController = UpiPaymentController();

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
  }

  @override
  void dispose() {
    _blinkController.dispose();
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
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
                final qrSize = SizeConfig.screenWidth * 0.55;
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
                    _copyableBox(vpa, copiedLabel: 'UPI ID copied'),
                    // Show the mobile number only when the backend provides one.
                    if ((_upiController.mobileNumber.value ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _copyableBox(
                        _upiController.mobileNumber.value!,
                        copiedLabel: 'Mobile number copied',
                      ),
                    ],
                  ],
                );
              }),
              const SizedBox(height: 24),

              // Download / Share actions
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
                    child: _actionButton(
                      icon: Icons.upload_file_rounded,
                      label: 'Upload Screenshot',
                      isBusy: false,
                      filled: true,
                      onTap: _uploadPaymentScreenshot,
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

  /// Lets the user choose Camera or Gallery for the payment screenshot, then
  /// sends the picked image as a message into the current conversation.
  Future<void> _uploadPaymentScreenshot() async {
    if ((widget.conversationId ?? '').isEmpty) {
      commonSnackBar(message: 'Unable to send screenshot');
      return;
    }

    PhotoPickerService.showSourceChooserDialog(
      context,
      'Upload Payment Screenshot',
      onCamera: () {
        Navigator.pop(context); // close the chooser
        _pickAndSendScreenshot(ImageSource.camera);
      },
      onGallery: () {
        Navigator.pop(context); // close the chooser
        _pickAndSendScreenshot(ImageSource.gallery);
      },
    );
  }

  /// Picks an image from [source] and sends it as an image message. The QR
  /// sheet closes as soon as a file is picked so the uploading card shows in
  /// the chat.
  Future<void> _pickAndSendScreenshot(ImageSource source) async {
    final XFile? picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    if (!mounted) return;
    Navigator.pop(context); // close the QR sheet

    // Compress before upload (~80% size reduction), mirroring the chat input
    // image flow, then route through the presigned-URL upload pipeline.
    final File original = File(picked.path);
    final File toSend =
        (await ChatMediaCompressionService.compressImage(original)) ?? original;

    final fileInfo = getFileInfo(toSend);
    final uploadParams = {
      ApiKeys.fileName: [fileInfo['fileName']],
      ApiKeys.fileType: [fileInfo['mimeType']],
    };

    final chatViewController = Get.find<ChatViewController>();
    await chatViewController.generateUploadUrlsApi(
      params: uploadParams,
      listFile: [toSend],
      userId: [widget.userId ?? ''],
      conversationId: widget.conversationId,
      commands: _note,
      messageType: 'image',
      // Marks this image as a payment proof so the chat bubble renders the
      // "Waiting for approval" tag (sender) / Approve-Reject buttons (shop
      // owner). Approval is managed locally.
      metadata: const {
        'is_payment_screenshot': true,
        'approval_status': 'pending',
      },
    );
  }
}
