import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/features/common/delivery_partner/model/rider_onboarding_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seam that made the rider profile lie: `aadhar` / `pan` / `rc` / `dl` are
/// STEP flags — the backend sets them from "a number is present" — while
/// `documents.<doc>.isVerified` is the review verdict. Reading the first as the
/// second put a green tick on every row of a rider the go-live gate was still
/// blocking.
Map<String, dynamic> _status({
  bool? aadharStep,
  bool? aadharVerified,
  String? verificationStatus,
  String? docStatus,
}) {
  return {
    'aadhar': aadharStep,
    'aadharNo': '567812346679',
    'verificationStatus': verificationStatus,
    if (aadharVerified != null || docStatus != null)
      'documents': {
        'aadhar': {
          if (aadharVerified != null) 'isVerified': aadharVerified,
          if (docStatus != null) 'status': docStatus,
        },
      },
  };
}

RiderOnboardingStatusData _parse(Map<String, dynamic> json) =>
    RiderOnboardingStatusData.fromJson(json);

void main() {
  test('a saved number with no review is submitted, not verified', () {
    final data = _parse(_status(
      aadharStep: true,
      aadharVerified: false,
      verificationStatus: 'pending',
    ));

    expect(data.verificationStatus=="verified", isTrue, reason: 'the step flag still reads as filled');
    expect(data.aadharState, RiderDocumentState.submitted);
  });

  test('an approved document reads as verified', () {
    final data = _parse(_status(
      aadharStep: true,
      aadharVerified: true,
      verificationStatus: 'pending',
    ));

    expect(data.aadharState, RiderDocumentState.verified);
  });

  test('nothing on file reads as missing, whatever the verdict says', () {
    expect(
      _parse(_status(aadharStep: false, verificationStatus: 'pending'))
          .aadharState,
      RiderDocumentState.missing,
    );
    expect(
      _parse(_status(aadharStep: null, verificationStatus: 'approved'))
          .aadharState,
      RiderDocumentState.missing,
    );
  });

  test('an approved rider stays verified when no per-document verdict is sent',
      () {
    // Older response shape: no `documents` envelope at all. This must not knock
    // an already-approved rider back to "under review".
    final data = _parse(_status(aadharStep: true, verificationStatus: 'approved'));

    expect(data.aadharIsVerified, isNull);
    expect(data.aadharState, RiderDocumentState.verified);
  });

  test('an unreviewed rider with no per-document verdict is under review', () {
    final data = _parse(_status(aadharStep: true, verificationStatus: 'pending'));

    expect(data.aadharState, RiderDocumentState.submitted);
  });

  test('a document status string stands in for a missing isVerified', () {
    expect(
      _parse(_status(
        aadharStep: true,
        docStatus: 'verified',
        verificationStatus: 'pending',
      )).aadharState,
      RiderDocumentState.verified,
    );
    expect(
      _parse(_status(
        aadharStep: true,
        docStatus: 'rejected',
        verificationStatus: 'approved',
      )).aadharState,
      RiderDocumentState.submitted,
      reason: 'an explicit non-pass must not fall back to the profile status',
    );
  });

  test('the verdicts survive a toJson round-trip', () {
    final data = _parse(_status(
      aadharStep: true,
      aadharVerified: false,
      verificationStatus: 'pending',
    ));

    final reparsed = _parse(data.toJson());

    expect(reparsed.aadharIsVerified, isFalse);
    expect(reparsed.aadharState, RiderDocumentState.submitted);
  });
}
