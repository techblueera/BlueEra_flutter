# Flutter Integration Guide — Loan Applications (user flow)

**Audience**: Flutter mobile team (BlueEra_flutter)
**Date**: 2026-08-26
**Backend**: `src/routes/loanApplication.route.js`, `src/controllers/loanApplication.controller.js`
**Swagger**: `/api-docs/` → tag **Loan Applications**

> Scope: the **user-facing** half only — submit, list, read, edit, withdraw.
> The admin endpoints (`/loan-applications/admin/*`) are deliberately not
> covered here; the app never calls them.

---

## 1. What the app does

The user fills a loan application form, submits it, and can then watch its
status move. That's the whole feature:

1. Open the form → optionally hydrate the dropdowns from `/options`.
2. Fill personal + employment + loan + residence details.
3. `POST /loan-applications` → the application is created as **`pending`**.
4. `GET /loan-applications/me` → "My applications" list.
5. `GET /loan-applications/{id}` → detail screen.
6. `PUT /loan-applications/{id}` → edit, **only while `pending` or `reviewed`**.
7. `DELETE /loan-applications/{id}` → withdraw, same window.

The app does **NOT**:

- set or send `applicationStatus` — only an admin moves the status, and the
  backend silently drops the field from user payloads;
- see other users' applications — every user endpoint is scoped to the caller's
  token;
- edit or withdraw once an admin has **approved** or **rejected** (→ `403`).

---

## 2. Base URL and auth

- **API_BASE (prod)**: `https://be.beapp.in/api/user-service`
- **API_BASE (local)**: `http://localhost:3000`

Every endpoint below is authenticated with the app's standard header — the same
one used for any other authenticated call:

```
Authorization: Bearer <JWT>
Content-Type: application/json
```

The applicant identity comes from that token. There is **no `userId` field in
any request body**; sending one is ignored.

---

## 3. Endpoints

| Method | Path | Purpose |
|---|---|---|
| `POST` | `{API_BASE}/loan-applications` | Submit a new application |
| `GET` | `{API_BASE}/loan-applications/options` | Enum lists for the form dropdowns |
| `GET` | `{API_BASE}/loan-applications/me` | My applications (paginated) |
| `GET` | `{API_BASE}/loan-applications/{id}` | One of my applications, in full |
| `PUT` | `{API_BASE}/loan-applications/{id}` | Partial edit of my application |
| `DELETE` | `{API_BASE}/loan-applications/{id}` | Withdraw my application |

### Response envelope

Every success looks like this:

```jsonc
{
  "success": true,
  "message": "Loan application submitted successfully",
  "data": { /* object, or array for /me */ },
  "pagination": { "page": 1, "limit": 10, "totalItems": 3, "totalPages": 1 }  // list only
}
```

Every failure looks like this:

```jsonc
{
  "success": false,
  "message": "Company name is required for salaried applicants",
  "errors": ["Company name is required for salaried applicants"]   // 400 validation only
}
```

`message` is written to be **showable to the user as-is**. Prefer it over a
generic string whenever the status is 400 or 403.

---

## 4. The data model

### 4.1 Enums

Fetch these from `GET /loan-applications/options` if you'd rather not hardcode,
but they are stable — hardcoding is fine and avoids a round-trip on form open.

```jsonc
{
  "professionTypes":     ["Business", "Salaried"],
  "residenceTypes":      ["Owned", "Rental", "Parental", "Company Provided", "Other"],
  "applicationStatuses": ["pending", "reviewed", "approved", "rejected"]
}
```

> Note the casing: profession/residence values are **Title Case**, statuses are
> **lowercase**. Send them back exactly as received.

### 4.2 Fields

| Field | Type | Required | Notes |
|---|---|---|---|
| `name` | string | ✅ | |
| `address` | string | ✅ | Residential address |
| `dob` | string | ✅ | Send `YYYY-MM-DD`. Returned as ISO datetime |
| `mobileNumber` | string | ✅ | 10 digits, starts 6–9 |
| `panNumber` | string | ✅ | `ABCDE1234F`. Stored uppercase |
| `professionType` | enum | ✅ | `Business` \| `Salaried` |
| `annualIncome` | number | ✅ | ≥ 0, rupees |
| `companyName` | string | ⚠️ Salaried | Cleared if `professionType` is Business |
| `jobRole` | string | ⚠️ Salaried | Cleared if `professionType` is Business |
| `businessName` | string | ⚠️ Business | Cleared if `professionType` is Salaried |
| `businessExperience` | number | ⚠️ Business | **Years**. ≥ 0 |
| `natureOfBusiness` | string | ⚠️ Business | Cleared if Salaried |
| `businessAddress` | string | ⚠️ Business | Cleared if Salaried |
| `loanAmount` | number | ✅ | ≥ 1, rupees |
| `loanPurpose` | string | ✅ | Free text |
| `loanTenure` | number | ✅ | **Months**. ≥ 1 |
| `isMonthlyEmi` | bool | — | Defaults `false` |
| `existingMonthlyEmi` | number | ⚠️ | Must be **> 0** when `isMonthlyEmi` is true; forced to `0` otherwise |
| `residentialPincode` | string | ✅ | 6 digits, doesn't start with 0 |
| `residenceType` | enum | ✅ | `Owned` \| `Rental` \| `Parental` \| `Company Provided` \| `Other` |

Read-only fields returned on every application: `_id`, `userId`,
`applicationStatus`, `createdAt`, `updatedAt`.

### 4.3 Sample response object

```jsonc
{
  "_id": "66c1f0a2d4e5f67890123456",
  "userId": "64f2b3c7a45e0e1f6c2d3f1a",
  "name": "Ramesh Kumar",
  "address": "12/B, Green Park Colony, New Delhi",
  "dob": "1992-04-18T00:00:00.000Z",
  "mobileNumber": "9876543210",
  "panNumber": "ABCDE1234F",
  "professionType": "Salaried",
  "annualIncome": 850000,
  "companyName": "Blue Cloud Systems Pvt Ltd",
  "jobRole": "Senior Software Engineer",
  "businessName": "",
  "businessExperience": null,
  "natureOfBusiness": "",
  "businessAddress": "",
  "loanAmount": 500000,
  "loanPurpose": "Home renovation",
  "loanTenure": 36,
  "isMonthlyEmi": true,
  "existingMonthlyEmi": 12000,
  "residentialPincode": "110033",
  "residenceType": "Rental",
  "applicationStatus": "pending",
  "createdAt": "2026-08-26T09:15:00.000Z",
  "updatedAt": "2026-08-26T09:15:00.000Z"
}
```

The unused branch comes back as `""` / `null` — **not** absent. Your `fromJson`
should treat empty string as "not applicable", not as a missing value.

---

## 5. Dart models

```dart
// lib/features/loan/models/loan_enums.dart

enum ProfessionType {
  business('Business'),
  salaried('Salaried');

  const ProfessionType(this.wire);
  final String wire;

  static ProfessionType fromWire(String v) =>
      values.firstWhere((e) => e.wire == v);
}

enum ResidenceType {
  owned('Owned'),
  rental('Rental'),
  parental('Parental'),
  companyProvided('Company Provided'),
  other('Other');

  const ResidenceType(this.wire);
  final String wire;

  static ResidenceType fromWire(String v) =>
      values.firstWhere((e) => e.wire == v);
}

enum LoanStatus {
  pending('pending', 'Submitted'),
  reviewed('reviewed', 'Under review'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected');

  const LoanStatus(this.wire, this.label);
  final String wire;
  final String label;

  /// The backend allows the applicant to edit or withdraw only in these two
  /// states. Mirror it in the UI so the buttons disappear before the 403 does.
  bool get isEditable => this == pending || this == reviewed;

  static LoanStatus fromWire(String v) =>
      values.firstWhere((e) => e.wire == v, orElse: () => pending);
}
```

```dart
// lib/features/loan/models/loan_application.dart

class LoanApplication {
  const LoanApplication({
    required this.id,
    required this.name,
    required this.address,
    required this.dob,
    required this.mobileNumber,
    required this.panNumber,
    required this.professionType,
    required this.annualIncome,
    required this.companyName,
    required this.jobRole,
    required this.businessName,
    required this.businessExperience,
    required this.natureOfBusiness,
    required this.businessAddress,
    required this.loanAmount,
    required this.loanPurpose,
    required this.loanTenure,
    required this.isMonthlyEmi,
    required this.existingMonthlyEmi,
    required this.residentialPincode,
    required this.residenceType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String address;
  final DateTime dob;               // treat as a calendar date, see §9
  final String mobileNumber;
  final String panNumber;
  final ProfessionType professionType;
  final num annualIncome;

  // Salaried branch — empty strings when professionType is Business.
  final String companyName;
  final String jobRole;

  // Business branch — empty / null when professionType is Salaried.
  final String businessName;
  final num? businessExperience;
  final String natureOfBusiness;
  final String businessAddress;

  final num loanAmount;
  final String loanPurpose;
  final int loanTenure;             // months
  final bool isMonthlyEmi;
  final num existingMonthlyEmi;
  final String residentialPincode;
  final ResidenceType residenceType;

  final LoanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LoanApplication.fromJson(Map<String, dynamic> json) {
    return LoanApplication(
      id: json['_id'] as String,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      dob: DateTime.parse(json['dob'] as String),
      mobileNumber: json['mobileNumber'] as String? ?? '',
      panNumber: json['panNumber'] as String? ?? '',
      professionType: ProfessionType.fromWire(json['professionType'] as String),
      annualIncome: json['annualIncome'] as num? ?? 0,
      companyName: json['companyName'] as String? ?? '',
      jobRole: json['jobRole'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      businessExperience: json['businessExperience'] as num?,
      natureOfBusiness: json['natureOfBusiness'] as String? ?? '',
      businessAddress: json['businessAddress'] as String? ?? '',
      loanAmount: json['loanAmount'] as num? ?? 0,
      loanPurpose: json['loanPurpose'] as String? ?? '',
      loanTenure: (json['loanTenure'] as num? ?? 0).toInt(),
      isMonthlyEmi: json['isMonthlyEmi'] as bool? ?? false,
      existingMonthlyEmi: json['existingMonthlyEmi'] as num? ?? 0,
      residentialPincode: json['residentialPincode'] as String? ?? '',
      residenceType: ResidenceType.fromWire(json['residenceType'] as String),
      status: LoanStatus.fromWire(json['applicationStatus'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  bool get isSalaried => professionType == ProfessionType.salaried;
  bool get isBusiness => professionType == ProfessionType.business;
}
```

```dart
// lib/features/loan/models/loan_page.dart

class LoanPagination {
  const LoanPagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  bool get hasMore => page < totalPages;

  factory LoanPagination.fromJson(Map<String, dynamic> json) => LoanPagination(
        page: json['page'] as int,
        limit: json['limit'] as int,
        totalItems: json['totalItems'] as int,
        totalPages: json['totalPages'] as int,
      );
}

class LoanApplicationPage {
  const LoanApplicationPage({required this.items, required this.pagination});
  final List<LoanApplication> items;
  final LoanPagination pagination;
}
```

### The create/edit payload

Keep the outbound payload separate from the read model — it lets you enforce
the conditional branch in one place instead of in every screen.

```dart
// lib/features/loan/models/loan_application_draft.dart

/// Formats a picker date as the calendar date the backend expects.
String toApiDate(DateTime d) {
  final u = DateTime.utc(d.year, d.month, d.day);
  return '${u.year.toString().padLeft(4, '0')}-'
      '${u.month.toString().padLeft(2, '0')}-'
      '${u.day.toString().padLeft(2, '0')}';
}

class LoanApplicationDraft {
  LoanApplicationDraft({
    required this.name,
    required this.address,
    required this.dob,
    required this.mobileNumber,
    required this.panNumber,
    required this.professionType,
    required this.annualIncome,
    required this.loanAmount,
    required this.loanPurpose,
    required this.loanTenure,
    required this.residentialPincode,
    required this.residenceType,
    this.isMonthlyEmi = false,
    this.existingMonthlyEmi = 0,
    this.companyName,
    this.jobRole,
    this.businessName,
    this.businessExperience,
    this.natureOfBusiness,
    this.businessAddress,
  });

  final String name;
  final String address;
  final DateTime dob;
  final String mobileNumber;
  final String panNumber;
  final ProfessionType professionType;
  final num annualIncome;
  final num loanAmount;
  final String loanPurpose;
  final int loanTenure;
  final String residentialPincode;
  final ResidenceType residenceType;
  final bool isMonthlyEmi;
  final num existingMonthlyEmi;

  final String? companyName;
  final String? jobRole;
  final String? businessName;
  final num? businessExperience;
  final String? natureOfBusiness;
  final String? businessAddress;

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'address': address.trim(),
        'dob': toApiDate(dob),
        'mobileNumber': mobileNumber.trim(),
        'panNumber': panNumber.trim().toUpperCase(),
        'professionType': professionType.wire,
        'annualIncome': annualIncome,
        'loanAmount': loanAmount,
        'loanPurpose': loanPurpose.trim(),
        'loanTenure': loanTenure,
        'isMonthlyEmi': isMonthlyEmi,
        // Backend zeroes this itself, but sending the truth keeps the
        // optimistic local copy identical to what comes back.
        'existingMonthlyEmi': isMonthlyEmi ? existingMonthlyEmi : 0,
        'residentialPincode': residentialPincode.trim(),
        'residenceType': residenceType.wire,
        if (professionType == ProfessionType.salaried) ...{
          'companyName': (companyName ?? '').trim(),
          'jobRole': (jobRole ?? '').trim(),
        },
        if (professionType == ProfessionType.business) ...{
          'businessName': (businessName ?? '').trim(),
          'businessExperience': businessExperience,
          'natureOfBusiness': (natureOfBusiness ?? '').trim(),
          'businessAddress': (businessAddress ?? '').trim(),
        },
      };
}
```

---

## 6. The service layer

Adapt to whatever HTTP client the project already uses — the shape matters more
than the package.

```dart
// lib/features/loan/data/loan_api_exception.dart

class LoanApiException implements Exception {
  LoanApiException(this.statusCode, this.message, [this.errors = const []]);

  final int statusCode;
  final String message;      // safe to show to the user
  final List<String> errors; // per-field validation messages (400 only)

  bool get isValidation   => statusCode == 400;
  bool get isUnauthorized => statusCode == 401;
  bool get isLocked       => statusCode == 403; // approved/rejected already
  bool get isNotFound     => statusCode == 404;

  @override
  String toString() => message;
}
```

```dart
// lib/features/loan/data/loan_application_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class LoanApplicationService {
  LoanApplicationService({
    required this.apiBase,        // https://be.beapp.in/api/user-service
    required this.tokenProvider,  // () async => authStore.token
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiBase;
  final Future<String?> Function() tokenProvider;
  final http.Client _client;

  static const _path = '/loan-applications';

  Uri _uri(String suffix, [Map<String, String>? query]) =>
      Uri.parse('$apiBase$_path$suffix')
          .replace(queryParameters: (query?.isEmpty ?? true) ? null : query);

  Future<Map<String, String>> _headers() async => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await tokenProvider()}',
      };

  /// Unwraps the { success, message, data } envelope or throws.
  Map<String, dynamic> _unwrap(http.Response res) {
    final body = res.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    throw LoanApiException(
      res.statusCode,
      body['message'] as String? ?? 'Something went wrong. Please try again.',
      ((body['errors'] as List?) ?? const []).cast<String>(),
    );
  }

  /// POST /loan-applications — always lands as `pending`.
  Future<LoanApplication> create(LoanApplicationDraft draft) async {
    final res = await _client.post(
      _uri(''),
      headers: await _headers(),
      body: jsonEncode(draft.toJson()),
    );
    return LoanApplication.fromJson(
        _unwrap(res)['data'] as Map<String, dynamic>);
  }

  /// GET /loan-applications/me
  Future<LoanApplicationPage> listMine({
    int page = 1,
    int limit = 10,
    LoanStatus? status,
  }) async {
    final res = await _client.get(
      _uri('/me', {
        'page': '$page',
        'limit': '$limit',
        if (status != null) 'status': status.wire,
      }),
      headers: await _headers(),
    );
    final body = _unwrap(res);
    return LoanApplicationPage(
      items: (body['data'] as List)
          .map((e) => LoanApplication.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          LoanPagination.fromJson(body['pagination'] as Map<String, dynamic>),
    );
  }

  /// GET /loan-applications/{id}
  Future<LoanApplication> getById(String id) async {
    final res = await _client.get(_uri('/$id'), headers: await _headers());
    return LoanApplication.fromJson(
        _unwrap(res)['data'] as Map<String, dynamic>);
  }

  /// PUT /loan-applications/{id} — partial. Send only what changed.
  /// Never include `applicationStatus`: the backend drops it.
  Future<LoanApplication> update(String id, Map<String, dynamic> changes) async {
    final res = await _client.put(
      _uri('/$id'),
      headers: await _headers(),
      body: jsonEncode(changes),
    );
    return LoanApplication.fromJson(
        _unwrap(res)['data'] as Map<String, dynamic>);
  }

  /// DELETE /loan-applications/{id}
  Future<void> withdraw(String id) async {
    final res = await _client.delete(_uri('/$id'), headers: await _headers());
    _unwrap(res);
  }

  /// GET /loan-applications/options — dropdown values.
  Future<Map<String, List<String>>> fetchOptions() async {
    final res = await _client.get(_uri('/options'), headers: await _headers());
    final data = _unwrap(res)['data'] as Map<String, dynamic>;
    return data.map((k, v) => MapEntry(k, (v as List).cast<String>()));
  }
}
```

---

## 7. The form — conditional branch

The single biggest thing to get right. `professionType` decides which block is
required, and the backend **clears the other block on every save**.

```dart
// Inside the form widget

Widget _employmentSection() {
  if (_professionType == ProfessionType.salaried) {
    return Column(children: [
      TextFormField(
        controller: _companyName,
        decoration: const InputDecoration(labelText: 'Company name *'),
        validator: LoanValidators.required('Company name'),
      ),
      TextFormField(
        controller: _jobRole,
        decoration: const InputDecoration(labelText: 'Job role *'),
        validator: LoanValidators.required('Job role'),
      ),
    ]);
  }

  return Column(children: [
    TextFormField(
      controller: _businessName,
      decoration: const InputDecoration(labelText: 'Business name *'),
      validator: LoanValidators.required('Business name'),
    ),
    TextFormField(
      controller: _businessExperience,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Business experience (years) *',
      ),
      validator: LoanValidators.nonNegativeNumber('Business experience'),
    ),
    TextFormField(
      controller: _natureOfBusiness,
      decoration: const InputDecoration(labelText: 'Nature of business *'),
      validator: LoanValidators.required('Nature of business'),
    ),
    TextFormField(
      controller: _businessAddress,
      maxLines: 2,
      decoration: const InputDecoration(labelText: 'Business address *'),
      validator: LoanValidators.required('Business address'),
    ),
  ]);
}
```

Two rules to bake in:

1. **Don't dispose the hidden controllers.** Keep both sets alive so a user who
   toggles Salaried → Business → Salaried doesn't lose what they typed.
2. **On an edit, switching `professionType` means re-sending the whole new
   branch.** The server wipes the old one, so a PUT of
   `{"professionType": "Business"}` alone will fail validation — send
   `businessName`, `businessExperience`, `natureOfBusiness` and
   `businessAddress` with it.

### The EMI pair

```dart
SwitchListTile(
  title: const Text('I have a running monthly EMI'),
  value: _isMonthlyEmi,
  onChanged: (v) => setState(() {
    _isMonthlyEmi = v;
    if (!v) _existingEmi.clear();
  }),
),
if (_isMonthlyEmi)
  TextFormField(
    controller: _existingEmi,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(labelText: 'Existing monthly EMI (₹) *'),
    validator: (v) {
      final n = num.tryParse((v ?? '').trim());
      if (n == null || n <= 0) {
        return 'Enter your total monthly EMI';
      }
      return null;
    },
  ),
```

The backend rejects `isMonthlyEmi: true` with `existingMonthlyEmi: 0` — catch it
in the form so the user never sees a server round-trip for it.

---

## 8. Client-side validators

Mirror the server rules exactly; these are the same regexes the schema uses.

```dart
// lib/features/loan/loan_validators.dart

class LoanValidators {
  static final _pan = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final _mobile = RegExp(r'^[6-9]\d{9}$');
  static final _pincode = RegExp(r'^[1-9][0-9]{5}$');

  static String? Function(String?) required(String label) =>
      (v) => (v ?? '').trim().isEmpty ? '$label is required' : null;

  static String? pan(String? v) {
    final s = (v ?? '').trim().toUpperCase();
    if (s.isEmpty) return 'PAN number is required';
    if (!_pan.hasMatch(s)) return 'Enter a valid PAN, e.g. ABCDE1234F';
    return null;
  }

  static String? mobile(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Mobile number is required';
    if (!_mobile.hasMatch(s)) return 'Enter a valid 10-digit mobile number';
    return null;
  }

  static String? pincode(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'Pincode is required';
    if (!_pincode.hasMatch(s)) return 'Enter a valid 6-digit pincode';
    return null;
  }

  static String? dob(DateTime? d) {
    if (d == null) return 'Date of birth is required';
    if (d.isAfter(DateTime.now())) return 'Date of birth cannot be in the future';
    return null;
  }

  static String? Function(String?) nonNegativeNumber(String label) => (v) {
        final n = num.tryParse((v ?? '').trim());
        if (n == null) return '$label is required';
        if (n < 0) return '$label cannot be negative';
        return null;
      };

  static String? Function(String?) positiveNumber(String label) => (v) {
        final n = num.tryParse((v ?? '').trim());
        if (n == null) return '$label is required';
        if (n <= 0) return '$label must be greater than zero';
        return null;
      };
}
```

Useful input formatters:

```dart
// PAN — force uppercase as the user types
TextFormField(
  controller: _pan,
  textCapitalization: TextCapitalization.characters,
  inputFormatters: [
    LengthLimitingTextInputFormatter(10),
    UpperCaseTextFormatter(),               // small custom formatter
  ],
  validator: LoanValidators.pan,
)

// Mobile / pincode — digits only
inputFormatters: [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(10),     // 6 for pincode
]
```

---

## 9. Dates

`dob` is the only date the app sends, and it's a **calendar date**, not a
moment in time.

- **Sending**: always `YYYY-MM-DD` via `toApiDate()` (§5). Never send a local
  ISO string with an offset — `1992-04-18T00:00:00+05:30` is stored as
  `1992-04-17T18:30Z` and will render as the 17th.
- **Reading**: the API returns `1992-04-18T00:00:00.000Z`. Format it with
  `.toUtc()`, not `.toLocal()`, so the displayed day can never drift:

```dart
String formatDob(DateTime dob) {
  final d = dob.toUtc();
  return DateFormat('dd MMM yyyy').format(d);
}
```

`createdAt` / `updatedAt` **are** real timestamps — use `.toLocal()` for those.

---

## 10. Status lifecycle and gating

```
pending ──▶ reviewed ──▶ approved
   │            │
   └────────────┴──────▶ rejected
```

Only an admin moves the status. The app just renders it and gates its buttons:

| Status | Label to show | Edit | Withdraw |
|---|---|---|---|
| `pending` | Submitted | ✅ | ✅ |
| `reviewed` | Under review | ✅ | ✅ |
| `approved` | Approved | ❌ | ❌ |
| `rejected` | Rejected | ❌ | ❌ |

```dart
// Detail screen
if (application.status.isEditable) ...[
  TextButton(onPressed: _openEdit, child: const Text('Edit')),
  TextButton(
    onPressed: _confirmWithdraw,
    child: const Text('Withdraw', style: TextStyle(color: Colors.red)),
  ),
],
```

Gating the UI isn't enough on its own — an admin can approve the application
while the user is sitting on the edit screen. Handle the resulting `403` by
refetching and telling the user what happened:

```dart
try {
  await service.update(id, changes);
} on LoanApiException catch (e) {
  if (e.isLocked) {
    // "A approved application can no longer be edited"
    final fresh = await service.getById(id);
    _showSnack(e.message);
    _replaceWith(fresh);   // re-render read-only
    return;
  }
  rethrow;
}
```

---

## 11. Error handling

| HTTP | When | UX |
|---|---|---|
| `400` | Validation failed, bad id, or an empty PUT body | Show `message`; map `errors[]` onto fields if you can |
| `401` | Token missing/expired/revoked | Existing global logout hook — nothing loan-specific |
| `403` | Editing/withdrawing an approved or rejected application | Refetch + show `message`, switch to read-only (§10) |
| `404` | Wrong id, or the application belongs to someone else | "This application is no longer available", pop to list |
| `500` | Backend error | Generic retry toast |

Note that `404` covers *both* "doesn't exist" and "isn't yours" — the backend
deliberately doesn't distinguish them, so don't write copy that implies the
record exists.

Empty-update guard, worth doing client-side since the server 400s on it:

```dart
Future<void> _save() async {
  final changes = _collectChangedFields();   // only fields the user touched
  if (changes.isEmpty) {
    Navigator.pop(context);                  // nothing to do
    return;
  }
  await service.update(widget.id, changes);
}
```

---

## 12. The list screen

`GET /loan-applications/me` returns **full** application objects (not the
trimmed summary rows the admin panel gets), so the list has everything it needs
for a rich card without a second call.

- `page` defaults to `1`, `limit` to `10`, and `limit` is **clamped to 100**
  server-side — asking for 500 silently gives you 100.
- Sorted newest first (`createdAt` descending). No sort parameter.
- Optional `?status=pending|reviewed|approved|rejected` for a filter chip row.

```dart
class MyLoanApplicationsController extends ChangeNotifier {
  MyLoanApplicationsController(this._service);
  final LoanApplicationService _service;

  final List<LoanApplication> items = [];
  LoanPagination? _pagination;
  bool _loading = false;
  LoanStatus? statusFilter;

  bool get hasMore => _pagination?.hasMore ?? true;

  Future<void> refresh() async {
    items.clear();
    _pagination = null;
    await loadMore();
  }

  Future<void> loadMore() async {
    if (_loading || !hasMore) return;
    _loading = true;
    notifyListeners();
    try {
      final page = await _service.listMine(
        page: (_pagination?.page ?? 0) + 1,
        limit: 10,
        status: statusFilter,
      );
      items.addAll(page.items);
      _pagination = page.pagination;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
```

After a successful create, withdraw, or edit, call `refresh()` — there's no
push/socket update for status changes, so the list is only as fresh as the last
pull. A pull-to-refresh on the list and a refetch on detail-screen focus cover
the admin-changed-it-meanwhile case.

---

## 13. Checklist before you ship

- [ ] `applicationStatus` never appears in a request body.
- [ ] `dob` sent as `YYYY-MM-DD`; displayed via `.toUtc()`.
- [ ] PAN uppercased in the field, not just before send.
- [ ] `loanTenure` labelled **months**, `businessExperience` labelled **years**.
- [ ] Salaried and Business controllers both survive a `professionType` toggle.
- [ ] Editing `professionType` re-sends the entire new branch.
- [ ] `existingMonthlyEmi` required > 0 when the EMI switch is on; cleared when off.
- [ ] Edit/Withdraw hidden unless `status.isEditable`.
- [ ] `403` on save → refetch and go read-only.
- [ ] Empty PUT short-circuited client-side.
- [ ] `_id` read, not `id`.
- [ ] `404` copy doesn't imply the record exists.
