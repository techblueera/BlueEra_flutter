# Security Deposit — GST & Invoice (Flutter Guide)

What changed on the backend, and the **one change you actually have to make**.

> **App repo:** `BlueEra_flutter`. All Dart paths below are relative to its
> `lib/` — e.g. `contribution_screen_v2.dart` is
> `lib/features/contribution/view/contribution_screen_v2.dart`.
> Line numbers were verified against the app at the time of writing; re-check
> them if the file has moved on.

---

## TL;DR

| | |
|---|---|
| **Does the app break?** | No. Ship nothing and payments still charge the correct amount. |
| **Is a change needed?** | **Yes — one.** The screen shows ₹200, Razorpay opens at ₹236. |
| **Invoice UI?** | Not required. Invoices arrive via BlueEra chat + email automatically. |
| **Effort** | ~20 minutes for the required fix. |

---

## 1. Why nothing breaks

`InitiateSecurityDepositResponse.fromJson` reads only the keys it names and
ignores the rest, so the new GST keys are dropped harmlessly.

And checkout already opens with the correct total —
`security_deposit_controller.dart:257`:

```dart
amount: order.finalAmount.toDouble(), // paise
```

`final_amount` **already includes GST** on the backend. It is still "the amount
to charge", exactly as before — the number is just bigger now. So Razorpay gets
the right value with zero app changes.

---

## 2. The required change — price mismatch

### The bug

`contribution_screen_v2.dart` renders **`plan.depositAmount`** — the catalog
price — in two places, and that value never includes GST:

```dart
// line ~427 — the pay button
'Pay Security Deposit  ₹${_rupees(plan.depositAmount)}',

// line ~587 — the big amount tile
zeroDeposit ? '₹0' : '₹${_rupees(plan.depositAmount)}',
```

Once GST is enabled the user experiences:

```
Your screen  :  ₹200   "Pay Security Deposit ₹200"
   ↓ taps
Razorpay     :  ₹236
```

Different price than promised → confusion, drop-off, support tickets.

> **Why can't the screen just use `final_amount`?**
> Both widgets render from the plan list, **before** `/initiate` is called. No
> order exists yet, so there is no `final_amount` to show.

### Fix A — minimal (5 min, no API call)

Make the label honest without knowing the exact tax:

```dart
// line ~427
'Pay Security Deposit  ₹${_rupees(plan.depositAmount)} + GST',

// line ~587
zeroDeposit ? '₹0' : '₹${_rupees(plan.depositAmount)} + GST',
```

Guard the zero-deposit case — never print "₹0 + GST":

```dart
zeroDeposit
    ? '₹0'
    : '₹${_rupees(plan.depositAmount)}${gstPercent > 0 ? " + GST" : ""}',
```

### Fix B — recommended (20 min, exact numbers)

Fetch the rate once on screen load and show the real breakup.

**1. Add the endpoint** — `subscription_service_api.dart`, next to
`securityDepositBase`:

```dart
final String securityDepositGst =
    'subscription-service/security-deposit/gst';
```

**2. Add a repo method** — `security_deposit_repo.dart`:

```dart
/// `GET /security-deposit/gst` — current tax rate for security deposits.
/// Returns `data` = { gst_percent, hsn_sac_code, tax_label, is_configured }.
Future<ResponseModel> getGstConfig() {
  return ApiBaseHelper().getHTTP(
    securityDepositGst,
    showProgress: false,
  );
}
```

**3. Hold it in the controller** — `security_deposit_controller.dart`:

```dart
/// Current GST percent (0 when tax is not configured). Display only —
/// never use this to compute the charge; the backend owns that.
final gstPercent = 0.obs;

Future<void> fetchGstConfig() async {
  try {
    final res = await _repo.getGstConfig();
    final data = res.response?.data?['data'];
    if (data != null) gstPercent.value = _asInt(data['gst_percent']);
  } catch (_) {
    // Non-fatal: fall back to showing the deposit without a tax line.
  }
}
```

Call it wherever plans are loaded (alongside the existing plan fetch).

**4. Render it** — `contribution_screen_v2.dart`:

```dart
int _gstOn(int depositPaise, int pct) => (depositPaise * pct / 100).round();

// line ~587 — amount tile
Builder(builder: (_) {
  final pct = controller.gstPercent.value;
  final gst = _gstOn(plan.depositAmount, pct);
  if (zeroDeposit) return CustomText('₹0', /* ...existing style */);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      CustomText(
        '₹${_rupees(plan.depositAmount + gst)}',
        fontSize: 22, fontWeight: FontWeight.w900,
        color: AppColors.primaryColor,
      ),
      if (gst > 0)
        CustomText(
          '₹${_rupees(plan.depositAmount)} + ₹${_rupees(gst)} GST',
          fontSize: 9, fontWeight: FontWeight.w600,
          color: AppColors.secondaryTextColor,
        ),
    ],
  );
}),
```

Wrap in `Obx(...)` if `gstPercent` is read outside an existing reactive scope.

> ⚠️ `_gstOn` is for **display only**. The charge is always `order.finalAmount`
> from the server. Never send a client-computed amount to Razorpay — any
> rounding drift is a failed payment.

---

## 3. API reference — what `/initiate` now returns

`POST /security-deposit/initiate` gains the keys below.
**Every existing key is unchanged.** All amounts are paise unless suffixed `_inr`.

```jsonc
{
  "success": true,
  "data": {
    // ── existing, unchanged ────────────────────────────────
    "order_id": "order_Lv32q9c9XQM8bX",
    "key_id": "rzp_live_xxxxxxxx",
    "currency": "INR",
    "base_amount": 20000,                 // catalog deposit
    "discount_amount": 0,                 // referral discount
    "referral_discount_percent": 0,
    "final_amount": 23600,                // ← CHARGE THIS. includes GST.
    "refund_after_months": 6,
    "security_deposit_id": "68b3...",
    "status": "created",

    // ── new, additive ──────────────────────────────────────
    "taxable_amount": 20000,              // deposit after discount, pre-tax
    "gst_percent": 18,
    "gst_amount": 3600,
    "taxable_amount_inr": 200,
    "gst_amount_inr": 36,
    "final_amount_inr": 236,
    "hsn_sac_code": "997119",
    "tax_label": "GST",
    "amount_display": "200 + 36",         // ready-made string
    "amount_breakup": [
      { "label": "Security Deposit", "amount": 20000, "amount_inr": 200 },
      { "label": "GST (18%)",        "amount": 3600,  "amount_inr": 36 },
      { "label": "Total Payable",    "amount": 23600, "amount_inr": 236 }
    ]
  }
}
```

`GET /security-deposit/gst` (any authenticated user):

```json
{ "gst_percent": 18, "hsn_sac_code": "997119", "tax_label": "GST", "is_configured": true }
```

`is_configured: false` with `gst_percent: 0` means GST is off — render no tax
line at all. Never show "GST 0%".

### Never do this

- ❌ Recompute the total client-side. `final_amount` is frozen server-side and matches the Razorpay order exactly. Any drift is a failed payment.
- ❌ Show a GST row when `gst_amount == 0` — that is every pre-GST and legacy user.
- ❌ Assume `final_amount == base_amount`. It hasn't been equal since referral discounts shipped, and now tax applies too.
- ❌ Cache `gst_percent` across sessions. An admin can change it at any time.

---

## 4. Optional — exact breakup after `/initiate`

`/initiate` now returns extra keys. Add them to
`InitiateSecurityDepositResponse` only if you want a confirmation sheet:

```dart
final int taxableAmount;      // paise — deposit after discount, pre-tax
final int gstPercent;
final int gstAmount;          // paise
final String amountDisplay;   // ready-made, e.g. "200 + 36"

// in fromJson:
taxableAmount = _asInt(j['taxable_amount']),
gstPercent    = _asInt(j['gst_percent']),
gstAmount     = _asInt(j['gst_amount']),
amountDisplay = (j['amount_display'] ?? '').toString(),
```

There is also `amount_breakup`, a ready-to-render list:

```json
[
  { "label": "Security Deposit", "amount": 20000, "amount_inr": 200 },
  { "label": "GST (18%)",        "amount": 3600,  "amount_inr": 36 },
  { "label": "Total Payable",    "amount": 23600, "amount_inr": 236 }
]
```

It **omits the GST row entirely when no tax applies**, so one widget renders
both the pre-GST and GST cases correctly:

```dart
...breakup.map((r) => _Row(r['label'], '₹${r['amount_inr']}')),
```

### Resumed orders

Backing out of Razorpay and re-tapping Pay returns `"resumed": true` with the
**original frozen snapshot** — the rate that order was created with, not
today's. Render it as returned; don't "correct" it against `/gst`.

---

## 5. Invoices — no work required

Every paid deposit gets a PDF invoice, delivered automatically to the user's
**BlueEra chat thread** and **email**. No app change needed.

The chat message arrives as a normal announcement with
`message_type: "document"` and a `url[0]` entry carrying `name`, `mimetype` and
`size`. If your chat UI already renders document bubbles it will Just Work —
verify it does, since this may be the first `document` announcement the app
receives. Fallback: the link is also in the message body text.

### Only if you want an in-app "My Invoices" screen

```
GET /security-deposit/invoices              → list
GET /security-deposit/{depositId}/invoice   → one deposit's invoice
```

```json
{
  "invoice_number": "BE/SD/25-26/000042",
  "invoice_url": "https://be.beapp.in/api/subscription-service/security-deposit/invoice/d/<token>",
  "status": "ready",
  "total_amount": 23600
}
```

| `status` | UI |
|---|---|
| `generating` | Spinner — "Preparing your invoice…", `invoice_url` is `null` |
| `ready` | Download button |
| `failed` | "Contact support" |

A **202** from `/{depositId}/invoice` means one was queued on demand (an old
deposit predating the feature). Treat it as `generating`, retry in ~30s.

**Opening the URL:**

```dart
launchUrl(Uri.parse(invoiceUrl), mode: LaunchMode.externalApplication);
```

- ❌ Do **not** attach the `Authorization` header — the link is intentionally unauthenticated so it also works from email and chat.
- ❌ Do **not** cache the redirect target. It expires in 15 minutes. Always re-open `invoice_url`, which is permanent.
- ⚠️ Treat `invoice_url` as a secret. It is an unguessable link to a document with the customer's name, email, phone and payment ids — keep it out of logs and analytics.

---

## 6. Stale comments to correct

`security_deposit_models.dart` — both are now wrong:

```dart
// line 104 — InitiateSecurityDepositResponse
final int finalAmount; // paise, payable (base − discount)
//                      ^ now: (base − discount) + GST

// line 139 — UserSecurityDeposit
final int finalAmount; // paise — amount actually paid AND refunded
//                      ^ paid: yes. refunded: NO.
```

Refunds return the **deposit only** — GST is remitted to the government and is
not refundable. The backend exposes `refundable_amount` for this.

No screen currently displays a refund figure, so **nothing renders incorrectly
today**. But if you ever add one, read `refundable_amount`, never `finalAmount`.

---

## 7. Rollout

The backend ships with **GST at 0%**, so it behaves exactly like today until an
admin enables it. That gives you a safe window:

1. Backend deploys — no behaviour change, GST still off
2. App update ships with the label fix
3. Admin switches GST on → prices and screens agree from day one

Turning GST on **before** the app update is what produces the ₹200-vs-₹236
mismatch. Sequence it this way and users never see it.

### Checklist

- [ ] Pay button shows a GST-inclusive or "+ GST" price
- [ ] Amount tile matches
- [ ] Zero-deposit tags still show plain "₹0" — never "₹0 + GST"
- [ ] Chat renders `message_type: "document"` bubbles
- [ ] Never compute the charge client-side — always `order.finalAmount`
- [ ] (Optional) breakup sheet via `amount_breakup`
- [ ] (Optional) My Invoices screen

## Related docs

There are three guides for this feature — this one, plus two for admin web:

| Doc | Audience |
|---|---|
| **This guide** | Flutter — the user app |
| `GST_ADMIN_GUIDE.md` | Admin web — setting & reading the GST rate |
| `INVOICE_ADMIN_GUIDE.md` | Admin web — viewing payments & invoices |
| `SECURITY_DEPOSIT_FRONTEND_INTEGRATION.md` | The original deposit flow (pre-GST) |
