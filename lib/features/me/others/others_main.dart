import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/me/others/controller/business_profile_full_controller.dart';
import 'package:BlueEra/features/me/others/repo/other_repo.dart';
import 'package:BlueEra/features/me/others/view/business_profile_full_screen.dart';
import 'package:BlueEra/features/me/others/view/other_service_not_create_screen.dart';
import 'package:BlueEra/features/me/others/widget/add_others_services.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OthersMain extends StatefulWidget {
  const OthersMain({
    super.key,
  });

  @override
  State<OthersMain> createState() => _OthersMainState();
}

class _OthersMainState extends State<OthersMain>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  final controller = Get.put(BusinessProfileFullController());

  @override
  void initState() {
    apiCalling();

    _tabController = TabController(length: 3, vsync: this);

    super.initState();
  }

  apiCalling() async {
    try {
      if (otherServiceIDGlobal.isEmpty) {
        ResponseModel response = await OtherRepo().getBusinessProfileRepo();
        if (response.isSuccess) {
          otherServiceIDGlobal = response.response?.data['data']['_id'];
          if (otherServiceIDGlobal.isNotEmpty) {
            await setOtherServiceID(otherServiceIDGlobal);
          } else {
            await setOtherServiceID("");
          }
        }
      }
      await getOtherServiceID();
      setState(() {
        controller.hasProfile.value = otherServiceIDGlobal.isNotEmpty;
      });
    } on Exception catch (e) {
      // TODO
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.white,
        body: Obx(() {
          return SafeArea(
            child:  controller.hasProfile.value ? Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: AppColors.secondaryTextColor,
                  indicatorColor: AppColors.primaryColor,
                  indicatorWeight: 2,
                  tabAlignment: TabAlignment.fill,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w400),
                  tabs: [
                    Tab(text: "Others"),
                    Tab(text: "Update"),
                    Tab(text: "Statics"),
                  ],
                ),
                Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        BusinessProfileFullScreen(),
                        AddOthersServices(),
                        const Center(child: CustomText(AppStrings.comingSoon)),
                      ],
                    ))
              ],
            ) : OtherServiceNotCreateScreen(controller: controller,),
          );
        }));
  }
}
