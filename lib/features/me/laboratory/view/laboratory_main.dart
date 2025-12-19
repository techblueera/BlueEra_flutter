import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/delivery_partner_orders.dart';
import 'package:BlueEra/features/common/delivery_partner/view/rider_profile_status_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/add_lab_services.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_blueear_screen/controller/earn_with_blueera_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/inventory_controller.dart';
import 'package:BlueEra/features/common/food/view/food_and_grocery_screen.dart';
import 'package:BlueEra/features/common/service/view/view_service_list.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/own_product_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_service_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/common_service_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/earn_with_blue_era_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/widget/horizonatal_video_player.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/tab_bar_delegate.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/common_search_bar.dart';

class LaboratoryMain extends StatefulWidget {


  const LaboratoryMain({super.key,});

  @override
  State<LaboratoryMain> createState() => _LaboratoryMainState();
}

class _LaboratoryMainState extends State<LaboratoryMain>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;



  @override
  void initState() {

    _tabController = TabController(length: 2, vsync: this);

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
                      Get.to(()=>AddLabServices());
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
              indicatorColor: Colors.blue,
              indicatorWeight: 2,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: AppStrings.myStore.tr),
                Tab(text: "Statics"),
              ],
            ),
            Expanded(child: TabBarView(
              controller: _tabController,
              children: [
                Container(),
                const Center(child: CustomText(AppStrings.comingSoon)),
              ],
            ))
          ],
        ),
      )

    );
  }
  

}
