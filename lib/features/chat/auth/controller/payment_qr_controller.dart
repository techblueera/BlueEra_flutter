import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/chat_media_compression_service.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/order_lifecycle_controller.dart';
import 'package:BlueEra/features/chat/auth/model/Generate_Upload_Ulr_Model.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/model/messageMediaUrl.dart';
import 'package:BlueEra/features/chat/auth/model/payment_qr_model.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
import 'package:BlueEra/features/chat/auth/repo/payment_qr_repo.dart';
import 'package:get/get.dart';

/// Drives the Payment QR & Transactions feature (see
/// `lib/docs/payment-qr-integration-guide.md`):
///   • registering / listing the current user's Payment QRs,
///   • recording a payment (payer) against a QR,
///   • listing payments received (payee) + handling the realtime
///     `payment:received` socket event.
///
/// Image uploads (QR image, screenshot) reuse the existing chat S3 presigned
/// flow via [ChatViewRepo].
class PaymentQrController extends GetxController {
  final PaymentQrRepo _repo = PaymentQrRepo();

  // ── My QRs (owner side) ──────────────────────────────────────────────────
  final RxBool isLoadingQrs = false.obs;
  final RxBool isRegistering = false.obs;
  final RxList<PaymentQr> myQrs = <PaymentQr>[].obs;

  /// The QR registered by [otherUserId] — the partner you'd pay. Loaded lazily
  /// from the conversation context when available, otherwise null.
  final Rxn<PaymentQr> partnerQr = Rxn<PaymentQr>();

  // ── Payments received (owner side) ───────────────────────────────────────
  final RxBool isLoadingReceived = false.obs;
  final RxList<PaymentTransaction> receivedTransactions =
      <PaymentTransaction>[].obs;
  int _receivedPage = 1;
  bool _receivedHasMore = true;

  // ── Recording a payment (payer side) ─────────────────────────────────────
  final RxBool isRecording = false.obs;

  // ───────────────────────────────────────────────────────────────────────
  // S3 upload (reuses the chat presigned-URL pipeline)
  // ───────────────────────────────────────────────────────────────────────

  /// Compresses [file] then uploads it through the presigned-URL flow.
  /// Returns the resulting [Files] (publicUrl + fileKey) or null on failure.
  ///
  /// Public so the order-payment sheet can reuse the exact same pipeline for
  /// the UPI payment screenshot it posts to
  /// `POST /api/orders/:id/payment/submit` — one upload path, one place to fix
  /// if the presigned flow changes.
  Future<Files?> uploadImageToS3(File file) => _uploadToS3(file);

  Future<Files?> _uploadToS3(File file) async {
    final File toSend =
        (await ChatMediaCompressionService.compressImage(file)) ?? file;
    final info = getFileInfo(toSend);
    final params = {
      ApiKeys.fileName: [info['fileName']],
      ApiKeys.fileType: [info['mimeType']],
    };

    final res = await ChatViewRepo().generateUploadUrlsApi(params);
    if (!res.isSuccess) return null;

    final model = GenerateUploadUlrModel.fromJson(res.response?.data);
    final files = model.files;
    if (files == null || files.isEmpty) return null;

    final target = files.first;
    final uploadRes = await ChatViewRepo().uploadVideoToS3(
      onProgress: (_) {},
      file: toSend,
      fileType: target.fileType ?? info['mimeType'] ?? 'image/jpeg',
      preSignedUrl: target.uploadUrl ?? '',
    );
    if (uploadRes == null || !uploadRes.isSuccess) return null;
    return target;
  }

  // ───────────────────────────────────────────────────────────────────────
  // Payment QR (owner)
  // ───────────────────────────────────────────────────────────────────────

  /// POST /payment-qr — uploads [qrImage] then registers the QR. Returns the
  /// created [PaymentQr] or null. Refreshes [myQrs] on success.
  Future<PaymentQr?> registerPaymentQr({
    required String upiId,
    String? upiPhoneNumber,
    required File qrImage,
  }) async {
    if (isRegistering.value) return null;
    isRegistering.value = true;
    try {
      final uploaded = await _uploadToS3(qrImage);
      if (uploaded == null) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return null;
      }

      final res = await _repo.createPaymentQr({
        'upi_id': upiId,
        if (upiPhoneNumber != null && upiPhoneNumber.isNotEmpty)
          'upi_phone_number': upiPhoneNumber,
        'qr_image_url': uploaded.publicUrl,
        if (uploaded.fileKey != null) 'qr_image_key': uploaded.fileKey,
      });

      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return null;
      }

      final data = res.response?.data;
      final qr = PaymentQr.fromJson(Map<String, dynamic>.from(data['data']));
      myQrs.insert(0, qr);
      commonSnackBar(message: data['message']?.toString() ?? 'Payment QR saved');
      return qr;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      isRegistering.value = false;
    }
  }

  /// GET /payment-qr — load the current user's QRs.
  Future<void> loadMyQrs() async {
    if (isLoadingQrs.value) return;
    isLoadingQrs.value = true;
    try {
      final res = await _repo.getMyPaymentQrs();
      if (res.isSuccess) {
        final list = (res.response?.data['data'] as List?) ?? const [];
        myQrs.assignAll(list
            .whereType<Map>()
            .map((e) => PaymentQr.fromJson(Map<String, dynamic>.from(e)))
            .toList());
      }
    } catch (_) {
      // Silent: callers render an empty/registration state on failure.
    } finally {
      isLoadingQrs.value = false;
    }
  }

  /// The current user's first/primary QR, if any.
  PaymentQr? get primaryQr => myQrs.isNotEmpty ? myQrs.first : null;

  /// GET /payment-qr/user/{userId} — resolve the QR registered by [userId]
  /// (the receiver) so a payer can record a transaction against it. Caches the
  /// result in [partnerQr].
  ///
  /// TODO(backend): this owner-lookup endpoint is NOT documented in
  /// payment-qr-integration-guide.md (which only exposes *your own* QRs).
  /// Confirm the route/shape with backend. Handles both a single-object and a
  /// list-style `data` payload defensively.
  final RxBool isLoadingPartnerQr = false.obs;

  Future<PaymentQr?> fetchPayeeQr(String userId) async {
    if (userId.isEmpty) return null;
    isLoadingPartnerQr.value = true;
    try {
      final res = await _repo.getPaymentQrByUser(userId);
      if (!res.isSuccess) return null;
      final data = res.response?.data?['data'];
      Map<String, dynamic>? raw;
      if (data is Map) {
        raw = Map<String, dynamic>.from(data);
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        raw = Map<String, dynamic>.from(data.first);
      }
      if (raw == null) return null;
      final qr = PaymentQr.fromJson(raw);
      partnerQr.value = qr;
      return qr;
    } catch (_) {
      return null;
    } finally {
      isLoadingPartnerQr.value = false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Transactions
  // ───────────────────────────────────────────────────────────────────────

  /// POST /payment-qr/transactions — uploads [screenshot] then records the
  /// payment against [paymentQrId]. On success, injects a local
  /// `payment_transaction` card into [conversationId] so the payer sees it
  /// immediately. Returns the created [PaymentTransaction] or null.
  Future<PaymentTransaction?> recordPayment({
    required String paymentQrId,
    required File screenshot,
    String? conversationId,
  }) async {
    if (isRecording.value) return null;

    isRecording.value = true;
    try {
      final uploaded = await _uploadToS3(screenshot);
      if (uploaded == null) {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return null;
      }

      final res = await _repo.recordTransaction({
        'payment_qr_id': paymentQrId,
        // 'utr_no': utrNo,
        // 'amount': amount,
        'screenshot_url': uploaded.publicUrl,
        if (uploaded.fileKey != null) 'screenshot_key': uploaded.fileKey,
      });

      if (!res.isSuccess) {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
        return null;
      }

      final data = res.response?.data;
      final txn =
          PaymentTransaction.fromJson(Map<String, dynamic>.from(data['data']));

      _injectTransactionMessage(
        txn,
        conversationId: conversationId,
        isMine: true,
      );
      commonSnackBar(
          message: data['message']?.toString() ?? 'Payment recorded');
      return txn;
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      return null;
    } finally {
      isRecording.value = false;
    }
  }

  /// GET /payment-qr/transactions/received — paginated. Pass [reset] to reload
  /// from page 1 (e.g. on tab open or after a `payment:received` event).
  Future<void> loadReceivedTransactions({bool reset = false}) async {
    if (isLoadingReceived.value) return;
    if (reset) {
      _receivedPage = 1;
      _receivedHasMore = true;
    }
    if (!_receivedHasMore) return;

    isLoadingReceived.value = true;
    try {
      final res = await _repo.getReceivedTransactions(page: _receivedPage);
      if (res.isSuccess) {
        final parsed = ReceivedTransactionsResponse.fromJson(
            Map<String, dynamic>.from(res.response?.data));
        if (reset) {
          receivedTransactions.assignAll(parsed.transactions);
        } else {
          receivedTransactions.addAll(parsed.transactions);
        }
        _receivedHasMore =
            parsed.pagination.page < parsed.pagination.totalPages;
        _receivedPage = parsed.pagination.page + 1;
      }
    } catch (_) {
      // Silent: the list keeps whatever was already loaded.
    } finally {
      isLoadingReceived.value = false;
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Realtime
  // ───────────────────────────────────────────────────────────────────────

  /// Handles the `payment:received` socket event for the QR owner: prepends the
  /// new payment to the "Payments received" list (the payee's source of truth).
  ///
  /// The event carries no conversation id, so we deliberately do NOT inject a
  /// chat card here — that would risk landing in whichever conversation is
  /// currently open. The payer side renders the card (where the conversation is
  /// known); the payee sees it in the Payments tab.
  void handlePaymentReceived(dynamic data) {
    try {
      if (data is! Map) return;
      final txn =
          PaymentTransaction.fromJson(Map<String, dynamic>.from(data));

      // Newest first; avoid duplicates if the REST refresh races the socket.
      if (txn.id != null &&
          receivedTransactions.any((t) => t.id == txn.id)) {
        return;
      }
      receivedTransactions.insert(0, txn);
    } catch (_) {
      // Best-effort: the received list remains the source of truth.
    }
  }

  /// Handles `payment:verified` / `payment:rejected` for the **payer**.
  ///
  /// Until these existed the payer was never told the outcome: they submitted
  /// a screenshot and the card sat on "waiting for the shop" indefinitely,
  /// whichever way the shop went. The event carries the transaction plus, for
  /// an order-linked payment, `order_id` — which lets the order card refresh
  /// itself so the Pay button comes back on a rejection.
  void handlePaymentResolved(dynamic data, {required bool verified}) {
    try {
      if (data is! Map) return;
      final json = Map<String, dynamic>.from(data);

      final orderId = (json['order_id'] ??
              json['orderId'] ??
              json['order_ref'] ??
              json['orderRef'])
          ?.toString();
      if (orderId != null && orderId.isNotEmpty) {
        // Authoritative: the order service, not this event, decides which
        // buttons the payer now gets.
        OrderLifecycleController.instance.refreshActions(orderId);
      }

      // Keep the payee's received list in step when the same session owns both
      // sides (a shop verifying from another device).
      final txnId = (json['_id'] ?? json['id'])?.toString();
      if (txnId != null) {
        final idx = receivedTransactions.indexWhere((t) => t.id == txnId);
        if (idx >= 0) receivedTransactions.removeAt(idx);
      }

      final reason = (json['reason'] ?? json['rejection_reason'])?.toString();
      commonSnackBar(
        message: verified
            ? 'Payment verified ✓'
            : (reason != null && reason.isNotEmpty
                ? 'Payment not confirmed: $reason'
                : 'Payment not confirmed'),
      );
    } catch (_) {
      // Best-effort: the order card's own /actions refresh is the fallback.
    }
  }

  // ───────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────

  /// Builds a `payment_transaction` [Messages] from [txn] and appends it to
  /// the chat view so it renders as a card. [isMine] is true when the current
  /// user is the payer (outgoing bubble).
  void _injectTransactionMessage(
    PaymentTransaction txn, {
    String? conversationId,
    required bool isMine,
  }) {
    if (!Get.isRegistered<ChatViewController>()) return;
    final chat = Get.find<ChatViewController>();

    final message = Messages(
      id: txn.id,
      conversationId: conversationId,
      senderId: txn.userId,
      messageType: 'payment_transaction',
      message: 'Payment',
      myMessage: isMine,
      createdAt: txn.createdAt ?? chat.formattedDate(),
      url: (txn.screenshotUrl != null && txn.screenshotUrl!.isNotEmpty)
          ? [
              MessageMediaUrl(
                url: txn.screenshotUrl,
                type: 'image',
                name: 'screenshot',
              )
            ]
          : null,
      metadata: MessageMetadata(
        paymentQrId: txn.paymentQrId,
        payeeUserId: txn.payeeUserId,
        utrNo: txn.utrNo,
        amount: txn.amount,
      ),
    );

    chat.appendLocalMessage(message);
  }

  /// True when [txn] was paid BY the current user (payer view).
  bool isOutgoing(PaymentTransaction txn) => txn.userId == userId;
}
