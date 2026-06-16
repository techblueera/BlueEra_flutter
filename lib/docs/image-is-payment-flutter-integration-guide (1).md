# `is_payment` Flag — Flutter Integration Guide

## What changed

The send-message API now accepts an optional **`is_payment`** boolean on image
messages (works for any message, but added for the image/payment-screenshot
flow). The backend stores it on the message document and echoes it back in the
HTTP response **and** the realtime socket payload.

- **Default:** `false`. Omit the field entirely and the message is saved with
  `is_payment: false`.
- **Sender-controlled:** the frontend decides when a sent image is a payment
  proof (e.g. a "Send as payment" toggle on the image preview screen).

Every payment message also carries a **`payment_status`** string that tracks the
lifecycle of the payment:

- **Values:** `"pending"` (default on send) → `"success"` or `"failed"`.
- Updated later via a dedicated API (see [Updating payment status](#updating-payment-status)).
- Changes are pushed in realtime over the `paymentStatusUpdate` socket event to
  **both** participants.

---

## Endpoint

```
POST /chat/send-message
Content-Type: multipart/form-data
Authorization: Bearer <token>
```

Image messages go through `multipart/form-data` (the file rides in the `files`
field). `is_payment` is just another form field.

### Request fields (relevant subset)

| Field           | Type            | Required | Notes                                         |
|-----------------|-----------------|----------|-----------------------------------------------|
| `conversation_id` | String        | yes*     | Existing conversation id                      |
| `message_type`  | String          | yes      | `"image"`                                     |
| `files`         | File            | yes      | The image file(s)                             |
| `is_payment`    | Boolean/String  | no       | `true` / `false`. Default `false`             |
| `message`       | String          | no       | Optional caption                              |

\* or `other_user_id` for a first message — same as today's flow.

> **Multipart note:** form-data values arrive as strings. Backend coerces
> `"true"` → `true`. Sending the literal string `"true"` or a real boolean both
> work. Anything else (including omitting it) → `false`.

---

## Flutter — sending an image with `is_payment`

Using `dio` (multipart):

```dart
Future<Response> sendPaymentImage({
  required String conversationId,
  required File imageFile,
  bool isPayment = false,
  String? caption,
}) async {
  final form = FormData.fromMap({
    'conversation_id': conversationId,
    'message_type': 'image',
    'is_payment': isPayment, // dio serializes bool -> "true"/"false"
    if (caption != null) 'message': caption,
    'files': await MultipartFile.fromFile(
      imageFile.path,
      filename: imageFile.path.split('/').last,
    ),
  });

  return dio.post(
    '/chat/send-message',
    data: form,
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
}
```

Using `http.MultipartRequest`:

```dart
final req = http.MultipartRequest('POST', Uri.parse('$base/chat/send-message'))
  ..headers['Authorization'] = 'Bearer $token'
  ..fields['conversation_id'] = conversationId
  ..fields['message_type'] = 'image'
  ..fields['is_payment'] = isPayment.toString() // "true" / "false"
  ..files.add(await http.MultipartFile.fromPath('files', imageFile.path));

final res = await req.send();
```

---

## Response shape

`is_payment` is part of the saved message document, so it appears in `data`:

```json
{
  "status": true,
  "message": "Message created successfully",
  "data": {
    "_id": "665f...",
    "message_type": "image",
    "is_payment": true,
    "payment_status": "pending",
    "url": [
      { "url": "https://.../images/...jpg", "type": "image", "mimetype": "image/jpeg" }
    ],
    "senderId": "...",
    "conversation_id": "...",
    "created_at": "2026-06-16T..."
  }
}
```

A freshly sent payment image always starts as `payment_status: "pending"`.

For a batch send (`other_user_id` as array), `data` is a list of message
objects, each carrying its own `is_payment` and `payment_status`.

---

## Realtime (socket) payload

The receiver gets the same fields over the existing `newMessageReceived` event:

```dart
socket.on('newMessageReceived', (payload) {
  final msg = payload['message'];
  final bool isPayment = msg['is_payment'] == true;
  final String paymentStatus = msg['payment_status'] ?? 'pending';
  // render payment-styled image bubble when true
});
```

(`commentReceived` carries it too for comment-on-media threads.)

---

## Updating payment status

The receiver of a payment image (e.g. the business/seller) confirms or rejects
the payment. Call this API to move `payment_status` from `pending` to `success`
or `failed`.

### Endpoint

```
PUT /chat/payment-status
Content-Type: application/json
Authorization: Bearer <token>
```

### Body

| Field            | Type   | Required | Notes                                  |
|------------------|--------|----------|----------------------------------------|
| `messageId`      | String | yes      | `_id` of the payment image message     |
| `payment_status` | String | yes      | `"success"`, `"failed"`, or `"pending"` |

### Response

```json
{
  "success": true,
  "message": "Payment status updated successfully",
  "data": {
    "_id": "665f...",
    "is_payment": true,
    "payment_status": "success",
    "conversation_id": "..."
  }
}
```

`400` if `payment_status` is not one of the allowed values, `404` if the
message id does not exist.

### Flutter call

```dart
Future<void> updatePaymentStatus({
  required String messageId,
  required String status, // 'success' | 'failed' | 'pending'
}) async {
  await dio.put(
    '/chat/payment-status',
    data: {'messageId': messageId, 'payment_status': status},
    options: Options(headers: {'Authorization': 'Bearer $token'}),
  );
  // No need to mutate local state here — the paymentStatusUpdate socket
  // event below fires for both participants, including the caller.
}
```

### `paymentStatusUpdate` socket event

When the status changes, **every participant** in the conversation (payer and
receiver) receives:

```dart
socket.on('paymentStatusUpdate', (payload) {
  final String messageId = payload['messageId'];
  final String conversationId = payload['conversation_id'];
  final String paymentStatus = payload['payment_status']; // success|failed|pending
  final bool isPayment = payload['is_payment'] == true;

  // Find the message by messageId in local store and update its
  // payment_status, then re-render the bubble (green = success, red = failed).
});
```

---

## Flutter model mapping

Add the field to your message model:

```dart
class ChatMessage {
  final String id;
  final String messageType;
  final bool isPayment;
  final String paymentStatus; // 'pending' | 'success' | 'failed'
  // ...

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['_id'] as String,
        messageType: json['message_type'] as String? ?? 'text',
        isPayment: json['is_payment'] == true, // null-safe -> false
        paymentStatus: json['payment_status'] as String? ?? 'pending',
        // ...
      );
}
```

> Old messages created before this change won't have the keys →
> `json['is_payment']` is `null` → `false`, and `json['payment_status']` is
> `null` → `'pending'`. No migration needed on the client.

---

## Checklist

- [ ] Add `is_payment` toggle to image preview/send UI.
- [ ] Pass `is_payment` as a form field on `/chat/send-message`.
- [ ] Parse `is_payment` + `payment_status` in message model (null-safe).
- [ ] Read both fields from `newMessageReceived` socket payload on receive.
- [ ] Render payment-styled bubble; reflect `payment_status` (pending/success/failed).
- [ ] On receiver side, call `PUT /chat/payment-status` to confirm/reject.
- [ ] Listen to `paymentStatusUpdate` socket; update the matching message locally.
