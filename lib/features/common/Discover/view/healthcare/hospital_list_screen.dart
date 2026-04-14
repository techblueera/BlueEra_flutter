import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
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
              "No hospitals found",
              fontSize: SizeConfig.medium,
              color: AppColors.grey9B,
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.primaryColor,
          onRefresh: () async {
            await controller.fetchInitial(widget.serviceType);
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
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

  bool _isEmpty(String? s) => s == null || s.trim().isEmpty;

  String _valueOr(String? s, {String fallback = "Not available"}) =>
      _isEmpty(s) ? fallback : s!.trim();

  List<String> _buildFacilities() {
    final list = <String>[];
    final ec = item.emergencyCare;
    final of = item.otherFacilities;
    if (ec?.emergencyCasualty ?? false) list.add("Emergency");
    if (ec?.traumaCare ?? false) list.add("Trauma Care");
    if (ec?.icu ?? false) list.add("ICU");
    if (ec?.ccu ?? false) list.add("CCU");
    if (ec?.nicu ?? false) list.add("NICU");
    if (ec?.picu ?? false) list.add("PICU");
    if (of?.ambulance ?? false) list.add("Ambulance");
    if (of?.bloodBank ?? false) list.add("Blood Bank");
    if (of?.diagnosticDepartments ?? false) list.add("Diagnostics");
    if (of?.medicalStore ?? false) list.add("Medical Store");
    if (of?.pmSwasthyaBimaYojana ?? false) list.add("PM Yojana");
    return list;
  }

  void _openChat() {
    final ownerId = item.userId;
    if (_isEmpty(ownerId)) return;
    final chatCtrl = getOrPut(() => ChatViewController());
    chatCtrl.checkChatConnectionAndOpenChat(
      userId: ownerId!,
      name: item.name,
      profile: item.logoUrl,
    );
  }

  String? _primaryPhone() {
    final contacts = item.contacts;
    if (contacts == null || contacts.isEmpty) return null;
    for (final c in contacts) {
      final depts = c.departments;
      if (depts == null) continue;
      for (final d in depts) {
        if (!_isEmpty(d.phone)) return d.phone;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final facilities = _buildFacilities();
    final departmentsCount = item.departments?.length ?? 0;
    final phone = _primaryPhone();
    final hasLogo = !_isEmpty(item.logoUrl);

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
      child: InkWell(
        borderRadius: BorderRadius.circular(SizeConfig.size12),
        onTap: () {
          try {
            final controller = Get.find<HospitalServiceAiController>();
            controller.hospitalDataResModel?.value =
                HospitalFullDetailsResModel(success: true, data: item);
            Get.to(DiscoverHospitalHomeScreen());
          } on Exception catch (e) {
            logs("ERROR $e");
          }
        },
        child: CommonCardWidget(
          cardMargin: 0,
          padding: SizeConfig.size12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: logo + name + address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(SizeConfig.size10),
                    child: Container(
                      width: SizeConfig.size70,
                      height: SizeConfig.size70,
                      color: AppColors.liteWhite,
                      child: hasLogo
                          ? Image.network(
                              item.logoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => LocalAssets(
                                  imagePath:
                                      AppIconAssets.place_holder_image),
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
                        CustomText(
                          _valueOr(item.name, fallback: "Unknown Hospital"),
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mainTextColor,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: SizeConfig.size4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: SizeConfig.size14,
                                color: AppColors.grey9B),
                            SizedBox(width: SizeConfig.size4),
                            Expanded(
                              child: CustomText(
                                _valueOr(item.location?.name,
                                    fallback: "Address not available"),
                                fontSize: SizeConfig.small,
                                color: AppColors.secondaryTextColor,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (!_isEmpty(phone)) ...[
                          SizedBox(height: SizeConfig.size4),
                          Row(
                            children: [
                              Icon(Icons.call_outlined,
                                  size: SizeConfig.size14,
                                  color: AppColors.primaryColor),
                              SizedBox(width: SizeConfig.size4),
                              Expanded(
                                child: CustomText(
                                  phone!,
                                  fontSize: SizeConfig.small,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: SizeConfig.size8),
                  _chatIconButton(),
                ],
              ),

              // Description
              if (!_isEmpty(item.description)) ...[
                SizedBox(height: SizeConfig.size10),
                CustomText(
                  item.description!.trim(),
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Quick stats row
              SizedBox(height: SizeConfig.size10),
              Row(
                children: [
                  _statChip(
                    icon: Icons.local_hospital_outlined,
                    label: departmentsCount > 0
                        ? "$departmentsCount Departments"
                        : "No departments",
                  ),
                  SizedBox(width: SizeConfig.size8),
                  _statChip(
                    icon: Icons.medical_services_outlined,
                    label: facilities.isNotEmpty
                        ? "${facilities.length} Facilities"
                        : "No facilities",
                  ),
                ],
              ),

              // Facilities
              SizedBox(height: SizeConfig.size10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Facilities : ",
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mainTextColor,
                  ),
                  Expanded(
                    child: facilities.isEmpty
                        ? CustomText(
                            "Not available",
                            fontSize: 12,
                            color: AppColors.grey9B,
                          )
                        : Wrap(
                            spacing: SizeConfig.size6,
                            runSpacing: SizeConfig.size6,
                            children: facilities
                                .take(4)
                                .map((t) => _facilityPill(t))
                                .toList()
                              ..addAll(facilities.length > 4
                                  ? [_facilityPill("+${facilities.length - 4}")]
                                  : []),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatIconButton() {
    final enabled = !_isEmpty(item.userId);
    return InkWell(
      onTap: enabled ? _openChat : null,
      borderRadius: BorderRadius.circular(SizeConfig.size20),
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size8),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryColor.withOpacity(0.1)
              : AppColors.liteWhite,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? AppColors.primaryColor.withOpacity(0.3)
                : AppColors.grey9B.withOpacity(0.2),
          ),
        ),
        child: Icon(
          Icons.chat_bubble_outline,
          size: SizeConfig.size18,
          color: enabled ? AppColors.primaryColor : AppColors.grey9B,
        ),
      ),
    );
  }

  Widget _statChip({required IconData icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8, vertical: SizeConfig.size4),
      decoration: BoxDecoration(
        color: AppColors.liteWhite,
        borderRadius: BorderRadius.circular(SizeConfig.size6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: SizeConfig.size14, color: AppColors.primaryColor),
          SizedBox(width: SizeConfig.size4),
          CustomText(
            label,
            fontSize: 11,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _facilityPill(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size8, vertical: SizeConfig.size4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(SizeConfig.size20),
        border:
            Border.all(color: AppColors.primaryColor.withOpacity(0.25)),
      ),
      child: CustomText(
        text,
        fontSize: 11,
        color: AppColors.primaryColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
