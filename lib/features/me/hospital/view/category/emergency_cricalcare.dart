import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../../../widget/no_product_profile.dart';
import '../../controller/hospital_model_controller.dart';
import '../widget/add_department_dialog.dart';


class EmergencyCriticalCare extends StatefulWidget {
  const EmergencyCriticalCare(
      {super.key, required this.categoryId, required this.title, required this.type});
  final String categoryId;
  final String title;
  final String type;

  @override
  State<EmergencyCriticalCare> createState() => _EmergencyCriticalCareState();
}
class _EmergencyCriticalCareState extends State<EmergencyCriticalCare> {
  final controller = getOrPut(() => HospitalModelController());
  @override
  void initState() {
    // TODO: implement initState
    controller.fetchEmergencySubCategoryData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: widget.title,
        isShadowShow: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Obx(() {
            if (controller.getHospitalSubResponse.value.status ==
                Status.COMPLETE) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    if(controller.hospitalSubCate.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: NoProfileDetailsFound(
                            content: "No Details Found Under ${widget.title}"),
                      )
                    else
                      ...controller.hospitalSubCate.map((department) {
                        return MeMenuCardDesign(description: department.description,
                          title: department.name ?? '', // ✅ department name
                          isToggleOn: department.isActive,
                          showToggleButton: true,
                          icon: '',
                        );
                      }).toList(),
                    SizedBox(height: SizeConfig.size20,),
                    InkWell(
                      onTap: () {
                        controller.nameController.clear();
                        HospitalDepartmentDialog.show(
                          isEmergencyAdd: true,
                          preDepartmentType: widget.type,
                          context: context,
                          categoryId: widget.categoryId,
                          type: widget.type,
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryColor),
                          color: AppColors.primaryColor.withOpacity(0.1),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                              color: AppColors.primaryColor,),
                            SizedBox(width: SizeConfig.size6,),
                            CustomText(
                              "Add More ${widget.title}",
                              fontSize: 14,
                              textAlign: TextAlign.center,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.size50,),
                  ],
                ),
              );
            } else if (controller.getHospitalSubResponse.value.status ==
                Status.INITIAL) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return Center(
                child: CustomText("Please try sometime"),
              );
            }
          }),
        ),
      ),
    );
  }
}
