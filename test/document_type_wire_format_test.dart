import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:flutter_test/flutter_test.dart';

/// `document-service` validates `documentType` against a fixed enum and
/// rejects anything else with `400 Invalid document payload`.
///
/// The app's [DocumentKeys] values are LOCAL identifiers — mostly
/// UPPER_SNAKE_CASE — so posting one raw fails. That is what broke Aadhaar
/// verification on the My Documents screen:
///
///   "Document validation failed: documentType: AADHAR is not a valid enum
///    value for path documentType."
///
/// while the gig-work screen kept working, because it posts to the rider
/// onboarding endpoint, which has no `documentType` field at all.
///
/// [_allowedDocumentTypes] is copied verbatim from that 400's
/// `allowedDocumentTypes` array, so this suite checks the app against what the
/// server actually said rather than against a guess.
const _allowedDocumentTypes = <String>{
  'aadhar',
  'pan',
  'drivingLicense',
  'vehicleRC',
  'addressProof',
  'noc',
  'bankersCancelledCheque',
  'gstCertificate',
  'fssaiLicense',
  'medicalLicense',
  'fireSafetyCertificate',
  'municipalCorpCertificate',
  'msmeCertificate',
  'shopActCertificate',
  'hotelTradeLicense',
  'hotelPanCard',
  'hotelGstCertificate',
  'hotelCancelledCheque',
  'hotelPoliceVerification',
  'hotelFireSafetyCertificate',
  'hotelFssaiLicense',
  'hotelOwnerIdProof',
  'hotelOnboardingAgreement',
  'hotelPropertyAgreement',
  'insuranceDocument',
  'puc',
  'fitnessCertificate',
  'bdmAadhar',
  'bdmPan',
  'bdmDrivingLicense',
  'bdmVehicleRC',
  'bdmAddressProof',
  'bdmNoc',
  'bdmBankersCancelledCheque',
  'bdmGstCertificate',
  'bdmFoodLicense',
  'bdmMedicalLicense',
  'bdmFireSafetyCertificate',
  'bdmMunicipalCorpCertificate',
  'bdmMsmeCertificate',
  'bdmShopActCertificate',
  'bankDetails',
};

/// Every local key the app can put in an upload body, with the identifier used
/// in the failure message so a break names the document rather than a string.
const _localKeys = <String, String>{
  'aadhar': DocumentKeys.aadhar,
  'pan': DocumentKeys.pan,
  'addressProof': DocumentKeys.addressProof,
  'noc': DocumentKeys.noc,
  'drivingLicense': DocumentKeys.drivingLicense,
  'bankDetails': DocumentKeys.bankDetails,
  'bankersCancelledCheque': DocumentKeys.bankersCancelledCheque,
  'vehicleRC': DocumentKeys.vehicleRC,
  'insuranceDocument': DocumentKeys.insuranceDocument,
  'puc': DocumentKeys.puc,
  'vehicleFitnessCertificate': DocumentKeys.vehicleFitnessCertificate,
  'gstCertificate': DocumentKeys.gstCertificate,
  'fssaiLicense': DocumentKeys.fssaiLicense,
  'medicalLicense': DocumentKeys.medicalLicense,
  'fireSafetyCertificate': DocumentKeys.fireSafetyCertificate,
  'municipalCorpCertificate': DocumentKeys.municipalCorpCertificate,
  'msmeCertificate': DocumentKeys.msmeCertificate,
  'shopActCertificate': DocumentKeys.shopActCertificate,
  'hotelTradeLicense': DocumentKeys.hotelTradeLicense,
  'hotelPanCard': DocumentKeys.hotelPanCard,
  'hotelGstCertificate': DocumentKeys.hotelGstCertificate,
  'hotelCancelledCheque': DocumentKeys.hotelCancelledCheque,
  'hotelPoliceVerification': DocumentKeys.hotelPoliceVerification,
  'hotelFireSafetyCertificate': DocumentKeys.hotelFireSafetyCertificate,
  'hotelFssaiLicense': DocumentKeys.hotelFssaiLicense,
  'hotelOwnerIdProof': DocumentKeys.hotelOwnerIdProof,
  'hotelOnboardingAgreement': DocumentKeys.hotelOnboardingAgreement,
  'hotelPropertyAgreement': DocumentKeys.hotelPropertyAgreement,
};

void main() {
  group('DocumentKeys.apiType', () {
    _localKeys.forEach((name, localKey) {
      test('$name translates to a type the server accepts', () {
        expect(
          _allowedDocumentTypes,
          contains(DocumentKeys.apiType(localKey)),
          reason: '$name ("$localKey") would be rejected with '
              '400 Invalid document payload',
        );
      });
    });

    /// The exact case from the bug report.
    test('aadhar sends "aadhar", never the local "AADHAR"', () {
      expect(DocumentKeys.apiType(DocumentKeys.aadhar), 'aadhar');
      expect(DocumentKeys.apiType(DocumentKeys.aadhar), isNot('AADHAR'));
    });

    /// The keys that always worked must keep working — they were already
    /// spelled the way the backend wanted, which is why hotel and vehicle
    /// uploads succeeded while every UPPER_SNAKE_CASE one failed.
    test('already-correct keys pass through unchanged', () {
      expect(DocumentKeys.apiType(DocumentKeys.puc), 'puc');
      expect(
        DocumentKeys.apiType(DocumentKeys.hotelPanCard),
        'hotelPanCard',
      );
      expect(
        DocumentKeys.apiType(DocumentKeys.insuranceDocument),
        'insuranceDocument',
      );
    });

    /// RC and the fitness certificate are the two whose local key is neither
    /// the wire value nor a simple case change, so they are the easiest to get
    /// wrong by hand.
    test('renamed keys map to their real wire names', () {
      expect(DocumentKeys.apiType(DocumentKeys.vehicleRC), 'vehicleRC');
      expect(
        DocumentKeys.apiType(DocumentKeys.vehicleFitnessCertificate),
        'fitnessCertificate',
      );
    });

    test('an unknown key is passed through rather than dropped', () {
      expect(DocumentKeys.apiType('somethingNew'), 'somethingNew');
    });
  });
}
