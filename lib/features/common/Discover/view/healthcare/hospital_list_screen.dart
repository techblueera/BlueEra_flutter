import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/Discover/view/healthcare/discover_hospital_home_screen.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalListScreen extends StatefulWidget {
  const HospitalListScreen({super.key});

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
    controller.fetchInitial();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      controller.fetchMore();
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
          onRefresh: controller.fetchInitial,
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

  const _HospitalCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0, bottom: 15, left: 8),
      child: InkWell(
        onTap: () {
          final controller = Get.find<HospitalServiceAiController>();
          controller.hospitalDataResModel?.value =
              HospitalFullDetailsResModel(success: true, data: item);
          Get.to(DiscoverHospitalHomeScreen());
        },
        child: CommonCardWidget(
          cardMargin: 0,
          child: Column(
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
              ExpandableText(
                text: item.description ?? "",
                trimLines: 1,
                isReadMoreNewLine: false,
                expandMode: ExpandMode.dialog,
                style: TextStyle(
                  color: AppColors.secondaryTextColor,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  fontFamily: AppConstants.OpenSans,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
