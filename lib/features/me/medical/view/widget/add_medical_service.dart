import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/medical_model_controller.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
class AddMedicalService extends StatefulWidget {
  const AddMedicalService({super.key});

  @override
  State<AddMedicalService> createState() => _AddMedicalServiceState();
}
class _AddMedicalServiceState extends State<AddMedicalService> {
  final controller = getOrPutController<MedicalModelController>(
        () => MedicalModelController(),
  );


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Add Service",
        isShadowShow: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          ...controller.medicalCategoryDataList.map((title) {
            return InkWell(
              onTap: () {
                Get.toNamed(RouteHelper.getMedicalOtcItemsScreen(),
                arguments: {
                  ApiKeys.title:title.name,
                  ApiKeys.categoryId:title.id
                });
              },
              child: MeMenuCardDesign(
                title: title.name??'',
                icon: 'assets/icons/service_icon.svg',
              ),
            );
          }).toList(),
          SizedBox(height: SizeConfig.size14),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.redLight),
              color: AppColors.redLight.withOpacity(0.1),
            ),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  "You Can’t Allow Any Medicine and Antibiotic \nAs a Display!",
                  fontSize: 14,
                  textAlign: TextAlign.center,
                  fontWeight: FontWeight.w700,
                  color: AppColors.redLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
