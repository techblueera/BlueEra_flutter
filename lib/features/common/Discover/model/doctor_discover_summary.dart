import 'package:BlueEra/core/constants/common_methods.dart';

/// One standalone-doctor listing from
/// `GET user-service/business/filter?category=DOCTORS`.
///
/// On top of the plain business fields the backend attaches a doctor summary —
/// `headline`, `specialization[]`, `degree[]`, `experienceYears`,
/// `consultationFee`, `feeType`, `languagesSpoken[]`, `certificate_count` —
/// see §14 of `docs/STANDALONE_DOCTOR_FLUTTER_GUIDE.md`.
///
/// Deliberately NOT parsed through `business_filter_to_hospital_adapter.dart`:
/// `HospitalFullData` has no field for any of the doctor enrichment above and
/// silently discards it, which is why doctor cards used to render empty
/// (§26.2). A standalone doctor is an independent business, not a hospital.
class DoctorDiscoverSummary {
  /// `Business._id` — the id enquiries, bookings, ratings and view tracking
  /// all key on. NOT interchangeable with `DoctorProfile._id`.
  final String businessId;

  /// `Business.user_id` — the OWNER's user id. Needed for
  /// `GET hospital-service/doctors/full/{userId}` and for opening the chat.
  final String ownerUserId;

  final String name;

  /// Card subtitle — the server sends `specialization[0]` as `headline`.
  final String headline;

  final List<String> degree;
  final List<String> specialization;
  final List<String> languagesSpoken;
  final int? experienceYears;

  /// `null` means the doctor has not set a fee — the fee line must be hidden
  /// rather than rendered as `₹0`, which would advertise a free consultation.
  final num? consultationFee;
  final String? feeType;

  final int certificateCount;
  final String logo;
  final String coverPicture;
  final String address;
  final double rating;
  final int totalRatings;

  /// The untouched listing map, so widgets can reach fields this model has no
  /// first-class getter for (`timing`, `liveState`, `business_location`, …)
  /// without another round of parsing.
  final Map<String, dynamic> raw;

  const DoctorDiscoverSummary({
    required this.businessId,
    required this.ownerUserId,
    required this.name,
    required this.headline,
    required this.degree,
    required this.specialization,
    required this.languagesSpoken,
    required this.experienceYears,
    required this.consultationFee,
    required this.feeType,
    required this.certificateCount,
    required this.logo,
    required this.coverPicture,
    required this.address,
    required this.rating,
    required this.totalRatings,
    required this.raw,
  });

  /// Degraded data is normal: when the doctor service is briefly unavailable
  /// the listing still returns, with empty arrays, `0` counts and a null fee.
  /// Every field below therefore has a safe fallback — this never throws.
  factory DoctorDiscoverSummary.fromJson(Map<String, dynamic> json) {
    final specialization = _stringList(json['specialization']);
    return DoctorDiscoverSummary(
      businessId: json['_id']?.toString() ?? '',
      ownerUserId: json['user_id']?.toString() ?? '',
      name: json['business_name']?.toString() ?? '',
      headline: json['headline']?.toString().trim().isNotEmpty == true
          ? json['headline'].toString().trim()
          : (specialization.isNotEmpty ? specialization.first : ''),
      degree: _stringList(json['degree']),
      specialization: specialization,
      languagesSpoken: _stringList(json['languagesSpoken']),
      experienceYears: _toInt(json['experienceYears']),
      consultationFee: json['consultationFee'] is num
          ? json['consultationFee'] as num
          : num.tryParse(json['consultationFee']?.toString() ?? ''),
      feeType: json['feeType']?.toString(),
      certificateCount: _toInt(json['certificate_count']) ?? 0,
      logo: json['logo']?.toString() ?? '',
      coverPicture: json['coverPicture']?.toString() ?? '',
      address: json['address']?.toString() ??
          json['city_state_pincode']?.toString() ??
          '',
      rating: (json['avg_rating'] is num)
          ? (json['avg_rating'] as num).toDouble()
          : 0.0,
      totalRatings: _toInt(json['total_ratings']) ?? 0,
      raw: json,
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static int? _toInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  // ── Display helpers ─────────────────────────────────────────────────

  String get degreeLabel => degree.join(', ');

  String get languagesLabel => languagesSpoken.join(', ');

  /// `"16 Years"` / `"1 Year"`. Empty when the doctor hasn't set it — a `0`
  /// here reads as "no experience" rather than "not filled in", so both are
  /// treated the same and the row is hidden.
  String get experienceLabel {
    final years = experienceYears;
    if (years == null || years <= 0) return '';
    return years == 1 ? '1 Year' : '$years Years';
  }

  /// `true` only when the doctor has actually set a fee. Callers must check
  /// this before rendering [feeLabel].
  bool get hasFee => consultationFee != null;

  /// `"₹600/Visit"`. Empty when unset — never render `₹0`.
  String get feeLabel {
    final fee = consultationFee;
    if (fee == null) return '';
    final amount = fee % 1 == 0 ? fee.toInt().toString() : fee.toString();
    final type = (feeType ?? '').replaceFirst(RegExp(r'^Per\s+'), '').trim();
    return type.isEmpty ? '₹$amount' : '₹$amount/$type';
  }

  /// Card hero image: the cover banner, falling back to the logo.
  String get heroImage => coverPicture.isNotEmpty ? coverPicture : logo;

  /// Distance from the device, using the same three-tier scale as the lab and
  /// finance cards. Empty when the listing carries no usable coordinates or
  /// the device location is unknown — `business/filter` sends no lat/lng, so
  /// this is always a client-side computation.
  String get distanceLabel {
    final loc = raw['business_location'];
    if (loc is! Map) return '';
    final lat = (loc['lat'] as num?)?.toDouble() ?? 0.0;
    final lng = (loc['lon'] as num?)?.toDouble() ?? 0.0;
    if (lat == 0.0 || lng == 0.0) return '';
    final km = calculateDistance(lat, lng);
    if (km == null) return '';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)}m Away';
    if (km < 10) return '${km.toStringAsFixed(1)}KM Away';
    return '${km.toStringAsFixed(0)}KM Away';
  }

  /// Today's opening block from the shared `timing` payload (see
  /// `lib/docs/BUSINESS_FILTER_TIMING.md`). Null when the doctor has never set
  /// visiting hours — callers render a "Timing not set" state rather than
  /// assuming a default.
  Map? get todayTiming {
    final timing = raw['timing'];
    if (timing is! Map) return null;
    final today = timing['today'];
    return today is Map ? today : null;
  }

  /// `liveState.isLive` — true only when the wall clock is inside today's
  /// window, which is what separates "Open now" from "Open today".
  bool get isLiveNow {
    final live = raw['liveState'];
    return live is Map && live['isLive'] == true;
  }

  /// The saved weekly hours (`timing.schedule`) — 0 to 7 entries, each
  /// `{day, isOpen, shopOpenTime?, shopCloseTime?}`. Empty when the doctor has
  /// never set visiting hours.
  List<Map> get weeklyTiming {
    final timing = raw['timing'];
    if (timing is! Map) return const [];
    final schedule = timing['schedule'];
    if (schedule is! List) return const [];
    return schedule.whereType<Map>().toList();
  }

  /// Weekday name for the caller's "now", as computed by the server in the
  /// business timezone — no client-side weekday maths.
  String get todayDayLabel => todayTiming?['day']?.toString() ?? '';

  /// "Open sometime today". For "open right now" combine with [isLiveNow].
  bool get isOpenToday => todayTiming?['isOpen'] == true;

  /// Today's window as `"9:00 AM"` / `"6:00 PM"`. Both empty when the doctor is
  /// closed today — the server omits the times in that case.
  String get todayOpenLabel => formatClock(todayTiming?['shopOpenTime']);

  String get todayCloseLabel => formatClock(todayTiming?['shopCloseTime']);

  /// False when `timing` is null — the doctor has never set hours. The card
  /// must then say so rather than invent a default window.
  bool get hasTiming => todayTiming != null || weeklyTiming.isNotEmpty;

  /// Short tags for the card's chip row. Languages first (they read as tags),
  /// then any specializations beyond the one already shown as the headline, so
  /// nothing is repeated.
  List<String> get tagChips {
    final extraSpecializations =
        specialization.where((s) => s != headline).toList();
    return [...languagesSpoken, ...extraSpecializations];
  }

  /// The service names the card's services panel lists.
  ///
  /// `business/filter` is inconsistent about this one field across categories —
  /// some builds send `servicesOffered`, older ones `serviceOffered`, and the
  /// doctor enrichment sometimes sends `services` as objects rather than
  /// strings — so all three shapes are accepted here rather than in the widget.
  ///
  /// When the listing carries none of them the panel falls back to what the
  /// doctor DID fill in: the specializations beyond the one already shown as
  /// the headline, then the languages. Empty only when the doctor has filled in
  /// nothing at all, in which case the card hides the panel entirely.
  List<String> get services {
    for (final key in const ['servicesOffered', 'serviceOffered', 'services']) {
      final parsed = _serviceList(raw[key]);
      if (parsed.isNotEmpty) return parsed;
    }
    final extraSpecializations =
        specialization.where((s) => s != headline).toList();
    return [...extraSpecializations, ...languagesSpoken];
  }

  /// Accepts `["X", "Y"]` and `[{name: "X"}, {title: "Y"}]` alike — the server
  /// sends whichever the owning service happens to store.
  static List<String> _serviceList(dynamic raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final item in raw) {
      String value = '';
      if (item is Map) {
        for (final key in const [
          'name',
          'title',
          'serviceName',
          'service_name',
          'label'
        ]) {
          final candidate = item[key]?.toString().trim() ?? '';
          if (candidate.isNotEmpty) {
            value = candidate;
            break;
          }
        }
      } else {
        value = item?.toString().trim() ?? '';
      }
      if (value.isNotEmpty && !out.contains(value)) out.add(value);
    }
    return out;
  }

  /// `"17:00"` → `"5:00 PM"`. Empty for null / malformed input, which is what
  /// the server sends for a closed day.
  static String formatClock(dynamic hhmm) {
    final raw = hhmm?.toString() ?? '';
    final parts = raw.split(':');
    if (parts.length != 2) return '';
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return '';
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    return '$hour12:${m.toString().padLeft(2, '0')} $period';
  }
}
