// import 'package:BlueEra/core/constants/shared_preference_utils.dart';
// import 'package:BlueEra/features/me/laboratory/controller/facility_controller.dart';
// import 'package:BlueEra/features/me/laboratory/model/facility_model.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// void main() {
//   test('Validate form requires either standard or other items', () {
//     final c = FacilityController();
//     c.wheelchairAssistance.value = false;
//     c.doctorConsultationTieUp.value = false;
//     c.insuranceCashlessSupport.value = false;
//     c.homeSampleCollection.value = false;
//     c.digitalReport.value = false;
//     c.otherEnabled.value = false;
//     c.validateForm();
//     expect(c.isValid.value, false);
//
//     c.wheelchairAssistance.value = true;
//     c.validateForm();
//     expect(c.isValid.value, true);
//   });
//
//   test('Other items active must have label and details', () {
//     final c = FacilityController();
//     c.otherEnabled.value = true;
//     c.others.add(FacilityOther(label: '', isActive: true, details: ''));
//     c.validateForm();
//     expect(c.isValid.value, false);
//
//     c.others[0] = FacilityOther(label: 'Pickup & Drop', isActive: true, details: 'Available');
//     c.validateForm();
//     expect(c.isValid.value, true);
//   });
//
//   test('Payload maps correctly', () {
//     final c = FacilityController();
//     // c.laboratoryId.value = "lab123";
//     c.wheelchairAssistance.value = true;
//     c.otherEnabled.value = true;
//     c.others.add(FacilityOther(label: 'Pickup', isActive: true, details: 'Yes'));
//     final payload = {
//       "laboratoryId":labIDGlobal,
//       "wheelchairAssistance": c.wheelchairAssistance.value,
//       "doctorConsultationTieUp": c.doctorConsultationTieUp.value,
//       "insuranceCashlessSupport": c.insuranceCashlessSupport.value,
//       "homeSampleCollection": c.homeSampleCollection.value,
//       "digitalReport": c.digitalReport.value,
//       "other": c.others.map((e) => e.toJson()).toList(),
//     };
//     expect(payload["laboratoryId"], "lab123");
//     expect((payload["other"] as List).length, 1);
//   });
// }
