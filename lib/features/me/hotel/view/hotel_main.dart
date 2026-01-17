import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:BlueEra/features/me/hotel/view/add_hotel_service_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_home_detail_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_home_screen.dart';
import 'package:BlueEra/features/me/hotel/view/widget/add_hotel_service.dart';
import 'package:BlueEra/features/me/school/view/category/school_home/school_home_screen.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../widgets/common_search_bar.dart';
import '../../../../widgets/local_assets.dart';

class HotelMain extends StatefulWidget {
  const HotelMain({
    super.key,
  });

  @override
  State<HotelMain> createState() => _HotelMainState();
}

class _HotelMainState extends State<HotelMain>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  bool hasHotel = false;

  @override
  void initState() {
    apiCalling();
    _tabController = TabController(length: 3, vsync: this);

    super.initState();
  }

  apiCalling() async {
    try {
      if (hotelIDGlobal.isEmpty) {
        ResponseModel response = await HotelServiceRepo().getHotelRepo();
        if (response.isSuccess) {
          String? hotelIDGlobal = response.response?.data['data']['_id'];
          if (hotelIDGlobal != null && hotelIDGlobal.isNotEmpty) {
            await setHotelID(hotelIDGlobal);
          } else {
            await setHotelID("");
          }
        }
      }
      await getHotelID();
      setState(() {
        // Check if global ID was successfully populated
        hasHotel = hotelIDGlobal.isNotEmpty;
        // controller.hasSchool.value = schoolIDGlobal.isNotEmpty;
      });
      // await schoolAboutUsController.getSchoolByIdController();
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
        body: SafeArea(
      child: hasHotel
          ? Column(
              children: [
                SizedBox(
                  height: SizeConfig.size12,
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
                    Tab(text: "My Hotel"),
                    Tab(text: "Update Hotel"),
                    Tab(text: "Statics"),
                  ],
                ),
                Expanded(
                    child: TabBarView(
                  controller: _tabController,
                  children: [
                    HotelHomeDetailScreen(),
                    AddHotelServiceScreen(),
                    ComingSoon(),
                  ],
                ))
              ],
            )
          : NoHotelCreatedScreen(),
    ));
  }
}
