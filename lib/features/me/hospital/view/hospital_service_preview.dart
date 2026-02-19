import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospita_ai_details_res_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalServicePreview extends StatelessWidget {
  final controller = Get.find<HospitalServiceAiController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(
        title: "Hospital Service Preview",
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.only(right: 15.0, left: 15, bottom: 15, top: 5),
          child: PositiveCustomBtn(
              onTap: () async {
                await controller.createHospitalServiceController();
              },
              title: "Create Hospital"),
        ),
      ),
      body: Obx(() {
        final data = controller.aiHospitalResModel?.value.data;
        if (data == null) return Center(child: CircularProgressIndicator());

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(data.aboutus),
                    _buildSectionTitle("Outpatient Departments (OPD)"),
                    _buildOPDList(data.optoutpatientdepartment),
                    _buildSectionTitle("Inpatient Wards (IPD)"),
                    _buildIPDList(data.ipdinpatientdepartment ??
                        IpdInpatientDepartment()),
                    _buildSectionTitle("Diagnostic Services"),
                    _buildDiagnostics(data.diagnosticdepartments),
                    _buildSectionTitle("Emergency & Critical Care"),
                    _buildEmergency(data.emergencyandcriticalcare),
                    SizedBox(height: 20),
                    _buildContactCard(data.contactus),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 70,
            )
          ],
        );
      }),
    );
  }

  // --- UI Components ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: CustomText(title,
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal[900]),
    );
  }

  Widget _buildHeader(HospitalAboutUs? about) {
    return CommonCardWidget(
      borderColorColor: AppColors.whiteE5,
      cardMargin: 0,
      child: Padding(
        padding: EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(controller.searchController.text.capitalizeFirst,
                fontSize: 22, fontWeight: FontWeight.bold,maxLines: 2,overflow: TextOverflow.ellipsis,),
            SizedBox(height: 8),
            CustomText(about?.history ?? "", color: Colors.grey[700]),
          ],
        ),
      ),
    );
  }

  Widget _buildOPDList(OptOutpatientDepartment? opd) {
    if (opd == null) return Container();
    return ExpansionTile(
      title: SizedBox.shrink(),
      subtitle: CustomText("Timing: ${opd.generalmedicine?.timing}"),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CustomText(opd.generalmedicine?.description ?? ""),
        ),
        ListTile(
          leading: Icon(Icons.person),
          title: CustomText(
              "Doctors: ${opd.generalmedicine?.doctors?.join(', ') ?? 'N/A'}"),
        )
      ],
    );
  }

  Widget _buildIPDList(IpdInpatientDepartment ipd) {
    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 12),
      child: Card(
        color: Colors.blueGrey[50],
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText("General Ward", fontWeight: FontWeight.bold),
              Divider(),
              CustomText("Beds: ${ipd.generalward?.bedCount}"),
              CustomText("Charges: ${ipd.generalward?.charges}",
                  color: Colors.green[700], fontWeight: FontWeight.w600),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnostics(DiagnosticDepartments? diag) {
    return Column(
      children: diag?.services
              ?.map((s) => ListTile(
                    leading: Icon(Icons.biotech, color: Colors.teal),
                    title: CustomText(s.name ?? ""),
                    subtitle: CustomText(s.timing ?? ""),
                  ))
              .toList() ??
          [],
    );
  }

  Widget _buildEmergency(EmergencyAndCriticalCare? ecc) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.emergency, color: Colors.red),
            title: CustomText("24/7 Emergency",
                color: Colors.red[900], fontWeight: FontWeight.bold),
            subtitle: CustomText(
                "Trauma, Cardiac and Acute Medical Crisis management."),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(ContactUs? contact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          CustomText("Emergency: ${contact?.emergencyPhone}",
              color: Colors.red, fontWeight: FontWeight.bold),
          CustomText(contact?.address ?? ""),
        ],
      ),
    );
  }
}
