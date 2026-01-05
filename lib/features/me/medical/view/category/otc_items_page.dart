
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../auth/controller/medical_model_controller.dart';
import '../../../laboratory/model/lab_content_list_view_model.dart';
import '../widget/all_medical_product_list.dart';
import '../widget/selected_medical_product_prev.dart';
T getOrPutController<T>(T Function() builder, {String? tag}) {
  if (Get.isRegistered<T>(tag: tag)) {
    return Get.find<T>(tag: tag);
  } else {
    return Get.put<T>(builder(), tag: tag);
  }
}

class OTCItemsPage extends StatefulWidget {
  const OTCItemsPage({
    super.key,
    required this.title, required this.categoryId,
  });

  /// API data (GROUP + LEAF)

  final String categoryId;
  final String title;

  @override
  State<OTCItemsPage> createState() => _OTCItemsPageState();
}

class _OTCItemsPageState extends State<OTCItemsPage> {
  /// UI-ready list
  List<LabContentListViewModel> otcItemsList = [];
  final controller = getOrPutController<MedicalModelController>(
        () => MedicalModelController(),
  );

  @override
  void initState() {
    super.initState();
    controller.fetchMedicalAdminProducts(widget.categoryId);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  CommonBackAppBar(title: widget.title),
      body: Obx(() {
        if(controller.getMedicalProductListResponse.value.status==Status.COMPLETE){

          return SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: SizeConfig.size16,
                ),
                HorizontalTabSelector(
                    tabs: ['Latest', "Oldest", 'A-Z', "Z-A"],
                    selectedIndex: 0,
                    onTabSelected: (int index, title) {

                    },
                    labelBuilder: (String title) => title),
                SizedBox(
                  height: SizeConfig.size16,
                ),
                Expanded(
                    child: AllMedicalProductList(
                      productList: controller.medicalProductDetails,
                    ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 16),
                  child: CustomBtn(
                    isValidate: controller.selectedProducts.isNotEmpty,
                    onTap: () {
                       Get.to(() => const SelectedMedicalProductPrev());
                      }, title:'Next',
                  ),
                )
              ],
            ),
          );
        }else if(controller.getMedicalProductListResponse.value.status==Status.ERROR){
          return Center(
            child: CustomText("Please Try Again Later"),
          );
        }else{
          return Center(
            child: CircularProgressIndicator(),
          );
        }

      }),
    );
  }
}
