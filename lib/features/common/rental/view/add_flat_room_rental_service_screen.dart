import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/business/visiting_card/view/widget/contact_number_widget.dart';
import 'package:BlueEra/features/common/rental/controller/rental_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/widget/add_more_details_dialog.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_drop_down.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddFlatRoomRentalServiceScreen extends StatefulWidget {
  const AddFlatRoomRentalServiceScreen({Key? key}) : super(key: key);

  @override
  State<AddFlatRoomRentalServiceScreen> createState() => _AddFlatRoomRentalServiceScreenState();
}

class _AddFlatRoomRentalServiceScreenState extends State<AddFlatRoomRentalServiceScreen> {
  final controller = Get.put(RentalServiceController());

  @override
  void initState() {
    super.initState();
    ever(controller.predictions, (_) => _updateOverlay());
    ever(controller.isSearchPlaceLoading, (_) => _updateOverlay());
    ever(controller.errorMessage, (_) => _updateOverlay());
  }

  @override
  void dispose() {
    controller.debounce?.cancel();
    controller.scrollController.dispose();
    _removeOverlay();
    Get.delete<RentalServiceController>();
    super.dispose();
  }


  void _updateOverlay() {
    if (controller.location.text.isNotEmpty ||
        controller.isSearchPlaceLoading.value ||
        controller.predictions.isNotEmpty ||
        controller.errorMessage.isNotEmpty) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _showOverlay() {
    final renderBox = controller.textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    if (controller.overlayEntry == null) {
      controller.overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: offset.dx,
          top: offset.dy + size.height + 10,
          width: size.width,
          child: CompositedTransformFollower(
            link: controller.layerLink,
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
                      controller.location.text.isNotEmpty) {
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
                      controller: controller.scrollController,
                      thumbVisibility: true,
                      trackVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(4),
                      child: SizedBox(
                        height: 300,
                        child: ListView.builder(
                          controller: controller.scrollController,
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
                                controller.location.text = prediction.description ?? '';
                                controller.currentAddress.value = controller.location.text;
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
      Overlay.of(context).insert(controller.overlayEntry!);
    } else {
      controller.overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    controller.overlayEntry?.remove();
    controller.overlayEntry = null;
  }

  Future<void> showAddMoreDetailsDialog(BuildContext context) async {
    if(controller.arrMoreDetails.length==5){
      commonSnackBar(message: 'You can\'t add more than five detail');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AddMoreDetailsDialog(
          fromScreen: RouteConstant.addFlatRoomRentalServiceScreen
      ),
    );

  }

  void onBackPressed(){
    log('current step-- ${controller.currentStep.value}');
    if(controller.currentStep.value > 0){
      controller.previousStep();
    }else{
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result){
        if(didPop){
          return;
        }

        onBackPressed();
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: "Flat/Room",
          onBackTap: onBackPressed,
          buildCustomWidget: ()=>
            Obx(() => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  "Step-${controller.currentStep.value + 1}/2",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            )),
        ),
        body: Obx(() {
          return controller.currentStep.value == 0
              ? _buildStepOne()
              : _buildStepTwo();
        }),
      ),
    );
  }

  // ---------------- STEP 1 ----------------
  Widget _buildStepOne() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
          left: SizeConfig.size15,
          right: SizeConfig.size15,
          top: SizeConfig.size15,
          bottom: SizeConfig.size40,
      ),
      child: Form(
        key: controller.formKeyStep1,
        child: Column(
          children: [
            CustomFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonTextField(
                    readOnly: true,
                    maxLine: 3,
                    textEditController: controller.propertyName,
                    inputLength: AppConstants.inputCharterLimit50,
                    keyBoardType: TextInputType.text,
                    title: "Property Name With House No.",
                    regularExpression: RegularExpressionUtils.alphabetSpacePattern,
                    hintText: "E.g. Taj Hotel...",
                    isValidate: true,
                  ),
                  SizedBox(height: SizeConfig.size15),
                  CommonTextField(
                    textEditController: controller.landmark,
                    title: 'Land Mark',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    titleColor: AppColors.mainTextColor,
                    hintText: "E.g: Gomti Nagar, Durgabari...",
                    keyBoardType: TextInputType.text,
                    isValidate: true,
                  ),
                  SizedBox(height: SizeConfig.size15),
                  CompositedTransformTarget(
                      link: controller.layerLink,
                      child: CommonTextField(
                          key: controller.textFieldKey,
                          autoFocus: false,
                          pIcon: Icon(Icons.search, color: AppColors.primaryColor),
                          title: 'Property Location',
                          hintText: "E.g. Lucknow, Gomti Nagar...",
                          textEditController: controller.location,
                          onChange: controller.onSearchChanged,
                          sIcon: controller.currentAddress.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.location.clear();
                              controller.currentAddress.value = '';
                              controller.predictions.clear();
                              _removeOverlay();
                            },
                          ) : null,
                        isValidate: true,
                      )
                  ),
                  SizedBox(height: SizeConfig.size15),
                  CommonTextField(
                    textEditController: controller.description,
                    title: 'Property Description',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    titleColor: AppColors.mainTextColor,
                    maxLine: 4,
                    maxLength: 300,
                    hintText: "E.g. 2BHK with swimming pool...",
                    keyBoardType: TextInputType.text,
                    isValidate: true,
                  ),
                  SizedBox(height: SizeConfig.size15),
                  ContactInputField1(
                    mobileController: controller.mobile,
                    landlineCodeController: controller.landlineCode,
                    landlineNumberController: controller.landlineNumber,
                    selectedType: controller.selectedType ?? ContactType.Mobile,
                    onTypeChanged: (type) {
                      controller.mobile.clear();
                      controller.landlineCode.clear();
                      controller.landlineNumber.clear();
                      setState(() {
                        controller.selectedType = type;
                      });

                      // _validateForm();
                    },
                    prefixOnChange: (v) => true,
                    mobileNumberOnChange: (v) {},
                  ),
                  SizedBox(height: SizeConfig.size15),

                  CustomText(
                    'Charges Type',
                    fontSize: SizeConfig.medium,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                  SizedBox(height: SizeConfig.size8),
                  CommonDropdown<ChargesTypes>(
                    items: ChargesTypes.values.toList(),
                    selectedValue: controller.selectedChargesTypes.value,
                    hintText: "E.g. Hourly..",
                    displayValue: (item) => item.label,
                    onChanged: (val) {
                      if (val != null) {
                        controller.selectedChargesTypes.value = val;
                      }
                    },
                  ),
                  SizedBox(height: SizeConfig.size15),
                  CommonTextField(
                    textEditController: controller.charge,
                    title: 'Charge',
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.w400,
                    titleColor: AppColors.mainTextColor,
                    hintText: "E.g. ₹2000",
                    keyBoardType: TextInputType.number,
                    isValidate: true,
                  ),
                  SizedBox(height: SizeConfig.size15),
                  _buildHighlightsSection(),
                ],
              ),
            ),
            SizedBox(height: SizeConfig.size15),
            CustomFormCard(
                child: Column(
                  children: [
                    _buildAddMoreDetails(),
                    SizedBox(height: SizeConfig.size30),
                    CustomBtn(
                      title: 'Next',
                      onTap: controller.nextStep,
                      radius: 10.0,
                      bgColor: AppColors.primaryColor,
                    ),
                  ],
                )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          'Property Highlights',
          fontSize: SizeConfig.medium,
          color: AppColors.mainTextColor,
          fontWeight: FontWeight.w400,
        ),
        SizedBox(height: SizeConfig.size8),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: SizeConfig.size16,
            vertical: SizeConfig.size10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.greyE5, width: 1),
          ),
          child: Row(
            children: [
              LocalAssets(imagePath: AppIconAssets.tagIcon),
              SizedBox(width: SizeConfig.size12),
              Expanded(
                child: TextField(
                  controller: controller.highlights,
                  onChanged: (_) => controller.update(["addHighlight"]),
                  decoration: const InputDecoration(
                    hintText: 'Add Highlights',
                    hintStyle: TextStyle(
                      color: AppColors.grey9B,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,

                  ),
                ),
              ),
              GetBuilder<RentalServiceController>(
                id: "addHighlight",
                builder: (_) {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: controller.highlights.text.isNotEmpty
                        ? InkWell(
                      key: const ValueKey("add"),
                      onTap: () {
                        controller.addHighlights();
                        controller.update(["addHighlight"]);
                        unFocus();
                      },
                      child: LocalAssets(
                        imagePath: AppIconAssets.addBlueIcon,
                        // imgColor: AppColors.grey9A
                      ),
                    )
                        : const SizedBox.shrink(key: ValueKey("empty")),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Obx(()=> Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.arrHighlights.map((h) {
            return Chip(
              label: Text(h),
              backgroundColor: AppColors.lightBlue,
              labelStyle: TextStyle(
                  fontSize: SizeConfig.size14,
                  color: Colors.black87
              ),
              deleteIcon: const Icon(Icons.close,
                  size: 20, color: AppColors.mainTextColor),
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(8.0)),
              onDeleted: () => controller.removeHighlights(h),
              labelPadding: const EdgeInsets.only(left: 12),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ))
      ],
    );
  }

  Widget _buildAddMoreDetails(){
    return Column(
      children: [
        Obx(()=> controller.arrMoreDetails.isNotEmpty ? Column(
          children: List.generate(
            controller.arrMoreDetails.length,
                (index) {
              final item = controller.arrMoreDetails[index];
              return Padding(
                padding: EdgeInsets.only(bottom: SizeConfig.size15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    if(index==0)...[
                      CustomText(
                        'Details',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mainTextColor,
                      ),

                      SizedBox(height: SizeConfig.size12),
                    ],

                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.white,
                                boxShadow: [AppShadows.textFieldShadow],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.greyE5,
                                )),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title + Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CustomText(
                                        item.title,
                                        fontSize: SizeConfig.large,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.mainTextColor,
                                      ),
                                      const SizedBox(height: 4),
                                      CustomText(
                                        item.details,
                                        fontSize: SizeConfig.medium,
                                        fontWeight: FontWeight.w400,
                                        color: AppColors.secondaryTextColor,
                                      ),
                                    ],
                                  ),
                                ),

                              ],
                            ),
                          ),
                        ),
                        Positioned(
                            right: 6,
                            top: -15,
                            child: InkWell(
                              onTap: () => controller.removeDetail(index),
                              child: Container(
                                padding: EdgeInsets.all(6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: AppColors.white,
                                    boxShadow: [AppShadows.textFieldShadow],
                                    border: Border.all(
                                      color: AppColors.greyE5,
                                    ),
                                    shape: BoxShape.circle
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                ),
                              ),
                            )
                        )
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ) : SizedBox.shrink()),

        InkWell(
          onTap: ()=> showAddMoreDetailsDialog(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'Add More Details',
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.bold,
                color: AppColors.mainTextColor,
              ),
              Container(
                width: 32,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- STEP 2 ----------------
  Widget _buildStepTwo() {
    return ListView(
      padding: EdgeInsets.only(
        left: SizeConfig.size15,
        right: SizeConfig.size15,
        top: SizeConfig.size15,
        bottom: SizeConfig.size40,
      ),
      children: [
        // Road Side Images
        GetBuilder<RentalServiceController>(
          id: RentalServiceController.roadSideId,
          builder: (ctrl) => _imageUploadSection(
            "Upload Road Side Images",
            minImages: 2,
            images: ctrl.roadSideImage,
            addNewImage: () async {
              ctrl.addImages(
                label: 'Road Side Images',
                imageList: ctrl.roadSideImage,
                updateId: RentalServiceController.roadSideId,
              );
            },
            removeSelectedImage: (index) {
              ctrl.removeImageAt(
                imageList: ctrl.roadSideImage,
                index: index,
                updateId: RentalServiceController.roadSideId,
              );
            },
          ),
        ),
        SizedBox(height: SizeConfig.size15),

        // Rooms
        GetBuilder<RentalServiceController>(
          id: RentalServiceController.roomId,
          builder: (ctrl) => _imageUploadSection(
            "Upload Rooms Images",
            minImages: 4,
            images: ctrl.roomImages,
            addNewImage: () async {
              ctrl.addImages(
                label: 'Rooms Images',
                imageList: ctrl.roomImages,
                updateId: RentalServiceController.roomId,
              );
            },
            removeSelectedImage: (index) {
              ctrl.removeImageAt(
                imageList: ctrl.roomImages,
                index: index,
                updateId: RentalServiceController.roomId,
              );
            },
          ),
        ),
        SizedBox(height: SizeConfig.size15),

        // Kitchen
        GetBuilder<RentalServiceController>(
          id: RentalServiceController.kitchenId,
          builder: (ctrl) => _imageUploadSection(
            "Upload Kitchen Images",
            minImages: 2,
            images: ctrl.kitchenImage,
            addNewImage: () async {
              ctrl.addImages(
                label: 'Kitchen Images',
                imageList: ctrl.kitchenImage,
                updateId: RentalServiceController.kitchenId,
              );
            },
            removeSelectedImage: (index) {
              ctrl.removeImageAt(
                imageList: ctrl.kitchenImage,
                index: index,
                updateId: RentalServiceController.kitchenId,
              );
            },
          ),
        ),
        SizedBox(height: SizeConfig.size15),

        // Bathroom
        GetBuilder<RentalServiceController>(
          id: RentalServiceController.bathroomId,
          builder: (ctrl) => _imageUploadSection(
            "Upload Bathroom Images",
            minImages: 2,
            images: ctrl.bathroomImage,
            addNewImage: () async {
              ctrl.addImages(
                label: 'Bathroom Images',
                imageList: ctrl.bathroomImage,
                updateId: RentalServiceController.bathroomId,
              );
            },
            removeSelectedImage: (index) {
              ctrl.removeImageAt(
                imageList: ctrl.bathroomImage,
                index: index,
                updateId: RentalServiceController.bathroomId,
              );
            },
          ),
        ),
        SizedBox(height: SizeConfig.size15),

        // Other
        GetBuilder<RentalServiceController>(
          id: RentalServiceController.otherId,
          builder: (ctrl) => _imageUploadSection(
            "Upload Other Images",
            minImages: 4,
            images: ctrl.otherImage,
            isOptional: true,
            addNewImage: () async {
              ctrl.addImages(
                label: 'Other Images(Optional)',
                imageList: ctrl.otherImage,
                updateId: RentalServiceController.otherId,
              );
            },
            removeSelectedImage: (index) {
              ctrl.removeImageAt(
                imageList: ctrl.otherImage,
                index: index,
                updateId: RentalServiceController.otherId,
              );
            },
          ),
        ),
        SizedBox(height: SizeConfig.size20),

        CustomBtn(
          title: 'Post Now',
          onTap: controller.submitForm,
          radius: 10.0,
          bgColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _imageUploadSection(
      String title,
      {
        List<File>? images,
        required int minImages,
        required VoidCallback addNewImage,
        required Function(int) removeSelectedImage,
        bool isOptional = false
      }) {
    return CustomFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomText(
                    title,
                    fontSize: SizeConfig.small,
                    color: AppColors.mainTextColor,
                    fontWeight: FontWeight.w400,
                ),
              ),
              if(!isOptional)
              Padding(
                padding: EdgeInsets.only(left: SizeConfig.size8),
                child: CustomText("Min-$minImages Images/Max-${controller.maxUploadImages}Images",
                  fontSize: SizeConfig.medium,
                  color: AppColors.mainTextColor,
                  fontWeight: FontWeight.w400
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final spacing = SizeConfig.size6;
              final itemCount = controller.maxUploadImages;
              final imageList = images ?? [];
              log('imageList length --> ${imageList.length}');

              // 4 items with equal width and 3 gaps between them
              final itemWidth = (availableWidth - (spacing * 5)) / 4;

              return SizedBox(
                height: itemWidth, // square shape
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(), // prevent scroll
                  padding: EdgeInsets.zero,
                  itemCount: itemCount,
                  separatorBuilder: (_, __) => SizedBox(width: spacing),
                  itemBuilder: (context, index) {
                    final hasImage = index < imageList.length;

                    return GestureDetector(
                      onTap: () {
                        if (!hasImage) addNewImage();
                      },
                      child: Container(
                        width: itemWidth,
                        height: itemWidth,
                        decoration: BoxDecoration(
                          color: AppColors.whiteFE,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.greyE5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (hasImage)
                              Image.file(imageList[index], fit: BoxFit.cover)
                            else
                              const Center(
                                child: Icon(Icons.photo_outlined,
                                    color: Colors.grey, size: 28),
                              ),
                            if (hasImage)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => removeSelectedImage(index),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close,
                                        size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          )


        ],
      ),
    );
  }
}
