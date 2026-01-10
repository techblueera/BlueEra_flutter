import 'dart:developer';

import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../widget/no_product_profile.dart';
import '../../controller/hospital_model_controller.dart';
import '../../model/hospital_model_class.dart';

class HospitalPreviewScreen extends StatelessWidget {
  HospitalPreviewScreen({super.key});

  final controller = getOrPut(() => HospitalModelController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.hospitalAiDataResponse.value.status ==
          Status.COMPLETE) {
        final details = controller.hospitalData.value;
        final hospital = details.data;

        if (hospital == null) {
          return const Center(
            child: Text("No Hospital Details Found"),
          );
        }

        controller.setContactControllers(hospital.contactUs);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ABOUT
              _sectionCard(
                title: "About Hospital",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hospital.aboutUs?.history ?? "-"),
                    const SizedBox(height: 6),
                    Text(
                      hospital.aboutUs?.missionVision ?? "-",
                      style: const TextStyle(
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              /// OPD
              _sectionTitle("OPD Departments"),
              ...(hospital.opdDepartments?.entries.map((e) {
                return _opdCard(
                  name: e.key.replaceAll("_", " "),
                  description: e.value.description ?? "",
                  doctors: e.value.doctors ?? [],
                  timing: e.value.timing ?? "",
                );
              }).toList() ??
                  []),

              /// IPD
              _sectionTitle("IPD Wards"),
              ...(hospital.ipdWards?.entries.map((e) {
                return _ipdCard(
                  name: e.key.replaceAll("_", " "),
                  beds: e.value.bedCount ?? "-",
                  charges: e.value.charges ?? "-",
                  features: e.value.features ?? [],
                );
              }).toList() ??
                  []),

              /// EMERGENCY
              _sectionTitle("Emergency & Critical Care"),
              _simpleCard(hospital
                  .emergencyCare?.emergency?.description ??
                  ""),
              _simpleCard(
                  hospital.emergencyCare?.icu?.description ??
                      ""),
              _simpleCard(
                  hospital.emergencyCare?.ccu?.description ??
                      ""),
              _simpleCard(
                  hospital.emergencyCare?.nicu?.description ??
                      ""),

              /// DIAGNOSTICS
              _sectionTitle("Diagnostic Services"),
              ...(hospital.diagnostics?.map((d) {
                return _simpleCard(
                  "${d.name ?? ""} (${d.timing ?? ""})\n${d.description ?? ""}",
                );
              }).toList() ??
                  []),

              /// OTHER
              _sectionTitle("Other Facilities"),
              _simpleCard(hospital
                  .otherFacilities?.insurance?.description ??
                  ""),
              _simpleCard(hospital
                  .otherFacilities?.ambulance?.description ??
                  ""),
              _simpleCard(hospital
                  .otherFacilities?.pmjay?.description ??
                  ""),
              _simpleCard(hospital
                  .otherFacilities?.bloodBank?.description ??
                  ""),

              /// CONTACT
              _sectionTitle("Editable Contact Details"),
              _sectionCard(
                title: "Contact Information",
                child: Column(
                  children: [
                    _editableField(
                        "Phone", controller.phoneController),
                    _editableField("Emergency Phone",
                        controller.emergencyController),
                    _editableField(
                        "Email", controller.emailController),
                    _editableField("Address",
                        controller.addressController,
                        maxLines: 3),
                  ],
                ),
              ),
               SizedBox(height: SizeConfig.size20),
              CustomBtn(
                isValidate: true,
                  onTap: (){
                  controller.saveAiHospitalDetails();
              }, title: "Save & Create Hospital"
              ),
              SizedBox(height: SizeConfig.size100),
            ],
          ),
        );
      }

      return const Center(child: NoProfileDetailsFound(content: "You Have not Upload Hospital Details"));
    });
  }

  /// ======================= WIDGETS =======================

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _sectionCard(
      {required String title, required Widget child}) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );

  Widget _opdCard(
      {required String name,
        required String description,
        required List<String> doctors,
        required String timing}) =>
      _sectionCard(
        title: name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            Text("Doctors: ${doctors.join(', ')}"),
            Text("Timing: $timing"),
          ],
        ),
      );

  Widget _ipdCard(
      {required String name,
        required String beds,
        required String charges,
        required List<String> features}) =>
      _sectionCard(
        title: name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Beds: $beds"),
            Text("Charges: $charges"),
            ...features.map((e) => Text("• $e")),
          ],
        ),
      );

  Widget _simpleCard(String text) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text),
  );

  Widget _editableField(String label,
      TextEditingController controller,
      {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CommonTextField(
          textEditController: controller,
          maxLength: maxLines,

            title: label,
        ),
      );
}

/// ======================= MODELS =======================

class HospitalPreviewResponse {
  bool? success;
  HospitalData? data;

  HospitalPreviewResponse({this.success, this.data});

  factory HospitalPreviewResponse.fromJson(
      Map<String, dynamic> json) =>
      HospitalPreviewResponse(
        success: json['success'],
        data: json['data'] != null
            ? HospitalData.fromJson(json['data'])
            : null,
      );
}

class HospitalData {
  Map<String, OpdDepartment>? opdDepartments;
  AboutUs? aboutUs;
  Map<String, IpdWard>? ipdWards;
  EmergencyCare? emergencyCare;
  List<DiagnosticService>? diagnostics;
  ContactUs? contactUs;
  OtherFacilities? otherFacilities;

  HospitalData.fromJson(Map<String, dynamic> json) {
    opdDepartments =
        (json['OPT_OUTPATIENT_DEPARTMENT'] as Map?)
            ?.map((k, v) =>
            MapEntry(k, OpdDepartment.fromJson(v)));
    aboutUs =
    json['ABOUT_US'] != null ? AboutUs.fromJson(json['ABOUT_US']) : null;
    ipdWards =
        (json['IPD_INPATIENT_DEPARTMENT'] as Map?)
            ?.map((k, v) =>
            MapEntry(k, IpdWard.fromJson(v)));
    emergencyCare = json['EMERGENCY_AND_CRITICAL_CARE'] != null
        ? EmergencyCare.fromJson(
        json['EMERGENCY_AND_CRITICAL_CARE'])
        : null;
    diagnostics = (json['DIAGNOSTIC_DEPARTMENTS']?['services']
    as List?)
        ?.map((e) => DiagnosticService.fromJson(e))
        .toList();
    contactUs =
    json['CONTACT_US'] != null ? ContactUs.fromJson(json['CONTACT_US']) : null;
    otherFacilities = json['OTHER_FACILITIES'] != null
        ? OtherFacilities.fromJson(json['OTHER_FACILITIES'])
        : null;
  }
}

class OpdDepartment {
  String? description;
  List<String>? doctors;
  String? timing;

  OpdDepartment.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    doctors = List<String>.from(json['doctors'] ?? []);
    timing = json['timing'];
  }
}

class AboutUs {
  String? history;
  String? missionVision;

  AboutUs.fromJson(Map<String, dynamic> json) {
    history = json['HISTORY'];
    missionVision = json['MISSION_AND_VISION'];
  }
}

class IpdWard {
  String? bedCount;
  String? charges;
  List<String>? features;

  IpdWard.fromJson(Map<String, dynamic> json) {
    bedCount = json['bedCount'];
    charges = json['charges'];
    features = List<String>.from(json['features'] ?? []);
  }
}

class EmergencyCare {
  SimpleDescription? emergency;
  SimpleDescription? icu;
  SimpleDescription? ccu;
  SimpleDescription? nicu;

  EmergencyCare.fromJson(Map<String, dynamic> json) {
    emergency = json['EMERGENTCY_CASUALTY'] != null
        ? SimpleDescription.fromJson(json['EMERGENTCY_CASUALTY'])
        : null;
    icu = json['ICU_INTENSIVE_CARE_UNIT'] != null
        ? SimpleDescription.fromJson(json['ICU_INTENSIVE_CARE_UNIT'])
        : null;
    ccu = json['CCU_CRITICAL_CARE_UNIT'] != null
        ? SimpleDescription.fromJson(json['CCU_CRITICAL_CARE_UNIT'])
        : null;
    nicu = json['NICU_NEONATAL_INTENSIVE_CARE_UNIT'] != null
        ? SimpleDescription.fromJson(
        json['NICU_NEONATAL_INTENSIVE_CARE_UNIT'])
        : null;
  }
}

class DiagnosticService {
  String? name;
  String? description;
  String? timing;

  DiagnosticService.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    timing = json['timing'];
  }
}

class ContactUs {
  String? phone;
  String? emergencyPhone;
  String? email;
  String? address;

  ContactUs.fromJson(Map<String, dynamic> json) {
    phone = json['phone'];
    emergencyPhone = json['emergencyPhone'];
    email = json['email'];
    address = json['address'];
  }
}

class OtherFacilities {
  SimpleDescription? insurance;
  SimpleDescription? ambulance;
  SimpleDescription? pmjay;
  SimpleDescription? bloodBank;

  OtherFacilities.fromJson(Map<String, dynamic> json) {
    insurance = json['CASH_LESS_INSURANCE'] != null
        ? SimpleDescription.fromJson(json['CASH_LESS_INSURANCE'])
        : null;
    ambulance = json['AMBULANCE'] != null
        ? SimpleDescription.fromJson(json['AMBULANCE'])
        : null;
    pmjay = json['PM_SWASTHYA_BIMA_YOJANA'] != null
        ? SimpleDescription.fromJson(
        json['PM_SWASTHYA_BIMA_YOJANA'])
        : null;
    bloodBank = json['BLOOD_BANK'] != null
        ? SimpleDescription.fromJson(json['BLOOD_BANK'])
        : null;
  }
}

class SimpleDescription {
  String? description;

  SimpleDescription.fromJson(Map<String, dynamic> json) {
    description = json['description'];
  }
}