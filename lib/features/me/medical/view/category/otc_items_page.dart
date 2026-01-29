import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../laboratory/model/lab_content_list_view_model.dart';
import '../../../widget/no_product_profile.dart';
import '../../controller/medical_model_controller.dart';
import '../widget/add_product_common_dialog.dart';
import '../widget/all_medical_product_list.dart';
import '../widget/selected_medical_product_prev.dart';

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
  final controller = getOrPut(() => MedicalModelController());

  @override
  void initState() {
    super.initState();
    controller.fetchMedicalAdminProducts(widget.categoryId);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  CommonBackAppBar(
          title: widget.title,
        isAddProductButton: true,
        categoryId: widget.categoryId,
      ),
      body: Obx(() {
        if(controller.getMedicalProductListResponse.value.status==Status.COMPLETE){

          return SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: SizeConfig.size16),

                HorizontalTabSelector(
                  tabs: ['Latest', "Oldest", 'A-Z', "Z-A"],
                  selectedIndex: 0,
                  onTabSelected: (int index, title) {},
                  labelBuilder: (String title) => title,
                ),

                SizedBox(height: SizeConfig.size16),

                /// MAIN CONTENT (fix is here)
                Expanded(
                  child: controller.medicalProductDetails.isEmpty
                      ? SingleChildScrollView(
                    child: Center(
                      child: Column(
                        children: [
                          SizedBox(height: SizeConfig.size26),
                          NoProfileDetailsFound(
                            content:
                            "No ${widget.title} Product Added Yet",
                          ),
                          SizedBox(height: SizeConfig.size26),
                          CustomBtn(
                            width: 180,
                            isValidate: true,
                            onTap: () {
                              AddProductCommonDialog.showAddProduct(
                                context: context,
                                categoryId: widget.categoryId,
                              );
                            },
                            title: "Add Product",
                          ),
                        ],
                      ),
                    ),
                  )
                      : AllMedicalProductList(
                    productList: controller.medicalProductDetails,
                  ),
                ),

                /// BOTTOM BUTTON (always visible)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 22),
                  child: CustomBtn(
                    isValidate: controller.selectedProducts.isNotEmpty,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true, // IMPORTANT
                        backgroundColor: Colors.transparent,
                        builder: (context) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.8, // 85% height
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: SelectedMedicalProductPrev(),
                            ),
                          );
                        },
                      );

                      // Get.to(() => const SelectedMedicalProductPrev());
                    },
                    title: 'Next',
                  ),
                ),
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
