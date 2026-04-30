import 'dart:async';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
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

  const SetAvailabilityScreen({super.key, required this.id});

  @override
  State<SetAvailabilityScreen> createState() => _SetAvailabilityScreenState();
}

class _SetAvailabilityScreenState extends State<SetAvailabilityScreen> {
  final controller = getOrPut(() => BookingController());
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
    final renderBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
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
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              shadowColor: Colors.black12,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.white,
                  border: Border.all(color: AppColors.greyE5),
                ),
                child: Obx(() {
                  if (controller.isSearchPlaceLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else if (controller.errorMessage.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: CustomText(controller.errorMessage.value,
                                  fontSize: SizeConfig.medium,
                                  color: Colors.red)),
                        ],
                      ),
                    );
                  } else if (controller.predictions.isEmpty &&
                      controller.locationController.text.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.search_off,
                              color: AppColors.secondaryTextColor, size: 18),
                          const SizedBox(width: 8),
                          CustomText("No results found",
                              fontSize: SizeConfig.medium,
                              color: AppColors.secondaryTextColor),
                        ],
                      ),
                    );
                  } else if (controller.predictions.isNotEmpty) {
                    return Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(4),
                      child: SizedBox(
                        height: 300,
                        child: ListView.separated(
                          controller: _scrollController,
                          itemCount: controller.predictions.length,
                          padding: EdgeInsets.zero,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: AppColors.greyE5),
                          itemBuilder: (context, index) {
                            final prediction = controller.predictions[index];
                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.location_on_outlined,
                                    color: AppColors.primaryColor, size: 16),
                              ),
                              title: CustomText(prediction.description ?? '',
                                  fontSize: SizeConfig.medium,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.mainTextColor),
                              onTap: () {
                                controller.locationController.text =
                                    prediction.description ?? '';
                                controller.currentAddress.value =
                                    controller.locationController.text;
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
                  }
                  return const SizedBox.shrink();
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
    controller.currentAddress.value = query;
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
    deleteIfRegistered<BookingController>();
    _debounce?.cancel();
    _scrollController.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(title: AppStrings.setYourAvailability),
      body: Obx(() {
        if (controller.isGetBookingAvailabilityLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: controller.formKey,
          child: AbsorbPointer(
            absorbing: controller.isAddBookingAvailability.value,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: SizeConfig.size15,
                horizontal: SizeConfig.size12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── 1. Booking Type ───
                  _buildSectionCard(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Booking Type',
                    subtitle: 'How do you want to receive bookings?',
                    child: _buildBookingTypeSelector(),
                  ),

                  SizedBox(height: SizeConfig.size12),

                  // ─── 2. Location ───
                  Obx(() => controller.selectedType.value != BookingType.online
                      ? Column(
                          children: [
                            _buildSectionCard(
                              icon: Icons.location_on_outlined,
                              title: 'Your Location',
                              subtitle: 'Where will you provide services?',
                              child: _buildLocationSection(),
                            ),
                            SizedBox(height: SizeConfig.size12),
                          ],
                        )
                      : const SizedBox.shrink()),

                  // ─── 3. Landmark ───
                  _buildSectionCard(
                    icon: Icons.place_outlined,
                    title: 'Landmark',
                    subtitle: 'Help clients find you easily',
                    child: CommonTextField(
                      textEditController: controller.landmarkController,
                      hintText: "E.g: Near Gomti Nagar Metro, Durgabari...",
                      keyBoardType: TextInputType.text,
                    ),
                  ),

                  SizedBox(height: SizeConfig.size12),

                  // ─── 4. Fee ───
                  _buildSectionCard(
                    icon: Icons.currency_rupee_rounded,
                    title: 'Your Fee',
                    subtitle: 'Set your minimum and maximum charge',
                    child: _buildFeeSection(),
                  ),

                  SizedBox(height: SizeConfig.size12),

                  // ─── 5. Fee Type ───
                  _buildSectionCard(
                    icon: Icons.receipt_outlined,
                    title: 'Fee Type',
                    subtitle: 'How do you charge your clients?',
                    child: CommonTextField(
                      textEditController: controller.feeTypeController,
                      hintText: "E.g. Per Visit, Per Hour, Per Project",
                      keyBoardType: TextInputType.text,
                    ),
                  ),

                  SizedBox(height: SizeConfig.size12),

                  // ─── 6. Instructions ───
                  _buildSectionCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Instructions',
                    subtitle: 'Any special notes for clients?',
                    child: CommonTextField(
                      textEditController: controller.instructionController,
                      hintText:
                          "E.g. Please bring the required documents, call before arriving...",
                      maxLength: 300,
                      maxLine: 4,
                      isCounterVisible: true,
                      isValidate: false,
                    ),
                  ),

                  SizedBox(height: SizeConfig.size12),

                  // ─── 7. Visiting Hours ───
                  _buildSectionCard(
                    icon: Icons.access_time_rounded,
                    title: 'Visiting Hours',
                    subtitle: 'Set when you are available',
                    child: VisitingHoursSelector(),
                  ),

                  SizedBox(height: SizeConfig.size24),

                  // ─── Action Buttons ───
                  _buildActionButtons(),

                  const SizedBox(height: 40 + kBottomNavigationBarHeight),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─── Section Card Wrapper ───
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return CustomFormCard(
      padding: EdgeInsets.all(SizeConfig.size14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primaryColor, size: 20),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(title,
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mainTextColor),
                    CustomText(subtitle,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryTextColor),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: AppColors.greyE5, height: SizeConfig.size20),
          child,
        ],
      ),
    );
  }

  // ─── Booking Type Selector ───
  Widget _buildBookingTypeSelector() {
    final types = [
      (
        label: AppStrings.online,
        type: BookingType.online,
        icon: Icons.videocam_outlined
      ),
      (
        label: AppStrings.offline,
        type: BookingType.offline,
        icon: Icons.handshake_outlined
      ),
      (
        label: AppStrings.both,
        type: BookingType.both,
        icon: Icons.swap_horiz_rounded
      ),
    ];

    return Obx(() => Row(
          children: types.map((item) {
            final isSelected = controller.selectedType.value == item.type;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right:
                        item.type != BookingType.both ? SizeConfig.size8 : 0),
                child: GestureDetector(
                  onTap: () => controller.setBookingType(item.type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? AppColors.primaryColor : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.greyE5,
                      ),
                      boxShadow: isSelected ? [] : [AppShadows.textFieldShadow],
                    ),
                    child: Column(
                      children: [
                        Icon(item.icon,
                            color: isSelected
                                ? Colors.white
                                : AppColors.secondaryTextColor,
                            size: 20),
                        SizedBox(height: SizeConfig.size4),
                        CustomText(
                          item.label,
                          fontSize: SizeConfig.small,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : AppColors.secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ));
  }

  // ─── Location Section ───
  Widget _buildLocationSection() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Mode Toggle ───
            Container(
              decoration: BoxDecoration(
                color: AppColors.whiteF3,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.greyE5),
              ),
              child: Row(
                children: [
                  _buildLocationModeTab(
                    label: 'Current Location',
                    icon: Icons.my_location_rounded,
                    mode: LocationMode.current,
                  ),
                  _buildLocationModeTab(
                    label: 'Search Location',
                    icon: Icons.search_rounded,
                    mode: LocationMode.search,
                  ),
                ],
              ),
            ),

            SizedBox(height: SizeConfig.size12),

            // ─── Location Input ───
            if (controller.selectedLocationMode.value == LocationMode.current)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: updateAddressFromLocation,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(SizeConfig.size12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: controller.currentAddress.value.isNotEmpty
                              ? AppColors.primaryColor.withValues(alpha: 0.4)
                              : AppColors.greyE5,
                        ),
                        boxShadow: [AppShadows.textFieldShadow],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              controller.currentAddress.value.isNotEmpty
                                  ? Icons.location_on
                                  : Icons.my_location_rounded,
                              color: AppColors.primaryColor,
                              size: 16,
                            ),
                          ),
                          SizedBox(width: SizeConfig.size10),
                          Expanded(
                            child: CustomText(
                              controller.currentAddress.value.isNotEmpty
                                  ? controller.currentAddress.value
                                  : AppStrings.fetchCurrentLocation,
                              fontSize: SizeConfig.medium,
                              color: controller.currentAddress.value.isNotEmpty
                                  ? AppColors.mainTextColor
                                  : AppColors.secondaryTextColor,
                              fontWeight:
                                  controller.currentAddress.value.isNotEmpty
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                            ),
                          ),
                          if (controller.currentAddress.value.isEmpty)
                            Icon(Icons.refresh_rounded,
                                color: AppColors.primaryColor, size: 18),
                        ],
                      ),
                    ),
                  ),
                  if (controller.currentAddress.value.isEmpty) ...[
                    SizedBox(height: SizeConfig.size6),
                    InkWell(
                      onTap: updateAddressFromLocation,
                      child: CustomText(
                        AppStrings.tapToFetchBusinessLocation,
                        fontSize: SizeConfig.small,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryColor,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primaryColor,
                      ),
                    ),
                  ],
                ],
              )
            else
              CompositedTransformTarget(
                link: _layerLink,
                child: CommonTextField(
                  key: _textFieldKey,
                  autoFocus: true,
                  pIcon: controller.currentAddress.isNotEmpty
                      ? null
                      : const Icon(Icons.search_rounded),
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
                        )
                      : null,
                ),
              ),
          ],
        ));
  }

  // ─── Location Mode Tab ───
  Widget _buildLocationModeTab({
    required String label,
    required IconData icon,
    required LocationMode mode,
  }) {
    return Obx(() {
      final isSelected = controller.selectedLocationMode.value == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            controller.currentAddress.value = '';
            controller.selectedLocationMode.value = mode;
            if (mode == LocationMode.current) updateAddressFromLocation();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(vertical: SizeConfig.size8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : AppColors.secondaryTextColor),
                SizedBox(width: SizeConfig.size4),
                CustomText(
                  label,
                  fontSize: SizeConfig.small,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      isSelected ? Colors.white : AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  // ─── Fee Section ───
  Widget _buildFeeSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Minimum (₹)'),
                  SizedBox(height: SizeConfig.size6),
                  CommonTextField(
                    textEditController: controller.minFeeController,
                    hintText: "e.g. 500",
                    keyBoardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            // Divider with "to" in between
            Padding(
              padding: EdgeInsets.only(top: SizeConfig.size20),
              child: CustomText('to',
                  fontSize: SizeConfig.small,
                  color: AppColors.secondaryTextColor),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel('Maximum (₹)'),
                  SizedBox(height: SizeConfig.size6),
                  CommonTextField(
                    textEditController: controller.maxFeeController,
                    hintText: "e.g. 1000",
                    keyBoardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: SizeConfig.size8),
        // ─── Tip row ───
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: SizeConfig.size10, vertical: SizeConfig.size6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 14, color: Colors.amber),
              SizedBox(width: SizeConfig.size6),
              Expanded(
                child: CustomText(
                  'Competitive pricing helps you get more bookings',
                  fontSize: SizeConfig.small,
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Action Buttons ───
  Widget _buildActionButtons() {
    return Obx(() => Row(
          children: [
            Expanded(
              child: CustomBtn(
                height: SizeConfig.size45,
                radius: SizeConfig.size10,
                bgColor: AppColors.white,
                borderColor: AppColors.primaryColor,
                onTap: controller.clearValues,
                title: AppStrings.clear,
                textColor: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: CustomBtn(
                height: SizeConfig.size45,
                radius: SizeConfig.size10,
                bgColor: AppColors.primaryColor,
                onTap: () => controller.addBookingAvailability(id: widget.id),
                title: controller.isAddBookingAvailability.value
                    ? null
                    : AppStrings.save,
                textColor: AppColors.white,
                isLoading: controller.isAddBookingAvailability.value,
              ),
            ),
          ],
        ));
  }

  Widget _fieldLabel(String label) => CustomText(
        label,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w500,
        color: AppColors.mainTextColor,
      );
}
