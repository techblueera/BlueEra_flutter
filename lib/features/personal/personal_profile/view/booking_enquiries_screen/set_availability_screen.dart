import 'dart:async';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/widget/custom_checkbox.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/visiting_hour_selector.dart';
import 'controller/booking_controller.dart';

class SetAvailabilityScreen extends StatefulWidget {
  final String id;

  SetAvailabilityScreen({super.key, required this.id});

  @override
  State<SetAvailabilityScreen> createState() => _SetAvailabilityScreenState();
}

class _SetAvailabilityScreenState extends State<SetAvailabilityScreen> {
  final controller = getOrPut(() => BookingTabController());
  final locationController = getOrPut(() => LocationController());
  final ScrollController _scrollController = ScrollController();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _textFieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;


  @override
  void initState() {
    super.initState();
    ever(controller.predictions, (_) => _updateOverlay());
    ever(controller.isSearchPlaceLoading, (_) => _updateOverlay());
    ever(controller.errorMessage, (_) => _updateOverlay());
    controller.checkAndGetAvailabilityBookingData(widget.id);
  }

  void _updateOverlay() {
    if (controller.locationController.text.isNotEmpty ||
        controller.isSearchPlaceLoading.value ||
        controller.predictions.isNotEmpty ||
        controller.errorMessage.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    final renderBox = _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 10,
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 10),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.white,
                ),
                child: Obx(() {
                  if (controller.isSearchPlaceLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (controller.errorMessage.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child:
                      CustomText(
                        controller.errorMessage.value,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: Colors.red,
                      ),
                    );
                  } else if (controller.predictions.isEmpty &&
                      controller.locationController.text.isNotEmpty) {
                    return Padding(
                      padding: EdgeInsets.all(16),
                      child: CustomText(
                        "No results found",
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor,
                      ),
                    );
                  } else if (controller.predictions.isNotEmpty) {
                    return Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(4),
                      child: SizedBox(
                        height: 300,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: controller.predictions.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final prediction = controller.predictions[index];
                            return ListTile(
                              leading: const Icon(
                                  Icons.location_on_outlined,
                                color: AppColors.mainTextColor,
                              ),
                              title: CustomText(
                                  prediction.description ?? '',
                                  fontSize: SizeConfig.medium,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mainTextColor,
                              ),
                              onTap: () {
                                controller.locationController.text = prediction.description ?? '';
                                controller.currentAddress.value = controller.locationController.text;
                                controller.latitude = prediction.lat ?? 0.0;
                                controller.longitude = prediction.lng ?? 0.0;
                                controller.predictions.clear();
                                _removeOverlay();
                              },
                            );
                          },
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onSearchChanged(String query) {
    controller.locationController.text = query;
    controller.currentAddress.value = controller.locationController.text;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      controller.fetchPredictions(query);
    });
  }

  Future<void> updateAddressFromLocation() async {
    final locationData = await locationController.checkPermissionAndSetData();
    if (locationData != null) {
      controller.currentAddress.value = locationData.fullAddress;
      controller.latitude = double.parse(locationData.lat);
      controller.longitude = double.parse(locationData.long);
    }
  }

  @override
  void dispose() {
    deleteIfRegistered<BookingTabController>();
    _debounce?.cancel();
    _scrollController.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF3,
      appBar: CommonBackAppBar(
        title: AppStrings.setYourAvailability,
      ),
      body: Obx((){
        if(controller.isGetBookingAvailabilityLoading.value){
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
              vertical:SizeConfig.size15,
              horizontal:SizeConfig.size8,
          ),
          child: CustomFormCard(
            padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size15,
              vertical: SizeConfig.size20,
            ),
            child: AbsorbPointer(
              absorbing: controller.isAddBookingAvailability.value,
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// Booking Type
                    CustomText(
                      AppStrings.bookingType,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size12),
                    Row(
                      children: [
                        buildBookingOption(AppStrings.online, BookingType.online),
                        SizedBox(width: SizeConfig.size16),
                        buildBookingOption(AppStrings.offline, BookingType.offline),
                        SizedBox(width: SizeConfig.size16),
                        buildBookingOption(AppStrings.both, BookingType.both),
                      ],
                    ),
                    SizedBox(height: SizeConfig.size20),


                    /// Location
                    Obx(() => controller.selectedType.value != BookingType.online
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CustomText(
                              AppStrings.location,
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              color: AppColors.mainTextColor,
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      controller.selectedLocationMode.value = LocationMode.current;
                                      updateAddressFromLocation();
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<LocationMode>(
                                          value: LocationMode.current,
                                          groupValue: controller.selectedLocationMode.value,
                                          onChanged: (val) {
                                            controller.currentAddress.value = '';
                                            if (val != null) {
                                              controller.selectedLocationMode.value = val;
                                            }
                                          },
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        CustomText(
                                          AppStrings.currentLocation,
                                          fontSize: SizeConfig.small,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  InkWell(
                                    onTap: () {
                                      controller.selectedLocationMode.value = LocationMode.search;
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Radio<LocationMode>(
                                          value: LocationMode.search,
                                          groupValue: controller.selectedLocationMode.value,
                                          onChanged: (val) {
                                            controller.currentAddress.value = '';
                                            if (val != null) controller.selectedLocationMode.value = val;
                                          },
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        CustomText(
                                          AppStrings.searchLocation,
                                          fontSize: SizeConfig.small,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.secondaryTextColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: SizeConfig.size8),
                        Obx(() {
                          if (controller.selectedLocationMode.value == LocationMode.current) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: SizeConfig.screenWidth,
                                  padding: EdgeInsets.all(SizeConfig.size12),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.greyE5, width: 1.2),
                                    boxShadow: [AppShadows.textFieldShadow],
                                  ),
                                  child: CustomText(
                                    controller.currentAddress.value.isNotEmpty
                                        ? controller.currentAddress.value
                                        : AppStrings.fetchCurrentLocation,
                                    fontSize: SizeConfig.large,
                                    color: controller.currentAddress.value.isNotEmpty ? AppColors.mainTextColor : AppColors.grey9A,
                                  ),
                                ),
                                SizedBox(height: SizeConfig.size8),
                                InkWell(
                                  onTap: () =>  updateAddressFromLocation(),
                                  child: CustomText(
                                    AppStrings.tapToFetchBusinessLocation,
                                    fontSize: SizeConfig.small,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.primaryColor,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return CompositedTransformTarget(
                                link: _layerLink,
                                child: CommonTextField(
                                    key: _textFieldKey,
                                    autoFocus: true,
                                    pIcon: controller.currentAddress.isNotEmpty ? null : Icon(Icons.search),
                                    hintText: AppStrings.searchLocation,
                                    textEditController: controller.locationController,
                                    onChange: _onSearchChanged,
                                    sIcon: controller.currentAddress.isNotEmpty
                                        ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        controller.locationController.clear();
                                        controller.currentAddress.value = '';
                                        controller.predictions.clear();
                                        _removeOverlay();
                                      },
                                    ) : null
                                )
                            );
                          }
                        }),

                      ],
                    )
                        : const SizedBox.shrink()),
                    SizedBox(height: SizeConfig.size20),
                    CommonTextField(
                      textEditController: controller.landmarkController,
                      title: AppStrings.landMark,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      titleColor: AppColors.mainTextColor,
                      hintText: "E.g: Gomti Nagar, Durgabari...",
                      keyBoardType: TextInputType.text,
                    ),
                    SizedBox(height: SizeConfig.size20),


                    /// Fee
                    CustomText(
                      'Your Fee',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    Row(
                      children: [
                        Expanded(
                          child: CommonTextField(
                            textEditController: controller.minFeeController,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            titleColor: AppColors.mainTextColor,
                            hintText: "Min - ₹500",
                            keyBoardType: TextInputType.number,
                          ),
                        ),
                        SizedBox(width: SizeConfig.paddingXSL),
                        Expanded(
                          child: CommonTextField(
                            textEditController: controller.maxFeeController,
                            fontSize: SizeConfig.small,
                            fontWeight: FontWeight.w400,
                            titleColor: AppColors.mainTextColor,
                            hintText: "Max - ₹600",
                            keyBoardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: SizeConfig.paddingL),

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

                    /// Instruction

                    _buildInstructionSection(),
                    SizedBox(height: SizeConfig.paddingL),

                    // buildSlotDurationSection(),
                    // SizedBox(height: SizeConfig.size15),

                    /// 'Visiting Hours'
                    CustomText(
                      'Visiting Hours',
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    VisitingHoursSelector(),
                    SizedBox(height: SizeConfig.size20),

                    /// Action Button
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: SizeConfig.size12),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomBtn(
                              height: SizeConfig.size45,
                              radius: SizeConfig.size6,
                              bgColor: AppColors.white,
                              borderColor: AppColors.skyBlueDF,
                              onTap: controller.clearValues,
                              title: AppStrings.clear,
                              textColor: AppColors.skyBlueDF,
                            ),
                          ),
                          SizedBox(width: SizeConfig.size12),
                          Expanded(
                            child: CustomBtn(
                                height: SizeConfig.size45,
                                radius: SizeConfig.size10,
                                bgColor: Colors.blue,
                                onTap: () => controller.addBookingAvailability(id: widget.id ?? ''),
                                title: controller.isAddBookingAvailability.value ? null : AppStrings.save,
                                textColor: AppColors.white,
                                isLoading: controller.isAddBookingAvailability.value
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      },
      ),
    );
  }

  Widget buildBookingOption(String label, BookingType type) {
    return Obx(() => Row(
      children: [
        CircularCheckbox(
          isChecked: controller.selectedType.value == type,
          onChanged: () => controller.setBookingType(type),
        ),
        SizedBox(width: SizeConfig.size10),
        CustomText(
          label,
          fontSize: SizeConfig.large,
          fontWeight: FontWeight.w400,
          color: AppColors.mainTextColor,
        ),
      ],
    ));
  }

  // Widget buildSlotDurationSection() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //     crossAxisAlignment: CrossAxisAlignment.end,
  //     children: [
  //       Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           CustomText(
  //             AppStrings.setYourAvailability,
  //             fontSize: SizeConfig.small,
  //             fontWeight: FontWeight.w600,
  //             color: AppColors.mainTextColor,
  //           ),
  //           SizedBox(height: SizeConfig.size8),
  //           CustomText(
  //             AppStrings.choose_your_slot_duration,
  //             fontSize: SizeConfig.small,
  //             fontWeight: FontWeight.w400,
  //             color: AppColors.mainTextColor,
  //           ),
  //         ],
  //       ),
  //       Container(
  //         padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12, vertical: SizeConfig.size3),
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(10),
  //           border: Border.all(color: Colors.grey.shade300),
  //           boxShadow: [AppShadows.textFieldShadow]
  //         ),
  //         child: Obx(() => DropdownButtonHideUnderline(
  //           child: DropdownButton<String>(
  //             value: controller.selectedTimeSlot.value,
  //             items: ['15 Min', '30 Min', '60 Min']
  //                 .map((e) => DropdownMenuItem(value: e, child: Text(e)))
  //                 .toList(),
  //             onChanged: (val) {
  //               controller.selectedTimeSlot.value = val!;
  //             },
  //             isDense: true,
  //             style: TextStyle(
  //                 fontSize: SizeConfig.size16,
  //                 fontWeight: FontWeight.w400,
  //                 color: AppColors.secondaryTextColor
  //             ),
  //             icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryTextColor),
  //           ),
  //         )),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildInstructionSection() {
    return CommonTextField(
        title: AppStrings.addInstructions,
        hintText: AppStrings.provideAvailabilityHint,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w400,
        titleColor: AppColors.mainTextColor,
        textEditController: controller.instructionController,
        maxLength: 300,
        maxLine: 4,
        isCounterVisible: true,
        validator: ValidationMethod().instructionValidation
    );
  }
}
