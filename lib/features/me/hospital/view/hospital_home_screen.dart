import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/business_location_widget.dart';
import 'package:BlueEra/features/me/hospital/controller/hospital_service_ai_controller.dart';
import 'package:BlueEra/features/me/hospital/model/hospital_full_details_res_model.dart';
import 'package:BlueEra/features/me/hospital/view/about_us/hospital_about_us.dart';
import 'package:BlueEra/features/me/hospital/view/emergency/hospital_emergency_care_screen.dart';
import 'package:BlueEra/features/me/hospital/view/gallery/hospital_photos_screen.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_contact_us/hospital_contact_us.dart';
import 'package:BlueEra/features/me/hospital/view/hospital_job_listing_screen.dart';
import 'package:BlueEra/features/me/hospital/view/ipd/hospital_ipd_screen.dart';
import 'package:BlueEra/features/me/hospital/view/opd/hospital_opd_screen.dart';
import 'package:BlueEra/features/me/hospital/view/opd/opd_doctor_list_screen.dart';
import 'package:BlueEra/features/me/hospital/view/ipd/ipd_ward_list_screen.dart';
import 'package:BlueEra/features/me/hospital/view/other_facilities/hospital_other_facilities_screen.dart';
import 'package:BlueEra/features/me/hospital/view/widget/hospital_header_view.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HospitalHomeScreen extends StatefulWidget {
  const HospitalHomeScreen({super.key});

  @override
  State<HospitalHomeScreen> createState() => _HospitalHomeScreenState();
}

class _HospitalHomeScreenState extends State<HospitalHomeScreen> {
  final controller = Get.find<HospitalServiceAiController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        controller.hospitalDataResModel?.value;
        final data = controller.hospitalDataResModel?.value.data;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(SizeConfig.size12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── HEADER ──
                HospitalHeaderView(isReadOnly: false),

                // ── DESCRIPTION ──
                SizedBox(height: SizeConfig.size12),
                _buildDescriptionSection(data),

                // ── OPD DEPARTMENTS ──
                SizedBox(height: SizeConfig.size12),
                _buildOpdSection(data),

                // ── IPD DEPARTMENTS ──
                SizedBox(height: SizeConfig.size12),
                _buildIpdSection(data),

                // ── EMERGENCY CARE ──
                SizedBox(height: SizeConfig.size12),
                _buildEmergencyCareSection(data),

                // ── OTHER FACILITIES ──
                SizedBox(height: SizeConfig.size12),
                _buildOtherFacilitiesSection(data),

                // ── MANAGEMENT ──
                SizedBox(height: SizeConfig.size12),
                _buildManagementSection(data),

                // ── GALLERY ──
                SizedBox(height: SizeConfig.size12),
                _buildGallerySection(data, context),

                // ── CAREERS ──
                SizedBox(height: SizeConfig.size12),
                _buildCareersSection(),

                // ── CONTACT US ──
                SizedBox(height: SizeConfig.size12),
                _buildContactUsSection(data),

                // ── LOCATION ──
                SizedBox(height: SizeConfig.size12),
                _buildLocationSection(data),

                SizedBox(height: kBottomNavigationBarHeight + 30),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════
  // DESCRIPTION
  // ═══════════════════════════════════════════════════════
  Widget _buildDescriptionSection(HospitalFullData? data) {
    final description = data?.description ?? '';
    final visionMission = data?.visionMission?.visionAndMission ?? '';
    final history = data?.history?.history ?? '';
    final hasData =
        description.isNotEmpty || visionMission.isNotEmpty || history.isNotEmpty;

    if (!hasData) {
      return _emptySection(
        title: AppStrings.aboutUs.tr,
        subtitle: "Add about us details for your hospital",
        icon: Icons.description_outlined,
        onEdit: () => Get.to(() => const HospitalAboutUsScreen())
            ?.then((_) => _refresh()),
      );
    }

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.aboutUs.tr, fontWeight: FontWeight.w700),
              _editButton(
                onTap: () => Get.to(() => const HospitalAboutUsScreen())
                    ?.then((_) => _refresh()),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          if (description.isNotEmpty)
            CustomText(
              description,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          if (visionMission.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size8),
            CustomText(
              visionMission,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ],
          if (history.isNotEmpty) ...[
            SizedBox(height: SizeConfig.size8),
            CustomText(
              history,
              fontSize: 14,
              color: AppColors.secondaryTextColor,
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // OPD
  // ═══════════════════════════════════════════════════════
  Widget _buildOpdSection(HospitalFullData? data) {
    final opdDepts = controller.filteredOpdDepartments;

    if (opdDepts.isEmpty) {
      return _emptySection(
        title: AppStrings.opdTitle.tr,
        subtitle: "Add OPD departments and doctors",
        icon: Icons.local_hospital_outlined,
        onEdit: () =>
            Get.to(() => const HospitalOpdScreen())?.then((_) => _refresh()),
      );
    }

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.opdTitle.tr, fontWeight: FontWeight.w700),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add New button — navigates to doctor list for selected dept
                  Obx(() {
                    final selectedDept = opdDepts.isNotEmpty &&
                            controller.selectedDeptIndex.value < opdDepts.length
                        ? opdDepts[controller.selectedDeptIndex.value]
                        : null;
                    return _addNewButton(
                      onTap: () {
                        if (selectedDept != null) {
                          Get.to(() => OpdDoctorListScreen(
                                departmentId: selectedDept.id ?? '',
                                hospitalId: selectedDept.hospitalId,
                              ))?.then((_) => _refresh());
                        }
                      },
                    );
                  }),
                  const SizedBox(width: 8),
                  _editButton(
                    onTap: () => Get.to(() => const HospitalOpdScreen())
                        ?.then((_) => _refresh()),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          // Department chips
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(opdDepts.length, (index) {
                    final dept = opdDepts[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: CustomText(
                          dept.name ?? "",
                          color: controller.selectedDeptIndex.value == index
                              ? AppColors.white
                              : AppColors.secondaryTextColor,
                          fontSize: SizeConfig.small,
                        ),
                        showCheckmark: false,
                        selectedColor: AppColors.primaryColor,
                        backgroundColor: Colors.transparent,
                        selected: controller.selectedDeptIndex.value == index,
                        onSelected: (val) {
                          if (val) controller.selectedDeptIndex.value = index;
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: controller.selectedDeptIndex.value == index
                              ? AppColors.primaryColor
                              : Colors.grey.shade400,
                          width: 1,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    );
                  }),
                ),
              )),
          SizedBox(height: SizeConfig.size10),
          // Doctor cards — tappable to navigate to doctor list
          Obx(() {
            final selectedIdx = controller.selectedDeptIndex.value;
            final selectedDept =
                selectedIdx < opdDepts.length ? opdDepts[selectedIdx] : null;
            final items = controller.currentCategoryItems;

            if (items.isEmpty) {
              return InkWell(
                onTap: () {
                  if (selectedDept != null) {
                    Get.to(() => OpdDoctorListScreen(
                          departmentId: selectedDept.id ?? '',
                          hospitalId: selectedDept.hospitalId,
                        ))?.then((_) => _refresh());
                  }
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 32, color: AppColors.greyA5),
                        SizedBox(height: SizeConfig.size8),
                        CustomText("Tap to add doctors",
                            color: AppColors.greyA5, fontSize: 13),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return InkWell(
                    onTap: () {
                      if (selectedDept != null) {
                        Get.to(() => OpdDoctorListScreen(
                              departmentId: selectedDept.id ?? '',
                              hospitalId: selectedDept.hospitalId,
                            ))?.then((_) => _refresh());
                      }
                    },
                    child: _doctorCard(
                      name: item.name ?? "",
                      imageUrl: item.imageUrl,
                      tag: item.timing ?? "",
                      description: item.description ?? "",
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // IPD
  // ═══════════════════════════════════════════════════════
  Widget _buildIpdSection(HospitalFullData? data) {
    final ipdDepts = controller.filteredIpdDepartments;

    if (ipdDepts.isEmpty) {
      return _emptySection(
        title: AppStrings.ipdTitle.tr,
        subtitle: "Add IPD wards and bed details",
        icon: Icons.bed_outlined,
        onEdit: () =>
            Get.to(() => const IpdWardListScreen(departmentId: '',),)?.then((_) => _refresh()),
            // Get.to(() => const HospitalIpdScreen())?.then((_) => _refresh()),
      );
    }

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.ipdTitle.tr, fontWeight: FontWeight.w700),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    final selectedDept = ipdDepts.isNotEmpty &&
                            controller.selectedIpdDeptIndex.value <
                                ipdDepts.length
                        ? ipdDepts[controller.selectedIpdDeptIndex.value]
                        : null;
                    return _addNewButton(
                      onTap: () {
                        if (selectedDept != null) {
                          Get.to(() => IpdWardListScreen(
                                departmentId: selectedDept.id ?? '',
                                hospitalId: selectedDept.hospitalId,
                              ))?.then((_) => _refresh());
                        }
                      },
                    );
                  }),
                  const SizedBox(width: 8),
                  _editButton(
                    onTap: () =>

                        Get.to(() =>  IpdWardListScreen(departmentId: '',))
                        ?.then((_) => _refresh()),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          // Department chips
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(ipdDepts.length, (index) {
                    final dept = ipdDepts[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: CustomText(
                          dept.name ?? "",
                          color:
                              controller.selectedIpdDeptIndex.value == index
                                  ? AppColors.white
                                  : AppColors.secondaryTextColor,
                          fontSize: SizeConfig.small,
                        ),
                        showCheckmark: false,
                        selectedColor: AppColors.primaryColor,
                        backgroundColor: Colors.transparent,
                        selected:
                            controller.selectedIpdDeptIndex.value == index,
                        onSelected: (val) {
                          if (val)
                            controller.selectedIpdDeptIndex.value = index;
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color:
                              controller.selectedIpdDeptIndex.value == index
                                  ? AppColors.primaryColor
                                  : Colors.grey.shade400,
                          width: 1,
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                      ),
                    );
                  }),
                ),
              )),
          SizedBox(height: SizeConfig.size10),
          // Ward cards — tappable to navigate to ward list
          Obx(() {
            final selectedIdx = controller.selectedIpdDeptIndex.value;
            final selectedDept =
                selectedIdx < ipdDepts.length ? ipdDepts[selectedIdx] : null;
            final items = controller.currentCategoryItemsIpd;

            if (items.isEmpty) {
              return InkWell(
                onTap: () {
                  if (selectedDept != null) {
                    Get.to(() => IpdWardListScreen(
                          departmentId: selectedDept.id ?? '',
                          hospitalId: selectedDept.hospitalId,
                        ))?.then((_) => _refresh());
                  }
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 32, color: AppColors.greyA5),
                        SizedBox(height: SizeConfig.size8),
                        CustomText("Tap to add wards",
                            color: AppColors.greyA5, fontSize: 13),
                      ],
                    ),
                  ),
                ),
              );
            }
            return SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return InkWell(
                    onTap: () {
                      if (selectedDept != null) {
                        Get.to(() => IpdWardListScreen(
                              departmentId: selectedDept.id ?? '',
                              hospitalId: selectedDept.hospitalId,
                            ))?.then((_) => _refresh());
                      }
                    },
                    child: _doctorCard(
                      name: item.name ?? "",
                      imageUrl: item.imageUrl,
                      tag: "${item.bedCount ?? 0} ${AppStrings.beds.tr}",
                      description: item.description ?? "",
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // EMERGENCY CARE
  // ═══════════════════════════════════════════════════════
  Widget _buildEmergencyCareSection(HospitalFullData? data) {
    final ec = data?.emergencyCare;
    final chips = <String>[];
    if (ec?.emergencyCasualty ?? false) chips.add("Emergency / Casualty");
    if (ec?.traumaCare ?? false) chips.add("Trauma Care");
    if (ec?.icu ?? false) chips.add("ICU");
    if (ec?.ccu ?? false) chips.add("CCU");
    if (ec?.nicu ?? false) chips.add("NICU");
    if (ec?.picu ?? false) chips.add("PICU");

    if (chips.isEmpty) {
      return _emptySection(
        title: AppStrings.emergencyCare.tr,
        subtitle: "Add emergency care services",
        icon: Icons.emergency_outlined,
        onEdit: () => Get.to(() => const HospitalEmergencyCareScreen())
            ?.then((_) => _refresh()),
      );
    }

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.emergencyCare.tr,
                  fontWeight: FontWeight.w700),
              _editButton(
                onTap: () => Get.to(() => const HospitalEmergencyCareScreen())
                    ?.then((_) => _refresh()),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((c) => _chip(c)).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // OTHER FACILITIES
  // ═══════════════════════════════════════════════════════
  Widget _buildOtherFacilitiesSection(HospitalFullData? data) {
    final of = data?.otherFacilities;
    final chips = <String>[];
    if (of?.ambulance ?? false) chips.add("Ambulance");
    if (of?.bloodBank ?? false) chips.add("Blood Bank");
    if (of?.diagnosticDepartments ?? false) chips.add("Diagnostic Departments");
    if (of?.medicalStore ?? false) chips.add("Medical Store");
    if (of?.pmSwasthyaBimaYojana ?? false) chips.add("PM Swasthya Bima Yojana");
    if (of?.cashlessInsurance?.isNotEmpty ?? false) chips.add("Cashless Insurance");

    if (chips.isEmpty) {
      return _emptySection(
        title: AppStrings.otherFacilities.tr,
        subtitle: "Add other facilities like ambulance, blood bank etc.",
        icon: Icons.medical_services_outlined,
        onEdit: () => Get.to(() => const HospitalOtherFacilitiesScreen())
            ?.then((_) => _refresh()),
      );
    }

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.otherFacilities.tr,
                  fontWeight: FontWeight.w700),
              _editButton(
                onTap: () =>
                    Get.to(() => const HospitalOtherFacilitiesScreen())
                        ?.then((_) => _refresh()),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((c) => _chip(c)).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MANAGEMENT
  // ═══════════════════════════════════════════════════════
  Widget _buildManagementSection(HospitalFullData? data) {
    final managementList = data?.management ?? [];

    if (managementList.isEmpty) {
      return _emptySection(
        title: AppStrings.managementTrust.tr,
        subtitle: "Add management & trust member details",
        icon: Icons.people_outline,
        onEdit: () => Get.to(() => const HospitalAboutUsScreen())
            ?.then((_) => _refresh()),
      );
    }

    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(AppStrings.managementTrust.tr,
                  fontWeight: FontWeight.w700),
              _editButton(
                onTap: () => Get.to(() => const HospitalAboutUsScreen())
                    ?.then((_) => _refresh()),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: managementList.length > 5 ? 5 : managementList.length,
              separatorBuilder: (_, __) => SizedBox(width: SizeConfig.size10),
              itemBuilder: (context, index) {
                final person = managementList[index];
                return _managementCard(person);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // GALLERY
  // ═══════════════════════════════════════════════════════
  Widget _buildGallerySection(HospitalFullData? data, BuildContext context) {
    final galleries = data?.gallery ?? [];
    final List<String> allImages =
        galleries.expand((photo) => photo.images ?? <String>[]).toList();

    return CommonCardWidget(
      cardMargin: 0,
      padding: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(AppStrings.gallery.tr,
                      fontWeight: FontWeight.w700),
                ),
                InkWell(
                  onTap: _navigateToGalleryEdit,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          if (allImages.isNotEmpty)
            _buildGalleryGrid(allImages, context)
          else
            _emptyGalleryPlaceholder(),
        ],
      ),
    );
  }

  void _navigateToGalleryEdit() {
    Get.to(() => HospitalPhotosScreen())?.then((_) => _refresh());
  }

  Widget _emptyGalleryPlaceholder() {
    return InkWell(
      onTap: _navigateToGalleryEdit,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.image, size: 28, color: Color(0xFFBDBDBD)),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(List<String> images, BuildContext context) {
    final count = images.length;
    final hasMore = count > 4;

    Widget imageTile(int index, {double? height}) {
      return InkWell(
        onTap: () => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: images,
            initialIndex: index,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: images[index],
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: Colors.grey[200]),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
      );
    }

    Widget viewMoreOverlay(int index) {
      return InkWell(
        onTap: () => navigatePushTo(
          context,
          ImageViewScreen(
            subTitle: AppStrings.imageViewer,
            appBarTitle: AppStrings.imageViewer,
            imageUrls: images,
            initialIndex: 0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) =>
                    Container(color: Colors.grey[200]),
              ),
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: CustomText(
                    "+${count - 3}",
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (count == 1) {
      return imageTile(0, height: 200);
    }
    if (count == 2) {
      return SizedBox(
        height: 160,
        child: Row(
          children: [
            Expanded(child: imageTile(0, height: 160)),
            const SizedBox(width: 6),
            Expanded(child: imageTile(1, height: 160)),
          ],
        ),
      );
    }
    if (count == 3) {
      return SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(flex: 1, child: imageTile(0, height: 200)),
            const SizedBox(width: 6),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: imageTile(1)),
                  const SizedBox(height: 6),
                  Expanded(child: imageTile(2)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      height: 260,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: imageTile(0)),
                const SizedBox(width: 6),
                Expanded(child: imageTile(1)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(child: imageTile(2)),
                const SizedBox(width: 6),
                Expanded(
                    child: hasMore ? viewMoreOverlay(3) : imageTile(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // CAREERS
  // ═══════════════════════════════════════════════════════
  Widget _buildCareersSection() {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(AppStrings.careers.tr, fontWeight: FontWeight.w700),
          _editButton(
            onTap: () => Get.to(
                () => const HospitalJobListingScreen(isReadOnly: false)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // CONTACT US
  // ═══════════════════════════════════════════════════════
  Widget _buildContactUsSection(HospitalFullData? data) {
    final contacts = data?.contacts ?? [];

    if (contacts.isEmpty) {
      return _emptySection(
        title: AppStrings.contactUs.tr,
        subtitle: "Add contact information for your hospital",
        icon: Icons.contact_phone_outlined,
        onEdit: () => Get.to(() => const HospitalContactUs())
            ?.then((_) => _refresh()),
      );
    }

    return _buildContactCard(data, contacts);
  }

  Widget _buildContactCard(
      HospitalFullData? data, List<HospitalContacts> contacts) {
    final firstContact = contacts.firstOrNull;
    return CommonCardWidget(
      padding: 5,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 6, right: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(AppStrings.contactUs.tr,
                    fontWeight: FontWeight.bold),
                _editButton(
                  onTap: () => Get.to(() => const HospitalContactUs())
                      ?.then((_) => _refresh()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and Name
                if ((data?.logoUrl ?? '').isNotEmpty)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10)
                      ],
                      image: DecorationImage(
                          image: NetworkImage(data?.logoUrl ?? ''),
                          fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 10),
                CustomText(data?.name,
                    fontSize: 20, fontWeight: FontWeight.bold),
                const SizedBox(height: 5),
                CustomText(
                  data?.description ?? "",
                  color: Colors.grey,
                  fontSize: 14,
                ),
                const Divider(height: 30),

                // Contact items
                if ((firstContact?.branch?.website ?? '').isNotEmpty)
                  _contactItem(AppIconAssets.website_click,
                      firstContact!.branch!.website!, Colors.blue),
                _contactItem(AppIconAssets.principal,
                    AppStrings.reception.tr, Colors.grey[700]!),
                ...contacts.expand((contact) {
                  return (contact.departments ?? []).map((dept) {
                    return Column(
                      children: [
                        if ((dept.email ?? '').isNotEmpty)
                          _contactItem(AppIconAssets.email, dept.email!,
                              AppColors.secondaryTextColor),
                        if ((dept.phone ?? '').isNotEmpty)
                          _contactItem(AppIconAssets.phone_outline,
                              dept.phone!, AppColors.secondaryTextColor),
                      ],
                    );
                  });
                }),
                if ((firstContact?.branch?.location?.name ?? '').isNotEmpty)
                  _contactItem(AppIconAssets.location_new,
                      firstContact!.branch!.location!.name!, Colors.grey[700]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // LOCATION MAP
  // ═══════════════════════════════════════════════════════
  Widget _buildLocationSection(HospitalFullData? data) {
    final contacts = data?.contacts;
    if (contacts == null || contacts.isEmpty) return const SizedBox.shrink();

    final coords = contacts.firstOrNull?.branch?.location?.coordinates;
    if (coords == null || coords.length < 2) return const SizedBox.shrink();

    final lng = coords[0];
    final lat = coords[1];
    if (lat == 0.0 && lng == 0.0) return const SizedBox.shrink();

    return BusinessLocationWidget(
      locationText: contacts.firstOrNull?.branch?.location?.name,
      latitude: lat,
      longitude: lng,
      businessName: data?.name ?? "",
      padding: 0,
      isTitleShow: true,
    );
  }

  // ═══════════════════════════════════════════════════════
  // REUSABLE WIDGETS (same as Lab pattern)
  // ═══════════════════════════════════════════════════════

  Widget _emptySection({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onEdit,
  }) {
    return CommonCardWidget(
      padding: 10,
      cardMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(title, fontWeight: FontWeight.w700),
              if (onEdit != null) _editButton(onTap: onEdit),
            ],
          ),
          SizedBox(height: SizeConfig.size16),
          Center(
            child: Column(
              children: [
                Icon(icon, size: 40, color: AppColors.greyA5),
                SizedBox(height: SizeConfig.size8),
                CustomText(
                  subtitle,
                  fontSize: 13,
                  color: AppColors.greyA5,
                  textAlign: TextAlign.center,
                ),
                if (onEdit != null) ...[
                  SizedBox(height: SizeConfig.size12),
                  InkWell(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomText(
                        AppStrings.create.tr,
                        fontSize: 13,
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                SizedBox(height: SizeConfig.size8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addNewButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: AppColors.white),
            SizedBox(width: 4),
            CustomText(
              AppStrings.addNew.tr,
              fontSize: 12,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _editButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined,
                size: 14, color: AppColors.primaryColor),
            SizedBox(width: 4),
            CustomText(
              AppStrings.edit.tr,
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffEAF2FF),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: CustomText(text, fontSize: SizeConfig.small),
    );
  }

  Widget _contactItem(String icon, String label, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          LocalAssets(imagePath: icon, imgColor: iconColor),
          const SizedBox(width: 12),
          Expanded(
              child: CustomText(label, fontSize: 15, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _doctorCard({
    required String name,
    String? imageUrl,
    required String tag,
    required String description,
  }) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey[200]),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child:
                            const Center(child: Icon(Icons.person, size: 40)),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child:
                          const Center(child: Icon(Icons.person, size: 40)),
                    ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      name,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tag.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomText(tag,
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      CustomText(
                        description,
                        color: Colors.white70,
                        fontSize: SizeConfig.small,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _managementCard(HospitalManagement person) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: person.imageUrl ?? "",
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200]),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.person, size: 40)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      person.name ?? "",
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: CustomText(
                        person.position ?? "",
                        color: Colors.white70,
                        fontSize: 11,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    await controller.getHospitalFullDetailsController();
    if (mounted) setState(() {});
  }
}
