
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/view/widgets/add_lab_services.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../widgets/common_search_bar.dart';
import '../../medical/view/widget/otc_items.dart';


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
              indicatorColor: AppColors.primaryColor,
              indicatorWeight: 4,
              tabAlignment: TabAlignment.fill,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: AppStrings.myStore.tr),
                Tab(text: "Statics"),
              ],
            ),
            Expanded(child: TabBarView(
              controller: _tabController,
              children: [
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
