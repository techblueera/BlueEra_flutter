import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_home_detail_controller.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_home_detail_screen.dart';
import 'package:BlueEra/features/me/school/view/coming_soon.dart';
import 'package:BlueEra/widgets/webview_common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HotelMain extends StatefulWidget {
  const HotelMain({super.key});

  @override
  State<HotelMain> createState() => _HotelMainState();
}

class _HotelMainState extends State<HotelMain>
    with TickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  bool hasHotel = false;
  bool _hasWebsite = false;

  final hotelDetailController = getOrPut(() => HotelDetailController());

  String get _websiteUrl =>
      hotelDetailController.hotelData.value?.profile?.website ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _apiCalling();

    ever(hotelDetailController.hotelData, (_) {
      final newHasWebsite = _websiteUrl.isNotEmpty;
      if (newHasWebsite != _hasWebsite) {
        _hasWebsite = newHasWebsite;
        final currentIndex = _tabController.index;
        _tabController.dispose();
        _tabController = TabController(
          length: _hasWebsite ? 3 : 2,
          vsync: this,
          initialIndex: currentIndex.clamp(0, _hasWebsite ? 2 : 1),
        );
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _apiCalling() async {
    logs("hotelIDGlobal=== $hotelIDGlobal");
    try {
      if (hotelIDGlobal.isEmpty) {
        ResponseModel response = await HotelServiceRepo().getHotelRepo();
        if (response.isSuccess) {
          String? id = response.response?.data['data']['_id'];
          if (id != null && id.isNotEmpty) {
            await setHotelID(id);
          } else {
            await setHotelID("");
          }
        } else {
          await setHotelID("");
        }
      }
      await getHotelID();
      if (mounted) {
        setState(() {
          hasHotel = hotelIDGlobal.isNotEmpty;
        });
      }
    } on Exception {
      // ignore
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
        child:Column(
          children: [
            SizedBox(height: SizeConfig.size12),
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
                Tab(text: AppStrings.hotelMyHotelTab.tr),
                if (_hasWebsite) Tab(text: AppStrings.website.tr),
                Tab(text: AppStrings.hotelStaticsTab.tr),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  HotelHomeDetailScreen(),
                  if (_hasWebsite)
                    CommonWebView(
                      urlLink: _websiteUrl,
                      urlTitle: '',
                      hideAppBar: true,
                    ),
                  ComingSoon(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
