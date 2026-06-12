/// Models for the Payment QR & Transactions feature.
///
/// Mirrors the backend data models documented in
/// `lib/docs/payment-qr-integration-guide.md`:
///   • [PaymentQr]          → a user's UPI QR (owned by the receiver/payee).
///   • [PaymentTransaction] → a single payment recorded against a [PaymentQr].
///
/// All endpoints wrap their payload in `{ success, message, data }`; the
/// `*Response` helpers below parse those envelopes.

/// A user's registered UPI payment QR. Owned by the receiver ([userId]).
class PaymentQr {
  final String? id;
  final String? userId;
  final String? upiId;
  final String? upiPhoneNumber;
  final String? qrImageUrl;
  final String? qrImageKey;
  final String? createdAt;
  final String? updatedAt;

  PaymentQr({
    this.id,
    this.userId,
    this.upiId,
    this.upiPhoneNumber,
    this.qrImageUrl,
    this.qrImageKey,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentQr.fromJson(Map<String, dynamic> json) {
    return PaymentQr(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      userId: json['user_id']?.toString(),
      upiId: json['upi_id']?.toString(),
      upiPhoneNumber: json['upi_phone_number']?.toString(),
      qrImageUrl: json['qr_image_url']?.toString(),
      qrImageKey: json['qr_image_key']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'user_id': userId,
        'upi_id': upiId,
        'upi_phone_number': upiPhoneNumber,
        'qr_image_url': qrImageUrl,
        'qr_image_key': qrImageKey,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

/// A single payment made against a [PaymentQr]. [userId] is the payer,
/// [payeeUserId] the QR owner (filled automatically by the backend).
class PaymentTransaction {
  final String? id;
  final String? paymentQrId;
  final String? payeeUserId;

  /// The payer. The realtime `payment:received` event names this
  /// `payer_user_id`; the REST record names it `user_id`. Both map here.
  final String? userId;
  final String? utrNo;
  final num? amount;
  final String? screenshotUrl;
  final String? screenshotKey;
  final String? createdAt;
  final String? updatedAt;

  PaymentTransaction({
    this.id,
    this.paymentQrId,
    this.payeeUserId,
    this.userId,
    this.utrNo,
    this.amount,
    this.screenshotUrl,
    this.screenshotKey,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    return PaymentTransaction(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      paymentQrId: json['payment_qr_id']?.toString(),
      payeeUserId: json['payee_user_id']?.toString(),
      userId: (json['user_id'] ?? json['payer_user_id'])?.toString(),
      utrNo: json['utr_no']?.toString(),
      amount: rawAmount is num ? rawAmount : num.tryParse('$rawAmount'),
      screenshotUrl: json['screenshot_url']?.toString(),
      screenshotKey: json['screenshot_key']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'payment_qr_id': paymentQrId,
        'payee_user_id': payeeUserId,
        'user_id': userId,
        'utr_no': utrNo,
        'amount': amount,
        'screenshot_url': screenshotUrl,
        'screenshot_key': screenshotKey,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

/// Pagination block returned by the "payments received" list.
class PaymentPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaymentPagination({
    this.page = 1,
    this.limit = 20,
    this.total = 0,
    this.totalPages = 0,
  });

  factory PaymentPagination.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v, int fallback) =>
        v is int ? v : int.tryParse('$v') ?? fallback;
    return PaymentPagination(
      page: asInt(json['page'], 1),
      limit: asInt(json['limit'], 20),
      total: asInt(json['total'], 0),
      totalPages: asInt(json['total_pages'], 0),
    );
  }
}

/// Parsed `GET /payment-qr/transactions/received` response.
class ReceivedTransactionsResponse {
  final List<PaymentTransaction> transactions;
  final PaymentPagination pagination;

  ReceivedTransactionsResponse({
    required this.transactions,
    required this.pagination,
  });

  factory ReceivedTransactionsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List?) ?? const [];
    return ReceivedTransactionsResponse(
      transactions: list
          .whereType<Map>()
          .map((e) => PaymentTransaction.fromJson(
              Map<String, dynamic>.from(e)))
          .toList(),
      pagination: json['pagination'] is Map
          ? PaymentPagination.fromJson(
              Map<String, dynamic>.from(json['pagination']))
          : PaymentPagination(),
    );
  }
}
