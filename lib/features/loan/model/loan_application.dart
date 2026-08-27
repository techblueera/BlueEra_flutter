import 'loan_enums.dart';

/// A submitted loan application, as it comes back from the API.
///
/// See docs/backend/FLUTTER_LOAN_APPLICATION_GUIDE.md §4.
///
/// **The unused employment branch comes back as `""` / `null`, not absent** —
/// a Salaried application still carries `businessName: ""`. So an empty string
/// here means "not applicable to this application", never "the server forgot
/// it", and nothing should render a branch it doesn't belong to.
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

  /// A CALENDAR date, not a moment. Format it with `.toUtc()` — see
  /// [loanDobLabel]; `.toLocal()` renders the previous day east of UTC.
  final DateTime? dob;

  final String mobileNumber;
  final String panNumber;
  final ProfessionType professionType;
  final num annualIncome;

  // Salaried branch — empty strings on a Business application.
  final String companyName;
  final String jobRole;

  // Business branch — empty / null on a Salaried application.
  final String businessName;

  /// YEARS. Not to be confused with [loanTenure], which is months.
  final num? businessExperience;

  final String natureOfBusiness;
  final String businessAddress;

  final num loanAmount;
  final String loanPurpose;

  /// MONTHS.
  final int loanTenure;

  final bool isMonthlyEmi;
  final num existingMonthlyEmi;
  final String residentialPincode;
  final ResidenceType residenceType;

  final LoanStatus status;

  /// Real timestamps, unlike [dob] — display these with `.toLocal()`.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static String _str(dynamic v) => v?.toString().trim() ?? '';

  static num _num(dynamic v, [num d = 0]) =>
      v == null ? d : (v is num ? v : num.tryParse(v.toString()) ?? d);

  factory LoanApplication.fromJson(Map<String, dynamic> j) => LoanApplication(
        // `_id`, not `id` — Mongo's own key is what the API returns.
        id: _str(j['_id'] ?? j['id']),
        name: _str(j['name']),
        address: _str(j['address']),
        dob: DateTime.tryParse(_str(j['dob'])),
        mobileNumber: _str(j['mobileNumber']),
        panNumber: _str(j['panNumber']),
        professionType: ProfessionType.fromWire(_str(j['professionType'])),
        annualIncome: _num(j['annualIncome']),
        companyName: _str(j['companyName']),
        jobRole: _str(j['jobRole']),
        businessName: _str(j['businessName']),
        // Kept nullable: the guide sends `null` on the unused branch, and 0
        // years of experience is a different statement from "not applicable".
        businessExperience:
            j['businessExperience'] == null ? null : _num(j['businessExperience']),
        natureOfBusiness: _str(j['natureOfBusiness']),
        businessAddress: _str(j['businessAddress']),
        loanAmount: _num(j['loanAmount']),
        loanPurpose: _str(j['loanPurpose']),
        loanTenure: _num(j['loanTenure']).toInt(),
        isMonthlyEmi: j['isMonthlyEmi'] == true,
        existingMonthlyEmi: _num(j['existingMonthlyEmi']),
        residentialPincode: _str(j['residentialPincode']),
        residenceType: ResidenceType.fromWire(_str(j['residenceType'])),
        status: LoanStatus.fromWire(_str(j['applicationStatus'])),
        createdAt: DateTime.tryParse(_str(j['createdAt'])),
        updatedAt: DateTime.tryParse(_str(j['updatedAt'])),
      );

  bool get isSalaried => professionType == ProfessionType.salaried;
  bool get isBusiness => professionType == ProfessionType.business;
}

/// A date of birth as the backend wants it: `YYYY-MM-DD`, no offset.
///
/// Built in UTC on purpose. A local ISO string carries the device's offset, so
/// `1992-04-18T00:00:00+05:30` is stored as `1992-04-17T18:30Z` and renders as
/// the 17th — the applicant's birthday silently moves a day.
String loanApiDate(DateTime d) {
  final u = DateTime.utc(d.year, d.month, d.day);
  return '${u.year.toString().padLeft(4, '0')}-'
      '${u.month.toString().padLeft(2, '0')}-'
      '${u.day.toString().padLeft(2, '0')}';
}

/// The outbound create/edit payload.
///
/// Kept separate from [LoanApplication] so the conditional employment branch is
/// enforced in ONE place: `professionType` decides which block is required, and
/// the backend **clears the other block on every save**. Sending both would
/// have half of it silently discarded; sending neither fails validation.
class LoanApplicationDraft {
  const LoanApplicationDraft({
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

  /// MONTHS.
  final int loanTenure;

  final String residentialPincode;
  final ResidenceType residenceType;
  final bool isMonthlyEmi;
  final num existingMonthlyEmi;

  final String? companyName;
  final String? jobRole;
  final String? businessName;

  /// YEARS.
  final num? businessExperience;

  final String? natureOfBusiness;
  final String? businessAddress;

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'address': address.trim(),
        'dob': loanApiDate(dob),
        'mobileNumber': mobileNumber.trim(),
        // Uppercased again here even though the field forces it as the user
        // types — this is the last point before the wire, and the backend
        // stores what it is sent.
        'panNumber': panNumber.trim().toUpperCase(),
        'professionType': professionType.wire,
        'annualIncome': annualIncome,
        'loanAmount': loanAmount,
        'loanPurpose': loanPurpose.trim(),
        'loanTenure': loanTenure,
        'isMonthlyEmi': isMonthlyEmi,
        // The backend zeroes this itself when the flag is off, but sending the
        // truth keeps an optimistic local copy identical to what comes back.
        'existingMonthlyEmi': isMonthlyEmi ? existingMonthlyEmi : 0,
        'residentialPincode': residentialPincode.trim(),
        'residenceType': residenceType.wire,
        // ONE branch, never both.
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
