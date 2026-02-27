import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/discover_hospital_home_screen.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalListScreen extends StatefulWidget {
  const HospitalListScreen({super.key, required this.serviceType});
final String serviceType;
  @override
  State<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen> {
  late final HospitalServiceAiController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = getOrPut(() => HospitalServiceAiController());
    controller.fetchInitial(widget.serviceType);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      controller.fetchMore(widget.serviceType);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Material(
      color: AppColors.appBackgroundColor,
      child: Obx(() {
        if (controller.isLoading.value && controller.profiles.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryColor));
        }
        if (controller.error.value.isNotEmpty && controller.profiles.isEmpty) {
          return Center(
            child: CustomText(
              "Failed to load data",
              fontSize: SizeConfig.medium,
              color: AppColors.red,
            ),
          );
        }
        if (controller.profiles.isEmpty) {
          return Center(
            child: CustomText(
              "No laboratories found",
              fontSize: SizeConfig.medium,
              color: AppColors.grey9B,
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: ()async{
         await   controller.fetchInitial(widget.serviceType);
          },
          child: ListView.builder(
            controller: _scrollController,
            // padding: EdgeInsets.all(SizeConfig.paddingM),
            itemCount: controller.profiles.length +
                (controller.isLoadingMore.value ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= controller.profiles.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                  child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryColor)),
                );
              }
              final item = controller.profiles[index];
              return _HospitalCard(item: item);
            },
          ),
        );
      }),
    );
  }
}

class _HospitalCard extends StatelessWidget {
  final HospitalFullData item;

  _HospitalCard({required this.item});

  List<Map<String, String>> services = [];

  @override
  Widget build(BuildContext context) {
    services = [
      if (item.emergencyCare?.emergencyCasualty ?? false)
        {
          "title": "Emergency / Casualty",
          "icon": "assets/svg/em_emergency.svg",
          "desc": ""
        },
      if (item.emergencyCare?.traumaCare ?? false)
        {
          "title": "Trauma Care",
          "icon": "assets/svg/em_trauma_care.svg",
          "desc": ""
        },
      if (item.emergencyCare?.icu ?? false)
        {
          "title": "ICU",
          "icon": "assets/svg/em_icu.svg",
          "desc": ""
        },
      if (item.emergencyCare?.ccu ?? false)
        {
          "title": "CCU",
          "icon": "assets/svg/em_ccu.svg",
          "desc": ""
        },
      if (item.emergencyCare?.nicu ?? false)
        {
          "title": "NICU",
          "icon": "assets/svg/em_nicu.svg",
          "desc": ""
        },
      if (item.emergencyCare?.picu ?? false)
        {
          "title": "PICU",
          "icon": "assets/svg/em_picu.svg",
          "desc": ""
        },
      if (item.otherFacilities?.ambulance ?? false)
        {"title": "Ambulance", "icon": AppIconAssets.Ambulance, "desc": ""},
      if (item.otherFacilities?.diagnosticDepartments ?? false)
        {
          "title": "Diagnostic Departments",
          "icon": AppIconAssets.diag_dept_view,
          "desc": ""
        },
      if (item.otherFacilities?.medicalStore ?? false)
        {
          "title": "Medical Store",
          "icon": AppIconAssets.medical_view,
          "desc": ""
        },
      if (item.otherFacilities?.pmSwasthyaBimaYojana ?? false)
        {
          "title": "PM Swasthya Bima Yojana",
          "icon": AppIconAssets.PMYojana,
          "desc": ""
        },
    ];
    return Padding(
      padding: const EdgeInsets.only(right: 10.0, bottom: 15, left: 8),
      child: InkWell(
        onTap: () {
          try {
            final controller = Get.find<HospitalServiceAiController>();
            controller.hospitalDataResModel?.value =
                HospitalFullDetailsResModel(success: true, data: item);
            Get.to(DiscoverHospitalHomeScreen());
          } on Exception catch (e) {
            logs("ERROR $e");
            // TODO
          }
        },
        child: CommonCardWidget(
          cardMargin: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SizeConfig.size12),
                    child: Container(
                      width: SizeConfig.size60,
                      height: SizeConfig.size60,
                      color: AppColors.liteWhite,
                      child: item.logoUrl?.isNotEmpty ?? false
                          ? Image.network(
                              item.logoUrl ?? "",
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => LocalAssets(
                                  imagePath: AppIconAssets.place_holder_image),
                            )
                          : LocalAssets(
                              imagePath: AppIconAssets.place_holder_image),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                (item.name?.isNotEmpty ?? false)
                                    ? item.name
                                    : "Unknown",
                                fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mainTextColor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size6),
                        CustomText(
                          "Address : ${item.location?.name}",
                          fontSize: SizeConfig.small,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size6),
              // SizedBox(height: SizeConfig.size6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText("Our Facility : ",fontSize: 12,fontWeight: FontWeight.w600,),

                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.start,
                      children: List.generate(services.take(3).length, (index) {
                        // 1. Store the title
                        final String title = services[index]['title'] ?? "";

                        // 2. Check if this is the last item in the generated list
                        final bool isLast = index == services.take(3).length - 1;

                        // 3. Conditionally append the separator
                        return CustomText(
                          isLast ? title : "$title | ",
                          fontSize: 12,
                        );
                      }),
                    ),
                  )
                  // Expanded(
                  //   child: Wrap(
                  //     crossAxisAlignment: WrapCrossAlignment.start,
                  //     children: List.generate(services.take(3).length, (index) {
                  //       return CustomText("${services[index]['title'] ?? " "} | ",fontSize: 12,);
                  //     }),
                  //   ),
                  // ),
                ],
              )
              // ExpandableText(
              //   text: item.description ?? "",
              //   trimLines: 1,
              //   isReadMoreNewLine: false,
              //   expandMode: ExpandMode.dialog,
              //   style: TextStyle(
              //     color: AppColors.secondaryTextColor,
              //     fontSize: SizeConfig.small,
              //     fontWeight: FontWeight.w400,
              //     fontFamily: AppConstants.OpenSans,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
