import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/common/auth/views/dialogs/select_profile_picture_dialog.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/controller/booking_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/availability_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/widget/availability_schedule_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/controller/self_work_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/service_selection_screen.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/expandable_text.dart';
import 'package:BlueEra/widgets/image_view_screen.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:BlueEra/widgets/visiting_hour_selector.dart';
import 'package:croppy/croppy.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfessionDetailsScreen extends StatefulWidget {

  const ProfessionDetailsScreen({Key? key}) : super(key: key);

  @override
  State<ProfessionDetailsScreen> createState() => _ProfessionDetailsScreenState();
}

class _ProfessionDetailsScreenState extends State<ProfessionDetailsScreen> {
  final controller = getOrPut(() => SelfWorkServiceController());
  final bookingController = getOrPut(() => BookingController());

  @override
  void initState() {
    controller.fetchSelfProfessionData();
    super.initState();
  }

  @override
  dispose(){
    super.dispose();
    deleteIfRegistered<SelfWorkServiceController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(),
      body: Obx(() {
        // 1. Loading State
        if (this.controller.isProfessionDataLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
        }

        // 3. Success State (Your UI)
        final service = this.controller.professionData.value;
        this.controller.serviceId = service.sId;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              vertical: SizeConfig.size15,
              horizontal: SizeConfig.size8
          ),
          child: SafeArea(
            child: Column(
              children: [
                // --- Profile Card ---
                CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          // Navigate to details
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(10.0)),
                              child: CachedNetworkImage(
                                imageUrl: service.providerDetails?.profileImage ?? '',
                                width: SizeConfig.screenWidth,
                                height: SizeConfig.size150,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  width: SizeConfig.screenWidth,
                                  height: SizeConfig.size150,
                                  color: Colors.grey[300],
                                ),
                                errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    size: SizeConfig.size150 / 2),
                              ),
                            ),
                            Positioned(
                                left: 20,
                                bottom: -(SizeConfig.size40),
                                child: Container(
                                  padding: const EdgeInsets.all(3.0),
                                  decoration: BoxDecoration(
                                      color: AppColors.white,
                                      shape: BoxShape.circle),
                                  child: CachedAvatarWidget(
                                    imageUrl: service.providerDetails?.profileImage ?? '',
                                    size: SizeConfig.size80,
                                    borderColor: Colors.white,
                                    borderRadius: SizeConfig.size40,
                                  ),
                                ))
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size60),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: CustomText(
                                  service.providerDetails?.name ?? AppStrings.na,
                                  fontSize: SizeConfig.large,
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: SizeConfig.size8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: SizeConfig.size3,
                                horizontal: SizeConfig.size10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                    color: AppColors.secondaryTextColor, width: 0.5),
                              ),
                              child: CustomText(
                                  service.category ?? AppStrings.na,
                                  fontSize: SizeConfig.small,
                                  color: AppColors.secondaryTextColor,
                                  fontWeight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: SizeConfig.size12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
                        child: ExpandableText(
                         text: service.providerDetails?.bio ?? AppStrings.na,
                          trimLines: 3,
                          expandMode: ExpandMode.dialog,
                          style: TextStyle(
                            color: AppColors.mainTextColor,
                            fontFamily: AppConstants.OpenSans,
                            fontWeight: FontWeight.w400,
                            fontSize: SizeConfig.medium,
                          ),
                        ),
                      ),
                      SizedBox(height: SizeConfig.size10),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.paddingM),

                 // --- Price ---
                CustomFormCard(
              padding: _innerPadding(),
              child: Obx(() {
                final details = bookingController.availabilityDetails.value?.feeDetails;

                final min = details?.minFee?.toString() ?? '0';
                final max = details?.maxFee?.toString() ?? '0';
                final feeType = details?.feeType ?? '';

                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _buildTitle('${AppStrings.price.tr}: ')),

                        _editIcon(
                          onTap: () => updateBookingPrice(
                            controller: bookingController,
                            minFee: min,
                            maxFee: max,
                            feeType: feeType
                          ),
                        )
                      ],
                    ),

                    _buildCommonDivider(),
                    SizedBox(height: SizeConfig.size8),

                    // 3. Display the live data
                    CustomText(
                      '₹$min - ₹$max',
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                  ],
                );
              }),
            ),

                SizedBox(height: SizeConfig.paddingM),

                // --- Service Type ---
                CustomFormCard(
                  padding: _innerPadding(),
                  margin: EdgeInsets.only(bottom: SizeConfig.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildTitle('Service Type')),
                          _editIcon(onTap: (){
                            updateServiceType(
                                controller: this.controller,
                                serviceType: service.serviceType ?? [],
                                designation: service.category ?? ELECTRICIAN
                            );
                           }
                          )
                        ],
                      ),
                      // SizedBox(height: SizeConfig.size8),
                      _buildCommonDivider(),
                      SizedBox(height: SizeConfig.size8),
                      (service.serviceType?.isNotEmpty ?? false)
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: service.serviceType!.map((service) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0), // Spacing between items
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Bullet Point
                                CustomText(
                                  "• ",
                                  fontSize: SizeConfig.medium,
                                  color: AppColors.mainTextColor,
                                  fontWeight: FontWeight.bold,
                                ),

                                // The Text
                                Expanded(
                                  child: CustomText(
                                    service,
                                    fontSize: SizeConfig.small,
                                    color: AppColors.secondaryTextColor,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                          :  CustomText(
                        AppStrings.na,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      )
                    ],
                  ),
                ),

                // --- Service Description ---
                CustomFormCard(
                  padding: _innerPadding(),
                  margin: EdgeInsets.only(bottom: SizeConfig.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildTitle('Service Description')),
                          _editIcon(onTap: (){
                            updateServiceDescription(
                              controller: this.controller,
                              desc: service.description ?? AppStrings.na,
                              designation: service.category ?? ELECTRICIAN,
                              experienceStartingDate: service.experienceStartDate
                            );
                           }
                          )
                        ],
                      ),
                      // SizedBox(height: SizeConfig.size8),
                      _buildCommonDivider(),
                      SizedBox(height: SizeConfig.size8),
                      CustomText(
                        service.description ?? AppStrings.na,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),

                // --- Timing ---
                  CustomFormCard(
                    padding: _innerPadding(),
                    margin: EdgeInsets.only(bottom: SizeConfig.paddingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: _buildTitle('Timing')),
                            _editIcon(onTap: ()=> updateVisitingHours(
                                controller: bookingController,
                                availabilityData: bookingController.availabilityDetails.value
                            ))
                          ],
                        ),
                        _buildCommonDivider(),
                        SizedBox(height: SizeConfig.size8),
                        bookingController.availabilityDetails.value!=null
                            ? AvailabilityScheduleCard(schedule: bookingController.availabilityDetails.value?.schedule ?? [])
                            : CustomText(
                          AppStrings.na,
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),

                // --- Work Experience ---
                CustomFormCard(
                  padding: _innerPadding(),
                  margin: EdgeInsets.only(bottom: SizeConfig.paddingM),
                  child: Builder(
                    builder: (BuildContext context) {
                      int years = 0;
                      int months = 0;
                      bool hasExperience = false;

                      final startDate = service.experienceStartDate;

                      if (startDate != null && startDate.isNotEmpty) {
                        final expData = calculateExperience(startDate);
                        years = expData['years'] ?? 0;
                        months = expData['months'] ?? 0;
                        hasExperience = true;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _buildTitle('Work Experience')),

                              // Now 'years' and 'months' are accessible here!
                              _editIcon(
                                onTap: () => updateWorkExperience(
                                  controller: this.controller,
                                  years: years,
                                  months: months,
                                ),
                              )
                            ],
                          ),

                          _buildCommonDivider(),
                          SizedBox(height: SizeConfig.size8),

                          // Display Text
                          CustomText(
                            hasExperience
                                ? '$years Years $months Months'
                                : AppStrings.na,
                            fontSize: SizeConfig.medium,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryTextColor,
                          ),
                        ],
                      );
                  },),
                ),

                // --- serviceOffered ---
                (service.serviceOffered != null && service.serviceOffered!.isNotEmpty)
                ? CustomFormCard(
                  padding: _innerPadding(),
                  margin: EdgeInsets.only(bottom: SizeConfig.paddingM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(child: _buildTitle('Service Offered')),
                          _editIcon(onTap: () {
                            updateServiceSelectionData(
                                controller: this.controller,
                                key: SelfWorkServiceController.keyServicesOffered,
                                designation: service.category,
                                preSelectedOptions: service.serviceOffered ?? []
                            );

                          })
                        ],
                      ),
                      // SizedBox(height: SizeConfig.size8),
                      _buildCommonDivider(),
                      SizedBox(height: SizeConfig.size8),
                       Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          service.serviceOffered!.length,
                              (index) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin:
                                  const EdgeInsets.only(top: 6.0, right: 8.0),
                                  width: 4.0,
                                  height: 4.0,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondaryTextColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Expanded(
                                  child: CustomText(
                                    service.serviceOffered![index],
                                    fontSize: SizeConfig.medium,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ) : SizedBox(),

                // --- Expertise ---
                (service.expertise != null && service.expertise!.isNotEmpty)
                    ? CustomFormCard(
                      padding: _innerPadding(),
                      margin: EdgeInsets.only(bottom: SizeConfig.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _buildTitle('Expertise')),
                              _editIcon(onTap: () {
                                updateServiceSelectionData(
                                    controller: this.controller,
                                    key: SelfWorkServiceController.keyExpertise,
                                    designation: service.category,
                                    preSelectedOptions: service.expertise ?? []
                                );
                              })
                            ],
                          ),
                          // SizedBox(height: SizeConfig.size8),
                          _buildCommonDivider(),
                          SizedBox(height: SizeConfig.size8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              service.expertise!.length,
                                  (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin:
                                      const EdgeInsets.only(top: 6.0, right: 8.0),
                                      width: 4.0,
                                      height: 4.0,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryTextColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: CustomText(
                                        service.expertise![index],
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ) : SizedBox(),

                // --- typesOfWork ---
                (service.typesOfWork != null && service.typesOfWork!.isNotEmpty)
                    ? CustomFormCard(
                      padding: _innerPadding(),
                      margin: EdgeInsets.only(bottom: SizeConfig.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _buildTitle('Types of Installations')),
                              _editIcon(onTap: () {
                                updateServiceSelectionData(
                                    controller: this.controller,
                                    key: SelfWorkServiceController.keyTypeOfWork,
                                    designation: service.category,
                                    preSelectedOptions: service.typesOfWork ?? []
                                );
                              })
                            ],
                          ),
                          // SizedBox(height: SizeConfig.size8),
                          _buildCommonDivider(),
                          SizedBox(height: SizeConfig.size8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              service.typesOfWork!.length,
                                  (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin:
                                      const EdgeInsets.only(top: 6.0, right: 8.0),
                                      width: 4.0,
                                      height: 4.0,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryTextColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: CustomText(
                                        service.typesOfWork![index],
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ) : SizedBox(),

                // --- workCategories ---
                (service.workCategories != null && service.workCategories!.isNotEmpty)
                    ? CustomFormCard(
                      padding: _innerPadding(),
                      margin: EdgeInsets.only(bottom: SizeConfig.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _buildTitle('Work Categories')),
                              _editIcon(onTap: () {
                                updateServiceSelectionData(
                                    controller: this.controller,
                                    key: SelfWorkServiceController.keyWorkCategories,
                                    designation: service.category,
                                    preSelectedOptions: service.workCategories ?? []
                                );
                              })
                            ],
                          ),
                          // SizedBox(height: SizeConfig.size8),
                          _buildCommonDivider(),
                          SizedBox(height: SizeConfig.size8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              service.workCategories!.length,
                                  (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin:
                                      const EdgeInsets.only(top: 6.0, right: 8.0),
                                      width: 4.0,
                                      height: 4.0,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryTextColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: CustomText(
                                        service.workCategories![index],
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ) : SizedBox(),

                // --- whyChooseMe ---
                (service.whyChooseMe != null && service.whyChooseMe!.isNotEmpty)
                    ? CustomFormCard(
                      padding: _innerPadding(),
                      margin: EdgeInsets.only(bottom: SizeConfig.paddingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: _buildTitle('Why Choose Me')),
                              _editIcon(onTap: () {
                                updateServiceSelectionData(
                                    controller: this.controller,
                                    key: SelfWorkServiceController.keyWhyChooseMe,
                                    designation: service.category,
                                    preSelectedOptions: service.whyChooseMe ?? []
                                );
                              })
                            ],
                          ),
                          // SizedBox(height: SizeConfig.size8),
                          _buildCommonDivider(),
                          SizedBox(height: SizeConfig.size8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(
                              service.whyChooseMe!.length,
                                  (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin:
                                      const EdgeInsets.only(top: 6.0, right: 8.0),
                                      width: 4.0,
                                      height: 4.0,
                                      decoration: BoxDecoration(
                                        color: AppColors.secondaryTextColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Expanded(
                                      child: CustomText(
                                        service.whyChooseMe![index],
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ) : SizedBox(),

                // --- Gallery ---
                CustomFormCard(
                  padding: EdgeInsets.all(SizeConfig.size10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle('Gallery'),

                      SizedBox(height: SizeConfig.size8),
                      _buildCommonDivider(),
                      SizedBox(height: SizeConfig.size8),
                      LayoutBuilder(
                      builder: (context, constraints) {
                      final spacing = SizeConfig.size8;
                      final containerWidth = (constraints.maxWidth - (spacing * 3)) / 4;

                      return GetBuilder<SelfWorkServiceController>(
                        id: 'professionPhotos',
                        builder: (controller) {
                          final apiPhotos = service.photos ?? [];;
                          final totalCount = apiPhotos.length;
                          final emptySlots = (8 - totalCount).clamp(0, 8);

                          List<Widget> allPhotos = [];

                          // API Photos (Already uploaded)
                          for (int i = 0; i < apiPhotos.length; i++) {
                            allPhotos.add(_buildImageContainer(
                              context,
                              ValueKey(apiPhotos[i]),
                              apiPhotos[i],
                              i,
                              controller,
                              containerWidth,
                              apiPhotos,
                            ));
                          }

                          // Empty slots for remaining photos
                          for (int i = 0; i < emptySlots; i++) {
                            allPhotos.add(_buildImageContainer(
                              context,
                              ValueKey("empty_${i}"),
                              "",
                              apiPhotos.length + i,
                              controller,
                              containerWidth,
                              apiPhotos,
                            ));
                          }

                          return Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: allPhotos,
                          );
                        },
                      );
                    },
                  ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        );
      }),
    );
  }

  // void _navigateToSelection({
  //   required String key,
  //   required List<String> preSelectedOptions,
  //   String? designation,
  // }
  //     ) {
  //   selfWorkServiceController.selectedCategoryMap[key]?.assignAll(preSelectedOptions);
  //   final List<String> _preSelectedOptions = selfWorkServiceController.selectedCategoryMap[key] ?? [];
  //   final _displayTitle = selfWorkServiceController.categoryTitleMap[key] ?? key;
  //
  //   Get.to(() => ServiceSelectionScreen(
  //     controller: selfWorkServiceController,
  //     designation: designation ?? ELECTRICIAN,
  //     selectedCategoryKey: key,
  //     pageTitle: _displayTitle,
  //     preSelectedOptions: _preSelectedOptions,
  //   ));
  // }

  EdgeInsets _innerPadding() => EdgeInsets.only(
    left: SizeConfig.size10,
    right: SizeConfig.size10,
    bottom: SizeConfig.size10,
  );

 Widget _buildTitle(String title){
    return CustomText(
    title,
    fontSize: SizeConfig.medium,
    fontWeight: FontWeight.w600,
    color: AppColors.mainTextColor,
    );
 }

  Widget _buildCommonDivider(){
    return Container(
      color: AppColors.greyE5,
      height: 0.5,
      width: SizeConfig.screenWidth,
    );
  }

  Widget _editIcon({
    required VoidCallback onTap
}){
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity(horizontal: -4, vertical: -2),
      icon: LocalAssets(
        imagePath: AppIconAssets.editIcon,
        width: 14,
        height: 14,
        imgColor: AppColors.secondaryTextColor,
      ),
    );
  }

  Widget _buildImageContainer(
      BuildContext context,
      Key key,
      String? imagePath,
      int index,
      SelfWorkServiceController controller,
      double size,
      List<String> allPhotos,
      ) {
    final isEmpty = imagePath == null || imagePath.isEmpty;

    return Stack(
      key: key,
      children: [
        GestureDetector(
          onTap: () async {
            if (isEmpty) {
              final imgStr = await SelectProfilePictureDialog.showLogoDialog(
                  context,
                  AppStrings.gallery,
                  cropAspectRatio: CropAspectRatio(width: 3, height: 4)
              );
              if (imgStr != null) {
                await controller.saveGalleryImages(controller.professionData.value.sId??'', imgStr);
                controller.update(['professionPhotos']);
              }
            } else {
              // View full image
              navigatePushTo(
                context,
                ImageViewScreen(
                  subTitle: '',
                  appBarTitle: AppStrings.imageViewer,
                  imageUrls: allPhotos,
                  initialIndex: index,
                ),
              );
            }
          },
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(
                color: AppColors.greyE5,
                // color: isEmpty ? AppColors.red : AppColors.greyE5,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: isEmpty ? [] : [AppShadows.textFieldShadow],
              image: !isEmpty
                  ? DecorationImage(
                image: NetworkImage(imagePath),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: isEmpty
                ? Center(
              child: LocalAssets(
                  imagePath: AppIconAssets.chat_input_gallery,
                  imgColor: AppColors.greyAF,
                  height: SizeConfig.size20,
                  width: SizeConfig.size20
              ),
            )
                : null,
          ),
        ),
        if (!isEmpty)
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () async {
                await controller.deleteProfessionImage(controller.professionData.value.sId??'', imagePath);
                controller.professionData.value.photos?.removeAt(index);
                controller.update(['professionPhotos']);
                },
              child: CircleAvatar(
                radius: 11,
                backgroundColor: AppColors.blackMite,
                child: Icon(Icons.close, size: 12, color: AppColors.white),
              ),
            ),
          ),

      ],
    );
  }

  // --- 4. Helper Widgets ---
  Widget _buildDragHandle() => Center(
    child: Container(
      width: 50,
      height: 5,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.secondaryTextColor,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );

  Widget _buildHeader(String header) => Row(
    children: [
      Expanded(
        child: CustomText(
          header,
          fontWeight: FontWeight.w600,
          fontSize: SizeConfig.large,
          color: AppColors.mainTextColor,
        ),
      ),
      IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.close),
      ),
    ],
  );

  void _showCommonUpdateSheet({
    required BuildContext context,
    required String title,
    required Widget content,
    required VoidCallback onUpdate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: SizeConfig.size12,
            right: SizeConfig.size12,
            top: SizeConfig.size10,
            bottom: SizeConfig.size40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDragHandle(),
              _buildHeader(title),

              // Dynamic Content
              content
            ],
          ),
        ),
      ),
    );
  }

  // void updatePrice({
  //   required String minFee
  //   required String maxFee}) {
  //   final minFeeController = TextEditingController(text: minFee);
  //   final maxFeeController = TextEditingController(text: maxFee);
  //   final feeTypeController = TextEditingController(text: maxFee);
  //
  //   _showCommonUpdateSheet(
  //     context: context,
  //     title: AppStrings.price,
  //     onUpdate: () {
  //       Navigator.pop(context);
  //     },
  //     content: Column(
  //       children: [
  //         Row(
  //           children: [
  //             Expanded(
  //               child: CommonTextField(
  //                 textEditController: minFeeController,
  //                 fontSize: SizeConfig.small,
  //                 fontWeight: FontWeight.w400,
  //                 titleColor: AppColors.mainTextColor,
  //                 hintText: "Min - ₹500",
  //                 keyBoardType: TextInputType.number,
  //               ),
  //             ),
  //             SizedBox(width: SizeConfig.paddingXSL),
  //             Expanded(
  //               child: CommonTextField(
  //                 textEditController: maxFeeController,
  //                 fontSize: SizeConfig.small,
  //                 fontWeight: FontWeight.w400,
  //                 titleColor: AppColors.mainTextColor,
  //                 hintText: "Max - ₹600",
  //                 keyBoardType: TextInputType.number,
  //               ),
  //             ),
  //           ],
  //         ),
  //        SizedBox(height: SizeConfig.paddingL),
  //
  //         /// Fee Type
  //         CommonTextField(
  //           textEditController: feeTypeController,
  //           title: 'Fee Type',
  //           fontSize: SizeConfig.small,
  //           fontWeight: FontWeight.w400,
  //           titleColor: AppColors.mainTextColor,
  //           hintText: "E.g. Per Visit",
  //           keyBoardType: TextInputType.text,
  //         ),
  //
  //         SizedBox(height: SizeConfig.paddingL),
  //
  //         // Common Update Button
  //         CustomBtn(
  //           radius: SizeConfig.size10,
  //           bgColor: AppColors.primaryColor,
  //           title: AppStrings.update,
  //           onTap: (){},
  //         ),
  //
  //       ],
  //     ),
  //   );
  // }

  void updateServiceType({
    required SelfWorkServiceController controller,
    required List<String> serviceType,
    required String designation,
  }) {
    controller.fetchPredefinedCategoryServiceType(
        designation: designation,
        selectedServiceKey: SelfWorkServiceController.keyServiceTypes);

    controller.selectedServiceTypes.assignAll(serviceType);

    _showCommonUpdateSheet(
      context: context,
      title: 'Service Type',
      onUpdate: () {
        Navigator.pop(context);
      },
      content: Column(
        children: [
          Obx(() {
            if (controller.isPredefinedCategoryServiceTypeLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (controller.serviceTypes.isEmpty) {
              return Center(
                  child: CustomText("No service types available",
                      color: AppColors.secondaryTextColor));
            }

            return Container(
              padding: EdgeInsets.symmetric(
                  horizontal: SizeConfig.size4, vertical: SizeConfig.size8),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: AppColors.greyE5),
                  boxShadow: [AppShadows.textFieldShadow]),
              child: Column(
                children: controller.serviceTypes.map((item) {
                  // Check if this specific item is selected
                  final isSelected =
                  controller.selectedServiceTypes.contains(item);

                  return Theme(
                    data: ThemeData(unselectedWidgetColor: Colors.grey.shade300),
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      visualDensity:
                      const VisualDensity(horizontal: -4, vertical: -3),
                      dense: true,
                      activeColor: AppColors.primaryColor,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: CustomText(
                        item,
                        fontSize: SizeConfig.medium,
                        color: AppColors.secondaryTextColor,
                      ),
                      value: isSelected,
                      onChanged: (val) {
                        if (val == true) {
                          controller.selectedServiceTypes.add(item);
                        } else {
                          controller.selectedServiceTypes.remove(item);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          SizedBox(height: SizeConfig.paddingL),

          Obx(() => CustomBtn(
            radius: SizeConfig.size10,
            bgColor: AppColors.primaryColor,
            // Fixed logic: Title should show 'Update' unless handled internally by isLoading
            title: controller.isUpdateServiceLoading.value ? null : AppStrings.update,
            isLoading: controller.isUpdateServiceLoading.value,
            onTap: () {
              if (controller.selectedServiceTypes.isEmpty) {
                commonSnackBar(message: 'Please select a service type');
                return;
              }

              Map<String, dynamic> params = {
                ApiKeys.serviceType: controller.selectedServiceTypes,
              };

              controller.updateEarnServiceData(params: params);
            },
          )),
        ],
      ),
    );
  }

  void updateServiceDescription({
    required SelfWorkServiceController controller,
    required String desc,
    required String designation,
    String? experienceStartingDate,
  }) {

    // Initialize controllers
    controller.aboutController.text = desc;

    _showCommonUpdateSheet(
      context: context,
      title: 'Service Description',
      onUpdate: () {
        Navigator.pop(context); // Close sheet
      },
      content: Column(
        children: [
          if(experienceStartingDate!=null)
            ...[
              Obx(()=>
              Align(
                alignment: Alignment.centerRight,
                child:  !controller.isGenerateDescLoading.value
                    ? Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                      onTap: () {
                        final expData = calculateExperience(experienceStartingDate);

                        final int years = expData['years']!;
                        final int months = expData['months']!;

                        controller
                            .generateDescriptions(bodyRequest: {
                          ApiKeys.category: designation,
                          ApiKeys.expYears: years,
                          ApiKeys.expMonths: months,
                        });
                      },
                      child: LocalAssets(
                        height: 25,
                        width: 25,
                        imgColor: AppColors.primaryColor,
                        imagePath: AppIconAssets.ai_generative,
                      )),
                ) : SizedBox(
                    height: 25,
                    width: 25,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                    )
                ),
              )

             ),
              SizedBox(height: SizeConfig.size8),
            ],

          CommonTextField(
              textEditController: controller.aboutController,
              maxLine: 4,
              hintText: "Horem ipsum dolor sit amet, consectetur adipiscing...",
              maxLength: 250,
              isCounterVisible: true,
              isValidate: true,
              validator: ValidationMethod().professionDescValidation
          ),

          SizedBox(height: SizeConfig.paddingL),

          // Common Update Button
          CustomBtn(
            radius: SizeConfig.size10,
            bgColor: AppColors.primaryColor,
            title: controller.isUpdateServiceLoading.value ? AppStrings.update : null,
            isLoading: controller.isUpdateServiceLoading.value,
            onTap: (){
              Map<String, dynamic> params = {
                ApiKeys.description: controller.aboutController.text.trim()
              };

              controller.updateEarnServiceData(
                  params: params
              );
            },
          ),

        ],
      ),
    );
  }

  void updateWorkExperience({
    required SelfWorkServiceController controller,
    int? years,
    int? months,
  }) {

    controller.selectedExperienceYear.value = years.toString();
    controller.selectedExperienceMonth.value = months.toString();

    // 2. Show Sheet
    _showCommonUpdateSheet(
      context: context,
      title: 'Your Experience',
      onUpdate: () {
        // Your API Logic
        // controller.updateSchedule(...);
        Navigator.pop(context);
      },
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                        AppStrings.years,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdown<String>(
                      items: controller.experienceYears,
                      selectedValue: controller.selectedExperienceYear.value,
                      hintText: "E.g 1 Year..",
                      onChanged: (val) {

                        controller.selectedExperienceYear.value = val;
                        log('val -- $val');
                        log('experience -- ${controller.selectedExperienceYear.value}');
                      },
                      displayValue: (val) => val,
                    ),
                  ],
                ),
              ),
              SizedBox(width: SizeConfig.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                        'Months',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonDropdown<String>(
                      items: controller.experienceMonths,
                      selectedValue: controller.selectedExperienceMonth.value,
                      hintText: "E.g 3 Months..",
                      onChanged: (val)=> controller.selectedExperienceMonth.value = val,
                      displayValue: (val) => val,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.paddingL),

          // Common Update Button
          CustomBtn(
            radius: SizeConfig.size10,
            bgColor: AppColors.primaryColor,
            title: controller.isUpdateServiceLoading.value ? AppStrings.update : null,
            isLoading: controller.isUpdateServiceLoading.value,
            onTap: (){

              if (controller.selectedExperienceYear.value == null) {
                commonSnackBar(message: 'Please select experience (Years)');
                return;
              }

              if (controller.selectedExperienceMonth.value == null) {
                commonSnackBar(message: 'Please select experience (Months)');
                return;
              }

              Map<String, dynamic> params = {
                ApiKeys.experience: {
                  ApiKeys.years: controller.selectedExperienceYear.value,
                  ApiKeys.months: controller.selectedExperienceMonth.value,
                },
              };

              controller.updateEarnServiceData(
                  params: params
              );

            },
          ),

        ],
      ),
    );
  }

  void updateBookingPrice({
    required BookingController controller,
    required String minFee,
    required String maxFee,
    required String feeType
  }){
    // 2. Show Sheet
    _showCommonUpdateSheet(
      context: context,
      title: 'Your Fee',
      onUpdate: () {
        Navigator.pop(context);
      },
      content: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                        AppStrings.min,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonTextField(
                      textEditController: controller.minFeeController,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      titleColor: AppColors.mainTextColor,
                      hintText: "Min - ₹500",
                      keyBoardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              SizedBox(width: SizeConfig.paddingXSL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                        AppStrings.max,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w400,
                        color: AppColors.mainTextColor
                    ),
                    SizedBox(height: SizeConfig.size8),
                    CommonTextField(
                      textEditController: controller.maxFeeController,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      titleColor: AppColors.mainTextColor,
                      hintText: "Max - ₹600",
                      keyBoardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: SizeConfig.paddingM),

          /// Fee Type
          CommonTextField(
            textEditController: controller.feeTypeController,
            title: 'Fee Type',
            fontSize: SizeConfig.small,
            fontWeight: FontWeight.w400,
            titleColor: AppColors.mainTextColor,
            hintText: "E.g. Per Visit",
            keyBoardType: TextInputType.text,
          ),
          SizedBox(height: SizeConfig.paddingL),

          // Common Update Button
          CustomBtn(
            title: controller.addUpdateAvailabilityResponse.value.status == Status.INITIAL
                  ? null
                  : AppStrings.update,
            isLoading: controller.addUpdateAvailabilityResponse.value.status == Status.INITIAL,
            radius: SizeConfig.size10,
            bgColor: AppColors.primaryColor,
            onTap: (){
              Map<String, dynamic> params = {
                ApiKeys.minFee: controller.minFeeController.text.trim(),
                ApiKeys.maxFee: controller.maxFeeController.text.trim(),
                ApiKeys.feeType: controller.feeTypeController.text.trim(),
              };
              controller.updateBookingAvailability(
                id: userId,
                params: params
              );
            },
          ),

        ],
      ),
    );
  }

  void updateVisitingHours({
        required BookingController controller,
         AvailabilityData? availabilityData}) {

      // 1. Sync Data Logic
      controller.syncScheduleToController(availabilityData?.schedule);

      // 2. Show Sheet
      _showCommonUpdateSheet(
        context: context,
        title: 'Visiting Hours',
        onUpdate: () {
          Navigator.pop(context);
        },
        content: Column(
          children: [
            VisitingHoursSelector(),
            SizedBox(height: SizeConfig.paddingL),

            // Common Update Button
            CustomBtn(
              radius: SizeConfig.size10,
              bgColor: AppColors.primaryColor,
              title: controller.addUpdateAvailabilityResponse.value.status == Status.INITIAL
                  ? null
                  : AppStrings.update,
              isLoading: controller.addUpdateAvailabilityResponse.value.status == Status.INITIAL,
              onTap: (){

                List<Map<String, dynamic>> visitingHoursData = bookingController.payloadForVisitingHours();
                logs("Visiting Hours: $visitingHoursData");

                Map<String, dynamic> params = {
                  ApiKeys.schedule: visitingHoursData,
                };
                controller.updateBookingAvailability(
                    id: userId,
                    params: params
                );

              },
            ),

          ],
        ),
      );
    }

  void updateServiceSelectionData(
      {
        required SelfWorkServiceController controller,
        required String key,
        required List<String> preSelectedOptions,
        String? designation,
      }
      ){

    final _displayTitle = controller.categoryTitleMap[key] ?? key;

    _showCommonUpdateSheet(
      context: context,
      title: _displayTitle,
      onUpdate: () {
        Navigator.pop(context); // Close sheet
      },
      content: ServiceSelectionScreen(
          controller: controller,
          designation: designation ?? ELECTRICIAN,
          selectedCategoryKey: key,
          pageTitle: _displayTitle,
          preSelectedOptions: preSelectedOptions,
          isDataUpdate: true
      ),
    );

  }



}
