
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/medical/view/widget/add_medical_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../widgets/common_search_bar.dart';
import '../../widget/no_product_profile.dart';
import '../controller/medical_model_controller.dart';
import 'category/medical_my_store.dart';

class MedicalMain extends StatefulWidget {


  const MedicalMain({super.key,});

  @override
  State<MedicalMain> createState() => _MedicalMainState();
}

class _MedicalMainState extends State<MedicalMain>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  final controller = getOrPut<MedicalModelController>(
  () => MedicalModelController());



  @override
  void initState() {
    controller.fetchMedicalCategoryData(MedicalStoreType.pharmacy);
    _tabController = TabController(length: 3, vsync: this);

    super.initState();
  }
  @override
  void dispose() {
    _tabController.dispose();
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
                        Get.to(()=>AddMedicalService());
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
                controller: _tabController,
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 4,
                tabAlignment: TabAlignment.fill,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: "Orders"),
                  Tab(text: "MY Store"),
                  Tab(text: "Statics"),
                ],
              ),
              Expanded(child: TabBarView(
                controller: _tabController,
                children: [
                  NoProfileDetailsFound(content: "No OTC Items Found",),
                  MedicalMyStore(),
                  NoProfileDetailsFound(content: "No Statics Items Found",),
                ],
              ))
            ],
          ),
        )

    );
  }


}
