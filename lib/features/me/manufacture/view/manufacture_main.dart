import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/features/me/me_tab_registry.dart';
import 'package:BlueEra/features/me/medical/view/widget/add_medical_service.dart';
import 'package:BlueEra/features/subscription/view/subscription_status_view.dart';
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
    MeTabRegistry.register(_tabController);
    super.initState();
  }
  @override
  void dispose() {
    MeTabRegistry.unregister(_tabController);
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CommonBackAppBar(
          showElevation: 0,
          isDrawerMenu: true,
          isLeading: false,
          isMore: true,
          isProfile: false,
          isNotification: !isGuestUser(),
          bellIconNotEmpty: true,
          isGuestLogout: isGuestUser(),
          onNotificationTap: () {
            Navigator.pushNamed(
              context,
              RouteHelper.getNotificationScreenRoute(),
            );
          },
        ),
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
                        Get.to(()=> AddMedicalService());
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
                  const SubscriptionStatusView(),
                ],
              ))
            ],
          ),
        )

    );
  }


}
