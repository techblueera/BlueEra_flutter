import 'dart:io';

import 'package:BlueEra/core/api/model/place_details.dart';
import 'package:BlueEra/core/common_bloc/place/repo/place_repo.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/health_camp_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/health_camp_model.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_test_models.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_location_search_field.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_check_box.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/new_common_date_selection_dropdown.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/select_product_image_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HealthCampFormScreen extends StatefulWidget {
  final HealthCamp? existing;

  const HealthCampFormScreen({super.key, this.existing});

  @override
  State<HealthCampFormScreen> createState() => _HealthCampFormScreenState();
}

class _HealthCampFormScreenState extends State<HealthCampFormScreen> {
  late final HealthCampController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<HealthCampController>()) {
      controller = Get.put(HealthCampController(), permanent: true);
    } else {
      controller = Get.find<HealthCampController>();
    }
    controller.preloadForm(widget.existing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
          title: widget.existing == null
              ? AppStrings.createHealthCamp.tr
              : AppStrings.editHealthCamp.tr),
      body: CommonCardWidget(
        child: SingleChildScrollView(
          // padding: EdgeInsets.all(SizeConfig.size16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonTextField(
                textEditController: controller.typeController,
                title: AppStrings.activityType.tr,
                hintText: AppStrings.egFreeHealthCheckup.tr,
                onChange: (val) {
                  controller.activityType.value = val;
                  controller.validateForm();
                },
              ),
              SizedBox(height: SizeConfig.size16),
              CommonTextField(
                textEditController: controller.descController,
                title: AppStrings.description.tr,
                hintText: AppStrings.describeTheCamp.tr,
                maxLine: 4,
                onChange: (val) => controller.validateForm(),
              ),
              SizedBox(height: SizeConfig.size16),
              CommonTextField(
                textEditController: controller.sqFootController,
                title: AppStrings.sqFoot.tr,
                hintText: AppStrings.labHintCampPrice.tr,
                keyBoardType: TextInputType.number,
                onChange: (val) => controller.validateForm(),
              ),
              SizedBox(height: SizeConfig.size16),
              Row(
                children: [

                  Expanded(
                    child: CommonTextField(
                      textEditController: controller.priceController,
                      title: AppStrings.price.tr,
                      hintText: AppStrings.labHintCampDiscountPrice.tr,
                      keyBoardType: TextInputType.number,
                      onChange: (val) => controller.validateForm(),
                    ),
                  ),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(
                    child: CommonTextField(
                      textEditController: controller.discountPriceController,
                      title: AppStrings.discountPrice.tr,
                      hintText: AppStrings.labHintCampDiscountedPrice.tr,
                      keyBoardType: TextInputType.number,
                      onChange: (val) => controller.validateForm(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeConfig.size16),
              CustomText(AppStrings.startDate.tr,
                  fontSize: 12, fontWeight: FontWeight.w400),
              SizedBox(height: SizeConfig.size8),
              Obx(() => NewDatePicker(
                    selectedDay: controller.startDay.value,
                    selectedMonth: controller.startMonth.value,
                    selectedYear: controller.startYear.value,
                    isFutureYear: true,
                    onDayChanged: (v) {
                      controller.startDay.value = v!;
                      controller.validateForm();
                    },
                    onMonthChanged: (v) {
                      controller.startMonth.value = v!;
                      controller.validateForm();
                    },
                    onYearChanged: (v) {
                      controller.startYear.value = v!;
                      controller.validateForm();
                    },
                  )),
              SizedBox(height: SizeConfig.size16),
              CustomText(AppStrings.endDate.tr, fontSize: 12, fontWeight: FontWeight.w400),
              SizedBox(height: SizeConfig.size8),
              Obx(() => NewDatePicker(
                    selectedDay: controller.endDay.value,
                    selectedMonth: controller.endMonth.value,
                    selectedYear: controller.endYear.value,
                    isFutureYear: true,
                    onDayChanged: (v) {
                      controller.endDay.value = v!;
                      controller.validateForm();
                    },
                    onMonthChanged: (v) {
                      controller.endMonth.value = v!;
                      controller.validateForm();
                    },
                    onYearChanged: (v) {
                      controller.endYear.value = v!;
                      controller.validateForm();
                    },
                  )),
              SizedBox(height: SizeConfig.size16),
              _buildSingleTimeDropdown(AppStrings.startTime.tr, controller.selectedTime),
              SizedBox(height: SizeConfig.size16),
              CommonLocationSearchField(
                controller: controller.searchController,
                hintText: AppStrings.labHintHappyHealth.tr,
                isShowLeading: false,
                title: AppStrings.labSearchLocationGoogle.tr,
                onSelected: (placeId, lat, lng, address) async {
                  controller.searchController.text = address;
                  //
                  try {
                    final detailsResponse = await PlaceRepo()
                        .getCompletePlaceDetails(placeId: placeId);
                    final detailsData = detailsResponse.response?.data;
                    final placeDetails =
                    PlaceDetailsResponse.fromJson(detailsData);
                    controller.lat.value=placeDetails.result?.geometry?.location?.lat??0.0;
                    controller.lng.value=placeDetails.result?.geometry?.location?.lng??0.0;
                  } catch (e) {
                    print("Error fetching place details: $e");
                  }
                  //
                  // validateAiSchoolForm();
                  // setstate(() {});
                },
              ),

              SizedBox(height: SizeConfig.size16),
              _buildImageUploadSection(),
              SizedBox(height: SizeConfig.size16),
              _buildTestCategorySection(),
              SizedBox(height: SizeConfig.size20),
              Obx(() => CustomBtn(
                    title: widget.existing == null ? AppStrings.create.tr : AppStrings.update.tr,
                    isValidate: controller.isValid.value,
                    isLoading: controller.isLoading.value,
                    onTap: controller.isValid.value
                        ? () async {
                            bool ok;
                            if (widget.existing == null) {
                              ok = await controller.createCamp();
                            } else {
                              ok =
                                  await controller.updateCamp(widget.existing!);
                            }
                            if (ok) Get.back();
                          }
                        : null,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              AppStrings.campImages.tr,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            Obx(() => CustomText(
                  "${controller.selectedImages.length}/${HealthCampController.maxImages}",
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.greyA5,
                )),
          ],
        ),
        SizedBox(height: SizeConfig.size8),
        Obx(() => Wrap(
              spacing: SizeConfig.size8,
              runSpacing: SizeConfig.size8,
              children: [
                ...List.generate(controller.selectedImages.length, (index) {
                  return _buildImageTile(controller.selectedImages[index], index);
                }),
                if (controller.selectedImages.length < HealthCampController.maxImages)
                  _buildAddImageTile(),
              ],
            )),
        SizedBox(height: SizeConfig.size4),
        Obx(() => controller.selectedImages.isEmpty
            ? CustomText(
                AppStrings.minOneImageRequired.tr,
                fontSize: 10,
                color: AppColors.red,
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildImageTile(File imageFile, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            imageFile,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => controller.removeImage(index),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(3),
              child: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageTile() {
    return GestureDetector(
      onTap: () async {
        final remaining =
            HealthCampController.maxImages - controller.selectedImages.length;
        if (remaining <= 0) return;
        final paths = await SelectProductImageDialog.showLogoDialog(
          context,
          AppStrings.addImages.tr,
          maxImages: remaining,
        );
        if (paths != null && paths.isNotEmpty) {
          controller.addImages(paths);
        }
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.greyE5, width: 1),
        ),
        child: const Icon(
          Icons.add_a_photo_outlined,
          color: AppColors.greyA5,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTestCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Add Discount Test" toggle row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              AppStrings.labAddDiscountTest.tr,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            Obx(() => Switch(
                  value: controller.addDiscountTestEnabled.value,
                onChanged: (val) {
                  controller.addDiscountTestEnabled.value = val;
                  if (val) {
                    if (controller.selectedTestCategories.isEmpty) {
                      _showAddDiscountTestBottomSheet();
                    }
                  } else {
                    controller.selectedTestCategories.clear();
                    controller.selectedTestDiscounts.clear();
                  }
                },
                  activeTrackColor: AppColors.primaryColor,
                )),
          ],
        ),
        // Selected categories as chips + "Add" tap area
        Obx(() {
          if (!controller.addDiscountTestEnabled.value) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected test discounts display
              if (controller.selectedTestDiscounts.isNotEmpty) ...[
                ...controller.selectedTestDiscounts.map((discount) {
                  return Container(
                    margin: EdgeInsets.only(bottom: SizeConfig.size8),
                    padding: EdgeInsets.all(SizeConfig.size12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.greyE5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                discount.test?.testName ?? "",
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              SizedBox(height: 4),
                              CustomText(
                                "${discount.discountValue ?? 0}% ${discount.discountType ?? 'percentage'}",
                                fontSize: 11,
                                color: AppColors.greyA5,
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller
                              .removeTestDiscount(discount.test?.id ?? ""),
                          child: const Icon(Icons.close,
                              size: 18, color: AppColors.red),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: SizeConfig.size4),
              ],
              // Add button to open category selection
              GestureDetector(
                onTap: () => _showAddDiscountTestBottomSheet(),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: Center(
                    child: CustomText(
                      AppStrings.labAddTestOffer.tr,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Step 1: Bottom sheet with 6 categories + checkboxes → "Next" button
  void _showAddDiscountTestBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(SizeConfig.size16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        AppStrings.labAddDiscountedTest.tr,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close,
                            size: 22, color: AppColors.mainTextColor),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Category list with checkboxes
                ...HealthCampController.testCategoryOptions.map((category) {
                  return Obx(() {
                    final isSelected =
                        controller.selectedTestCategories.contains(category);
                    return InkWell(
                      onTap: () => controller.toggleTestCategory(category),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeConfig.size16,
                          vertical: SizeConfig.size12,
                        ),
                        child: Row(
                          children: [
                            CustomCheckBox(
                              isChecked: isSelected,
                              onChanged: () =>
                                  controller.toggleTestCategory(category),
                              size: 22,
                              borderColor: AppColors.greyE5,
                            ),
                            SizedBox(width: SizeConfig.size12),
                            Expanded(
                              child: CustomText(
                                category,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                }),
                // "Next" button
                Padding(
                  padding: EdgeInsets.all(SizeConfig.size16),
                  child: Obx(() => CustomBtn(
                        title: AppStrings.next.tr,
                        isValidate:
                            controller.selectedTestCategories.isNotEmpty,
                        onTap: controller.selectedTestCategories.isNotEmpty
                            ? () {
                                Navigator.pop(context);
                                _showSelectTestBottomSheet();
                              }
                            : null,
                      )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Step 2: TabBar bottom sheet with selected categories as tabs,
  /// showing test catalog per tab with checkboxes + discount input
  void _showSelectTestBottomSheet() {
    // Fetch lab tests for all selected categories
    controller.fetchAllSelectedTests();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: _SelectTestTabView(controller: controller),
          ),
        );
      },
    );
  }

  Widget _buildSingleTimeDropdown(String label, RxString selectedValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(label, fontSize: 12, fontWeight: FontWeight.w400),
        const SizedBox(height: 8),
        Obx(() => SizedBox(
              width: double.infinity,
              child: _buildDropdown(HealthCampController.timeSlots, selectedValue.value,
                  (val) {
                selectedValue.value = val!;
                controller.validateForm();
              }),
            )),
      ],
    );
  }

  Widget _buildDropdown(
      List<String> items, String currentValue, Function(String?) onChanged) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: AppColors.greyE5)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(currentValue) ? currentValue : null,
          hint: CustomText(AppStrings.selectStartTime.tr),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.mainTextColor,
          ),
          isDense: true,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: AppConstants.OpenSans,
            color: AppColors.mainTextColor,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: CustomText(
                value,
                fontSize: 12,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// TabBar-based test selection view for the "Select Test" bottom sheet
class _SelectTestTabView extends StatefulWidget {
  final HealthCampController controller;

  const _SelectTestTabView({required this.controller});

  @override
  State<_SelectTestTabView> createState() => _SelectTestTabViewState();
}

class _SelectTestTabViewState extends State<_SelectTestTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  HealthCampController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: controller.selectedTestCategories.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final cat = controller.selectedTestCategories[_tabController.index];
        controller.fetchTestsForCategory(cat);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = controller.selectedTestCategories.toList();

    return Column(
      children: [
        // Header
        Padding(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                AppStrings.labSelectTest.tr,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close,
                    size: 22, color: AppColors.mainTextColor),
              ),
            ],
          ),
        ),
        // Tab bar with selected categories
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.mainTextColor,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontFamily: AppConstants.OpenSans,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontFamily: AppConstants.OpenSans,
            fontWeight: FontWeight.w400,
          ),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.primaryColor,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          tabs: categories
              .map((cat) => Tab(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(cat),
                    ),
                  ))
              .toList(),
        ),
        SizedBox(height: SizeConfig.size8),
        // Tab bar view with test catalog per tab
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: categories.map((category) {
              return _buildTestList(category);
            }).toList(),
          ),
        ),
        // "Post" button at the bottom
        Padding(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: CustomBtn(
            title: AppStrings.labPostBtn.tr,
            isValidate: true,
            onTap: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildTestList(String category) {
    return Obx(() {
      if (controller.isTestsLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      final tests = controller.getTestsForCategory(category);
      if (tests.isEmpty) {
        return Center(
          child: CustomText(
            AppStrings.labNoTestsFound.tr,
            fontSize: 14,
            color: AppColors.greyA5,
          ),
        );
      }
      return ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
        itemCount: tests.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = tests[index];
          return Obx(() {
            final isSelected = controller.isTestSelected(item.id ?? "");
            return InkWell(
              onTap: () => controller.toggleTestDiscount(item),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomCheckBox(
                      isChecked: isSelected,
                      onChanged: () => controller.toggleTestDiscount(item),
                      size: 22,
                      borderColor: AppColors.greyE5,
                    ),
                    SizedBox(width: SizeConfig.size12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            item.testName ?? "",
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          if (item.testParameters != null &&
                              item.testParameters!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: CustomText(
                                item.testParameters!
                                    .map((p) => p is TestParameter
                                        ? (p.name ?? '')
                                        : p.toString())
                                    .join(", "),
                                fontSize: 11,
                                color: AppColors.greyA5,
                                maxLines: 2,
                              ),
                            ),
                          if (item.specimen != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: CustomText(
                                "${AppStrings.labReportsWithinPrefix.tr} ${item.estimatedReportHours ?? 0} ${AppStrings.labHrsSuffix.tr} - ${item.specimen ?? ''} ${AppStrings.labSampleCollection.tr}",
                                fontSize: 10,
                                color: AppColors.greyA5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (item.testFees != null)
                          CustomText(
                            "${AppStrings.labInrSpace.tr}${item.testFees}",
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        if (item.customerPrice != null &&
                            item.customerPrice != item.testFees)
                          CustomText(
                            "${AppStrings.labInrSpace.tr}${item.customerPrice}",
                            fontSize: 10,
                            color: AppColors.greyA5,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          });
        },
      );
    });
  }
}
