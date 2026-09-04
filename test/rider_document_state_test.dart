import 'package:BlueEra/features/common/delivery_partner/model/rider_onboarding_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// The seam that made the rider profile lie: `aadhar` is a STEP flag — the
/// backend sets it from "a number is present" — while verification is a
/// separate verdict. Reading the first as the second put a green tick on 1,591
/// riders the go-live gate was still blocking: they typed a number, never
/// uploaded the card images, and could not understand why they still couldn't
/// go live. See docs/backend/RIDER_AADHAAR_VERIFIED_APP_GUIDE.md.
///
/// The verdict now arrives as a top-level `aadharVerified`, with
/// `aadharVerifiedThrough` / `aadharStatus` as the interim fallback for
/// backends that have not shipped it yet. These tests pin the two halves apart.
Map<String, dynamic> _status({
  Object? aadharStep,
  Object? aadharVerified,
  String? verifiedThrough,
  String? aadharStatus,
  String? aadharMasked,
  String? aadharNo,
}) {
  return {
    if (aadharStep != null) 'aadhar': aadharStep,
    if (aadharVerified != null) 'aadharVerified': aadharVerified,
    if (verifiedThrough != null) 'aadharVerifiedThrough': verifiedThrough,
    if (aadharStatus != null) 'aadharStatus': aadharStatus,
    if (aadharMasked != null) 'aadharMasked': aadharMasked,
    if (aadharNo != null) 'aadharNo': aadharNo,
  };
}

RiderOnboardingStatusData _parse(Map<String, dynamic> json) =>
    RiderOnboardingStatusData.fromJson(json);

void main() {
  group('the step flag is not the verdict', () {
    test('a saved number with no review is on file but NOT verified', () {
      final data = _parse(_status(aadharStep: true));

      expect(data.aadhar, isTrue, reason: 'the step flag reads as filled');
      expect(data.aadharVerified, isFalse,
          reason: 'nothing has reviewed it — this is the tick that lied');
    });

    test('an approved document is both on file and verified', () {
      final data = _parse(_status(aadharStep: true, aadharVerified: true));

      expect(data.aadhar, isTrue);
      expect(data.aadharVerified, isTrue);
    });

    test('a rejected document stays on file, unverified, and says why', () {
      final data = _parse(_status(aadharStep: true, aadharStatus: 'rejected'));

      expect(data.aadhar, isTrue);
      expect(data.aadharVerified, isFalse);
      expect(data.aadharStatus, 'rejected',
          reason: 'the rider must be told to re-submit, not left waiting');
    });
  });

  group('the step flag', () {
    test('nothing on file reads as false', () {
      expect(_parse(_status(aadharStep: false)).aadhar, isFalse);
    });

    test('both keys absent stays null — unknown, not a hard false', () {
      expect(_parse(_status()).aadhar, isNull);
    });

    test('a user-level verification satisfies the step on its own', () {
      // A Gig Work signup verifies through `/user/aadhaar/*` and never makes
      // the personal-identification PUT, so `aadhar` is absent. Reading only
      // that flag asked those riders for the same Aadhaar a second time.
      final data = _parse(_status(aadharVerified: true));

      expect(data.aadhar, isTrue);
      expect(data.aadharVerified, isTrue);
    });

    test('a user-level verification overrides an explicit false step', () {
      expect(
        _parse(_status(aadharStep: false, aadharVerified: true)).aadhar,
        isTrue,
      );
    });
  });

  group('the interim fallback, until the backend sends aadharVerified', () {
    test('aadharVerifiedThrough standing alone means verified', () {
      // It is "otp" / "manual" only when verified, and null otherwise.
      expect(
        _parse(_status(aadharStep: true, verifiedThrough: 'otp'))
            .aadharVerified,
        isTrue,
      );
      expect(
        _parse(_status(aadharStep: true, verifiedThrough: 'manual'))
            .aadharVerified,
        isTrue,
      );
    });

    test('a "verified" status string also stands in, case-insensitively', () {
      expect(
        _parse(_status(aadharStep: true, aadharStatus: 'verified'))
            .aadharVerified,
        isTrue,
      );
      expect(
        _parse(_status(aadharStep: true, aadharStatus: 'VERIFIED'))
            .aadharVerified,
        isTrue,
      );
    });

    test('a pending status is not a pass', () {
      expect(
        _parse(_status(aadharStep: true, aadharStatus: 'pending'))
            .aadharVerified,
        isFalse,
      );
    });

    test('the explicit flag wins over the fallback in both directions', () {
      // The point of the fallback is that it yields the moment the real field
      // ships — including when the real field disagrees with it.
      expect(
        _parse(_status(
          aadharStep: true,
          aadharVerified: false,
          verifiedThrough: 'otp',
          aadharStatus: 'verified',
        )).aadharVerified,
        isFalse,
      );
      expect(
        _parse(_status(
          aadharStep: true,
          aadharVerified: true,
          aadharStatus: 'rejected',
        )).aadharVerified,
        isTrue,
      );
    });

    test('no verdict of any kind is unverified, never null', () {
      // The consumer branches on `== true`, so a null would read the same —
      // but the field is documented as a definite answer, so pin it.
      expect(_parse(_status(aadharStep: true)).aadharVerified, isFalse);
    });
  });

  group('what to display', () {
    test('aadharMasked is carried through for the OTP route', () {
      // `aadharNo` is null on the OTP route by design — be_user_service keeps
      // only a hash plus the last four digits — so masking it locally produced
      // an empty row for exactly the riders who did verify properly.
      final data = _parse(_status(
        aadharStep: true,
        aadharVerified: true,
        verifiedThrough: 'otp',
        aadharMasked: 'XXXX XXXX 3693',
      ));

      expect(data.aadharMasked, 'XXXX XXXX 3693');
      expect(data.aadharNo, isNull);
    });

    test('the document route still carries a raw number', () {
      final data = _parse(_status(aadharStep: true, aadharNo: '567812346679'));

      expect(data.aadharNo, '567812346679');
      expect(data.aadharVerified, isFalse,
          reason: 'having the number is not having a verdict');
    });
  });

  group('document images', () {
    test('the nested documents envelope supplies both sides', () {
      final data = _parse({
        'aadhar': true,
        'documents': {
          'aadhar': {
            'files': {
              'front': 'https://cdn/a-front.jpg',
              'back': 'https://cdn/a-back.jpg',
            },
          },
        },
      });

      expect(data.aadharImage, 'https://cdn/a-front.jpg');
      expect(data.aadharImageBack, 'https://cdn/a-back.jpg');
    });

    test('a flat top-level field still works, and blanks fall through', () {
      final data = _parse({
        'aadhar': true,
        'documents': {
          'aadhar': {
            'files': {'front': ''},
          },
        },
        'aadharImage': 'https://cdn/legacy.jpg',
      });

      expect(data.aadharImage, 'https://cdn/legacy.jpg',
          reason: 'an empty backend value must not win over a real URL');
      expect(data.aadharImageBack, isNull);
    });
  });
}
