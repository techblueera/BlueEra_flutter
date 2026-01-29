
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../laboratory/view/widgets/me_menu_card_design.dart';
import '../../controller/medical_model_controller.dart';
class MedicalMyStore extends StatefulWidget {
  const MedicalMyStore({super.key});

  @override
  State<MedicalMyStore> createState() => _MedicalMyStoreState();
}
class _MedicalMyStoreState extends State<MedicalMyStore> {
  final controller = getOrPut<MedicalModelController>(
        () => MedicalModelController(),
  );


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: SizeConfig.size12),
          ...controller.medicalCategoryDataList.map((title) {
            return InkWell(
              onTap: () {
                Get.toNamed(RouteHelper.getMedicalOtcItemsScreen(),
                    arguments: {
                      ApiKeys.title:title.name,
                      ApiKeys.category_id:title.id
                    });
              },
              child: MeMenuCardDesign(
                title: title.name??'',
                icon: '',
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
          SizedBox(height: SizeConfig.size150),
        ],
      ),
    );
  }
}
