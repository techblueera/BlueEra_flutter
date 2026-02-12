import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_service_ai_controller.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_service_repo.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_update_screen.dart';
import 'package:BlueEra/features/me/laboratory/view/lab_full_details_screen.dart';
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
  final labServiceAiController = getOrPut(() => LabServiceAiController());

  @override
  void initState() {
    apiCalling();
    _tabController = TabController(length: 3, vsync: this);

    super.initState();
  }

  apiCalling() async {
    try {
      if (labIDGlobal.isEmpty) {
        ResponseModel response =
            await LabServiceRepo().getLabFullDetailsByIdRepo();
        if (response.isSuccess) {
          labIDGlobal = response.response?.data['data']['profile']['_id'];
          if (labIDGlobal.isNotEmpty) {
            await setLabID(labIDGlobal);
          } else {
            labIDGlobal = "";
            await setLabID("");
          }
        } else {
          labIDGlobal = "";
          await setLabID("");
        }
      }
      await getLabID();
      labServiceAiController.hasLabCreated.value = labIDGlobal.isNotEmpty;
      setState(() {
      });
    } on Exception {
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
            child:  labServiceAiController.hasLabCreated.value
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
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.w600),
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
                          LabFullDetailsScreen(),
                          LabUpdateScreen(),
                          ComingSoon(),
                        ],
                      ))
                    ],
                  )
                : NoLabCreateScreen(),
          );
        }));
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
