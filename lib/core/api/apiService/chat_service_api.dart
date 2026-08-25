/// All `chat-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: the call-service endpoint (`callHistory`) targets a different host
/// (`callBaseUrl`) and is intentionally left in `BaseService` itself.
mixin ChatServiceApi {
  /// ADD POST
  final String sendMessage = 'chat-service/chat/send-message';
  final String updateMessage = 'chat-service/chat/update-message';
  // Confirm/reject a payment image's status (see
  // image-is-payment-flutter-integration-guide.md → Updating payment status).
  final String paymentStatus = 'chat-service/chat/payment-status';
  final String generateUploadUrls = 'chat-service/s3/generate-upload-urls';
  final String generateDownloadUrls = 'chat-service/s3/generate-download-url';
  final String sendDownloadLargeFile =
      'chat-service/chat/send-message-large-file';
  final String sync_offline_messages =
      'chat-service/chat/sync-offline-messages';

  final String forwardMessage = 'chat-service/chat/forward-messages';
  final String createGroup = 'chat-service/group/create';
  final String updateGroup = 'chat-service/group/update';
  final String getGroupDetails = 'chat-service/group/details';
  final String getGroupMembersChat = 'chat-service/group/members';
  final String addGroupMember = "chat-service/group/add-members";
  final String checkChatConnection =
      'chat-service/connections/check-connection';
  final String getGroupMembers = 'chat-service/chat/get-group-members';
  final String deleteChatList = 'chat-service/chat/delete-chatlist';
  final String clearAllChat = 'chat-service/chat/clear-all-chat';
  final String deleteMessage = 'chat-service/chat/delete-messages';
  final String deleteGroupMessage = 'chat-service/chat/delete-messages';
  final String addToPinMessage = 'chat-service/chat/add-to-pin-message';
  final String getPinMessageList = 'chat-service/chat/pin-message-list';
  final String addToStarMessage = 'chat-service/chat/add-to-star-message';
  final String getStarMessageList = 'chat-service/chat/star-message-list';
  final String getOneToOneMedia = 'chat-service/chat/get-one-to-one-media';
  final String addToArchive = 'chat-service/chat/add-to-archive';
  final String messageLikeUnlike = 'chat-service/chat/message-like-unlike';

  final String getChatRequest = 'chat-service/connections/requests';
  final String getChatRequestsList = 'chat-service/chat/requests';
  // v1.1: consent-gated symbol-reply request endpoints. See
  // lib/docs/symbol-reply-request-integration-guide.md §2.3–2.5.
  final String chatRequestRespond = 'chat-service/chat/requests/respond';
  final String chatRequestCancel = 'chat-service/chat/requests/cancel';
  String chatRequestById(String id) => 'chat-service/chat/requests/$id';
  final String getLatestChat = 'chat-service/chat/latest-chat';
  final String getChatExportAll = 'chat-service/chat/export-all';
  final String reactChatRequest = 'chat-service/connections/respond';
  final String connectionsSync = 'chat-service/connections/sync';
  final String findServiceByContact =
      'chat-service/connections/filter-by-profileType';
  final String myconnectionsSync = 'chat-service/connections/my';
  final String requestForPersonalChat = 'chat-service/connections/request';
  final String updateMessageOrderStatus = 'chat-service/chat/order-status';

  // ── E2E Encryption API (Phase 1–4) ──────────────────────────────────────
  // Phase 1: Protocol versioning
  String e2eCapability(String userId) =>
      'chat-service/protocol/capability/$userId';

  // Phase 2: Key infrastructure
  final String e2eKeysRegister = 'chat-service/keys/register';
  final String e2eKeysOpks = 'chat-service/keys/opks';
  String e2eKeysBundle(String userId) => 'chat-service/keys/bundle/$userId';
  String e2eKeysDevice(String deviceId) => 'chat-service/keys/device/$deviceId';

  // Phase 3: Encrypted media
  final String e2eEncryptedMediaUploadUrl =
      'chat-service/encrypted-media/upload-url';

  // Phase 4: Sync engine
  final String e2eSyncMessages = 'chat-service/sync/messages';
  final String e2eSyncAck = 'chat-service/sync/ack';

  final String callUser = 'chat-service/call/user';
  final String messageToOrderTab = "chat-service/order/send-message";
  final String createGroceryOrderConvoApi =
      'chat-service/grocery-order/send-message';

  final String clearChatHistory = 'chat-service/group/clear';
  final String setReminder = 'chat-service/reminders/set-reminder';
  //gst
  final String getGst = 'chat-service/reminders/set-reminder';

  // ── Payment QR & Transactions ────────────────────────────────────────────
  // See lib/docs/payment-qr-integration-guide.md. A user registers a UPI
  // payment QR (`paymentQr`); payers record payments against it as
  // transactions (`paymentQrTransactions`). Both QR image and screenshot use
  // the existing S3 presigned upload flow (`generateUploadUrls`).
  final String paymentQr = 'chat-service/payment-qr';
  final String paymentQrTransactions = 'chat-service/payment-qr/transactions';
  final String paymentQrTransactionsReceived =
      'chat-service/payment-qr/transactions/received';
  String paymentQrById(String id) => 'chat-service/payment-qr/$id';
  String paymentQrTransactionsForQr(String id) =>
      'chat-service/payment-qr/$id/transactions';

  /// Transactions awaiting the payee's decision.
  /// `GET chat-service/payment-qr/transactions/pending`.
  final String paymentQrTransactionsPending =
      'chat-service/payment-qr/transactions/pending';

  /// The payee confirms / refuses one recorded payment. For an ORDER-linked
  /// transaction prefer the order service's own
  /// `POST /api/orders/:id/payment/verify|reject` — that is what advances the
  /// order state machine. These two exist for payments recorded outside an
  /// order. See lib/docs/FLUTTER_ORDER_FLOW_UI_GUIDE.md §9.
  String paymentQrTransactionVerify(String id) =>
      'chat-service/payment-qr/transactions/$id/verify';
  String paymentQrTransactionReject(String id) =>
      'chat-service/payment-qr/transactions/$id/reject';

  // Resolve the QR registered by a given owner so a payer can record a payment
  // against it. NOTE: not documented in payment-qr-integration-guide.md (which
  // only lists *your own* QRs) — assumed endpoint, TODO: confirm with backend.
  String paymentQrByUser(String userId) =>
      'chat-service/payment-qr/user/$userId';

  // ── Help / support inquiry ───────────────────────────────────────────────
  // Backs the floating help bubble on Discover. `supportQuestions` returns
  // ready-made questions tailored server-side to the caller's account type and
  // business category / profession (bilingual en+hi), plus the id of an
  // existing support thread when the user has already asked something.
  // `supportInquiry` starts (or reuses) that thread with the question as its
  // first message. See lib/docs/HELP_WIDGET_FLUTTER_GUIDE.md.
  final String supportQuestions = 'chat-service/support/questions';
  final String supportInquiry = 'chat-service/support/inquiry';

  /// Per-ORDER customer-care thread, opened from the ongoing-ride card's
  /// Customer Care sheet. `POST { orderId, reason, note?, vehicleType?, ride? }`
  /// opens (or reuses) a 2-way conversation with the ride/order team, posts the
  /// reason as its first message, and returns `conversation_id` plus the
  /// `display_name` to show at the top of the chat.
  ///
  /// One thread per order: a second complaint about the SAME ride appends to
  /// it, a different ride opens a new one. See
  /// docs/backend/ORDER_CUSTOMER_SUPPORT_FLUTTER_GUIDE.md.
  final String orderSupport = 'chat-service/support/order-support';
}
