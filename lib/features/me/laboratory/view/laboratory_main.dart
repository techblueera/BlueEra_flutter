import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/view/no_lab_create_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/features/me/school/view/school_update_screen.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

class LaboratoryMain extends StatefulWidget {
  const LaboratoryMain({
    super.key,
  });

  @override
  State<LaboratoryMain> createState() => _LaboratoryMainState();
}

class _LaboratoryMainState extends State<LaboratoryMain>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  bool hasLabCreated = false;

  @override
  void initState() {
    // apiCalling();
    _tabController = TabController(length: 3, vsync: this);

    super.initState();
  }

  //
  // apiCalling() async {
  //   try {
  //     if (hotelIDGlobal.isEmpty) {
  //       ResponseModel response = await HotelServiceRepo().getHotelRepo();
  //       if (response.isSuccess) {
  //         String? hotelIDGlobal = response.response?.data['data']['_id'];
  //         if (hotelIDGlobal != null && hotelIDGlobal.isNotEmpty) {
  //           await setHotelID(hotelIDGlobal);
  //         } else {
  //           await setHotelID("");
  //         }
  //       }
  //     }
  //     await getHotelID();
  //     setState(() {
  //       // Check if global ID was successfully populated
  //       hasHotel = hotelIDGlobal.isNotEmpty;
  //       // controller.hasSchool.value = schoolIDGlobal.isNotEmpty;
  //     });
  //     // await schoolAboutUsController.getSchoolByIdController();
  //   } on Exception {
  //     // TODO
  //   }
  // }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: Padding(
          padding: EdgeInsetsGeometry.only(bottom: 100),
          child: FloatingActionButton(onPressed: () {
            Get.to(ServiceProgressScreen());
          }),
        ),
        body: SafeArea(
          child: hasLabCreated
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
                        Tab(text: "Home"),
                        Tab(text: "Update"),
                        Tab(text: "Statics"),
                      ],
                    ),
                    Expanded(
                        child: TabBarView(
                      controller: _tabController,
                      children: [
                        ComingSoon(),
                        ComingSoon(),
                        ComingSoon(),
                      ],
                    ))
                  ],
                )
              : NoLabCreateScreen(),
        ));
  }
}

class ServiceProgressScreen extends StatefulWidget {
  @override
  _ServiceProgressScreenState createState() => _ServiceProgressScreenState();
}

class _ServiceProgressScreenState extends State<ServiceProgressScreen> {
  final controller = Get.put(AiLabControllerPIP());

  @override
  void initState() {
    super.initState();
    // Enable PiP because service is starting
    controller.setPipStatus(true);
  }

  @override
  void dispose() {
    // Disable PiP when leaving this screen
    controller.setPipStatus(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Also trigger PiP if they click the Back button
        await controller.platformData.invokeMethod('enterPip');
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: "data",
          onBackTap: () {
            Get.back();
          },
        ),
        body: Center(child: CustomText("Welcome To PIP Mode")),
      ),
    );
  }
}

class AiLabControllerPIP extends GetxController {
  final platformData = MethodChannel('com.vahcare.lab/pip');

  // This updates the Android Master Switch
  Future<void> setPipStatus(bool isEnabled) async {
    await platformData
        .invokeMethod('updatePipStatus', {"isEnabled": isEnabled});
  }
}
