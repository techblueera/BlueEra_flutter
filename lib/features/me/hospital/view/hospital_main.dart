
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hospital/view/widget/add_hospital_prev_widget.dart';
import 'package:BlueEra/features/me/hospital/view/widget/add_hospital_service.dart';
import 'package:BlueEra/features/me/hospital/view/widget/create_hotel_profile_via_ai.dart';
import 'package:BlueEra/features/common/franchise/view/franchise_home.dart';
import 'package:BlueEra/features/me/hospital/view/widget/general_medicine.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/add_lab_services.dart';
import 'package:BlueEra/features/me/medical/view/category/otc_items_page.dart';
import 'package:BlueEra/features/me/medical/view/widget/add_medical_service.dart';
import 'package:BlueEra/features/me/widget/no_product_profile.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/getx_utils.dart';
import '../../../../widgets/common_search_bar.dart';
import '../../medical/view/widget/otc_items.dart';
import '../controller/hospital_model_controller.dart';
import 'hospital_home_page.dart';


class HospitalMain extends StatefulWidget {


  const HospitalMain({super.key,});

  @override
  State<HospitalMain> createState() => _HospitalMainState();
}

class _HospitalMainState extends State<HospitalMain>
    with SingleTickerProviderStateMixin, RouteAware {

  final controller = getOrPut(() => HospitalModelController());




  @override
  void initState() {

    controller.tabController = TabController(length: 3, vsync: this);
    controller.fetchHospitalCategoryData();
    controller.getHospitalHomeDetails();

    super.initState();
  }
  @override
  void dispose() {
    controller.tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body:SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: SizeConfig.size12,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26.0,vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: CommonSearchBar(
                          controller: TextEditingController(),
                          isShowCursor: false,
                          onSearchTap: (){

                          },
                          onClearCallback: (){

                          },
                          hintText: "Search Products..."),
                    ),
                    SizedBox(
                      width: SizeConfig.size12,
                    ),
                    InkWell(
                      onTap: (){
                        showDialog(context: context,
                            builder: (BuildContext){
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CreateHotelProfileViaAi(),
                          );
                            }
                        );
                        // Get.to(()=>AddHospitalService());
                      },
                      child: Container(
                        height: SizeConfig.size40,
                        width: SizeConfig.size40,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.primaryColor
                        ),
                        child: Center(
                          child:Icon(Icons.add,size: 28,color: AppColors.white,),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              TabBar(
                onTap: (index){
                  if(index==0){
                    controller.getHospitalHomeDetails();
                  }
                },
                controller: controller.tabController,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 4,
                tabAlignment: TabAlignment.fill,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: "Home"),
                  Tab(text: "Updates"),
                  Tab(text: "Statics"),
                ],
              ),
              Expanded(child: TabBarView(
                controller: controller.tabController,
                children: [
                  // HospitalPreviewScreen(),
                  HospitalHomePage(),
                  CategoryListView(),
                  const Center(child: CustomText(AppStrings.comingSoon)),
                ],
              ))
            ],
          ),
        )

    );
  }


}
