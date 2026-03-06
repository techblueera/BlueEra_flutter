import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/me/medical/view/widget/add_medical_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../widgets/common_search_bar.dart';

class ManufactureMain extends StatefulWidget {
  const ManufactureMain({super.key,});
  @override
  State<ManufactureMain> createState() => _ManufactureMainState();
}
class _ManufactureMainState extends State<ManufactureMain>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  @override
  void initState() {
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
                  Tab(text: "Home"),
                  Tab(text: "MY Product"),
                  Tab(text: "Statics"),
                ],
              ),
              Expanded(child: TabBarView(
                controller: _tabController,
                children: [
                  VisitBusinessProfileNew(
                    businessId: businessId,
                    screenName: AppConstants.business,
                    showAppBar: false,
                  ),
                  SizedBox(),
                  SizedBox(),
                ],
              ))
            ],
          ),
        )

    );
  }


}
