import 'dart:io';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/regular_expression.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_constant.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/controller/add_service_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/listing_form_screen/widgets/add_more_details_dialog.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:get/get.dart';
import '../../../../../../core/constants/app_icon_assets.dart';
import '../../../../../../widgets/local_assets.dart';

class AddServicesScreen extends StatefulWidget {
  const AddServicesScreen({Key? key}) : super(key: key);

  @override
  State<AddServicesScreen> createState() => _AddServicesScreenState();
}

class _AddServicesScreenState extends State<AddServicesScreen> {
  late AddServiceController addServiceController;

  @override
  void initState() {
    super.initState();
    Get.lazyPut<AddServiceController>(() => AddServiceController());
    addServiceController = Get.find<AddServiceController>();
  }

  @override
  void dispose() {
    Get.delete<AddServiceController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: 'Service',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.paddingM),
          child: Form(
            key: addServiceController.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload Images Section
                Container(
                  padding: EdgeInsets.all(SizeConfig.size16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    // boxShadow: [AppShadows.textFieldShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// Upload images
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(
                              "Upload Images",
                              fontWeight: FontWeight.w400
                          ),
                          const CustomText(
                              "Min 2 / Max 5",
                              fontWeight: FontWeight.w400),
                        ],
                      ),
                      SizedBox(height: SizeConfig.paddingS),
                      SizedBox(
                        height: SizeConfig.size80,
                        child: GridView.builder(
                          scrollDirection: Axis.horizontal,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            final imgIdx = index;
                            return GestureDetector(
                              key: ValueKey('img_$imgIdx'),
                              onTap: () {
                                if (addServiceController.imageLocalPaths.length >= 5) {
                                  commonSnackBar(
                                    message: 'Limit reached\nYou can upload up to 5 images only.',
                                  );
                                } else {
                                  addServiceController.pickImages(context);
                                }
                              },
                              onLongPress: () {
                                final hasImage = imgIdx < addServiceController.imageLocalPaths.length;
                                if (hasImage) {
                                  addServiceController.removeImageAt(imgIdx);
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.whiteFE,
                                  borderRadius: BorderRadius.circular(6.0),
                                  border: Border.all(color: AppColors.greyE5, width: 1),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Obx(() {
                                  final hasImage = imgIdx < addServiceController.imageLocalPaths.length;
                                  return Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (hasImage)
                                        Image.file(
                                          File(addServiceController.imageLocalPaths[imgIdx]),
                                          fit: BoxFit.cover,
                                        )
                                      else
                                        Center(
                                          child: Icon(
                                            Icons.photo_outlined,
                                            color:
                                            AppColors.secondaryTextColor.withValues(alpha: 0.3),
                                          ),
                                        ),
                                      if (hasImage)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => addServiceController.removeImageAt(imgIdx),
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
                                  );
                                }),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: SizeConfig.size10),

                      /// service name
                      CommonTextField(
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        title: "Service Name",
                        hintText: "E.g. Hospital OPD Consultation...",
                        textEditController: addServiceController.serviceNameCtrl,
                        validator: addServiceController.validateServiceName,
                        maxLength: 30,
                        isCounterVisible: true
                      ),
                      SizedBox(height: SizeConfig.size10),

                      /// facility
                      CustomText(
                        'Facilities',
                        fontSize: SizeConfig.medium,
                        color: AppColors.black,
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
                            Image.asset("assets/icons/tag_icon.png"),
                            SizedBox(width: SizeConfig.size12),
                            Expanded(
                              child: TextField(
                                controller: addServiceController.facilitiesCtrl,
                                onChanged: (_) => addServiceController.update(["addIcon"]),
                                decoration: const InputDecoration(
                                  hintText: 'Facility',
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
                            GetBuilder<AddServiceController>(
                              id: "addIcon",
                              builder: (_) {
                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(scale: anim, child: child),
                                  child: addServiceController.facilitiesCtrl.text.isNotEmpty
                                      ? InkWell(
                                    key: const ValueKey("add"),
                                    onTap: () {
                                      addServiceController.addFacility();
                                      addServiceController.update(["addIcon"]);
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
                        runSpacing: 2,
                        children: addServiceController.facilities.map((facility) {
                          return Chip(
                            label: Text(facility),
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
                            onDeleted: () => addServiceController.removeFacility(facility),
                            labelPadding: const EdgeInsets.only(left: 12),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      )),
                      SizedBox(height: SizeConfig.size10),

                      /// service description
                      CommonTextField(
                        title: "Service Description",
                        hintText: "Horem ipsum dolor sit amet, consectetur adipiscing...",
                        textEditController: addServiceController.descriptionCtrl,
                        maxLine: 4,
                        validator: addServiceController.validateServiceDescription,
                        maxLength: 600,
                        isCounterVisible: true
                      ),
                      SizedBox(height: SizeConfig.size10),

                      /// timing section
                      _timingSection(),

                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size10),

                Container(
                  padding: EdgeInsets.all(SizeConfig.size16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    // boxShadow: [AppShadows.textFieldShadow],
                  ),
                  child: Column(
                    children: [
                      _priceSection(),

                      SizedBox(height: SizeConfig.size10),

                      _discountSection(),
                    ],
                  ),
                ),

                SizedBox(height: SizeConfig.size10),

                // Demo Video
                // _demoVideoSection(),
                //
                // SizedBox(height: SizeConfig.size10),

                // Minimum Booking

                Container(
                  padding: EdgeInsets.all(SizeConfig.size16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    // boxShadow: [AppShadows.textFieldShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:  [
                      CommonTextField(
                        contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                        title: "Minimum booking Amount",
                        hintText: "E.g. ₹300",
                        textEditController: addServiceController.minBookingCtrl,
                        keyBoardType: TextInputType.number,
                        validator: addServiceController.validateAmount,
                      ),
                      SizedBox(height: SizeConfig.size30),

                      Obx(()=> addServiceController.detailsList.isNotEmpty ? Column(
                        children: List.generate(
                          addServiceController.detailsList.length,
                              (index) {
                            final item = addServiceController.detailsList[index];
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
                                      color: AppColors.black,
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
                                            onTap: () => addServiceController.removeDetail(index),
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomText("Add More Details",
                          fontWeight: FontWeight.w600,),
                          GestureDetector(
                            onTap: () {
                              showAddMoreDetailsDialog(context);
                            },
                            child: Container(
                              height: 28,
                                width: 28,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                color: Colors.blue
                                ),
                                child: Center(child: const Icon(CupertinoIcons.add,
                                  color: Colors.white,size: 21,))),
                          ),
                        ],
                      ),
                      SizedBox(height: SizeConfig.size30),

                      CustomBtn(
                        title: 'Post Service',
                        onTap: ()=> addServiceController.createServiceApi(),
                        bgColor: AppColors.primaryColor,
                        textColor: AppColors.white,
                        height: SizeConfig.size40,
                        radius: 10.0,
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
  }

  Widget _timingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CustomText("Timing", fontWeight: FontWeight.w500),
            Obx(()=> Row(
              children: [
                SizedBox(
                  width: 100,
                  child: RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    value: false,
                    groupValue: addServiceController.isSpecial.value,
                    onChanged: (val) => addServiceController.isSpecial.value = val ?? false,
                    title: const CustomText("Default", fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    value: true,
                    groupValue: addServiceController.isSpecial.value,
                    onChanged: (val) => addServiceController.isSpecial.value = val ?? true,
                    title: const CustomText("Special", fontSize: 12),
                  ),
                ),
              ],
            ))
          ],
        ),

        SizedBox(height: SizeConfig.size8),

        // Start and End Time Dropdowns
        Row(
          children: [
            Expanded(
              child: Obx(() => _buildDropdown(
                hint: "Start Time",
                value: addServiceController.startTime.value,
                items: addServiceController.timeSlots,
                onChanged: (val) => addServiceController.startTime.value = val!,
              )),
            ),
            SizedBox(width: SizeConfig.size10),
            Expanded(
              child: Obx(() => _buildDropdown(
                hint: "End Time",
                value: addServiceController.endTime.value,
                items: addServiceController.timeSlots,
                onChanged: (val) => addServiceController.endTime.value = val!,
              )),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16, vertical: SizeConfig.size10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.greyE5),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          value: value.isEmpty ? null : value,
          hint: Text(hint, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
          style: TextStyle(color: Colors.black87, fontSize: 14),
          items: items.map((String t) {
            return DropdownMenuItem<String>(
              value: t,
              child: Text(t),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }


  Widget _priceSection() {
    return Obx(()=> Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CustomText("Price", fontWeight: FontWeight.w500),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    value: false,
                    groupValue: addServiceController.isRange.value,
                    onChanged: (val) => addServiceController.isRange.value = val ?? false,
                    title:  CustomText("Fixed",
                      fontSize: 12,),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: RadioListTile<bool>(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    value: true,
                    groupValue: addServiceController.isRange.value,
                    onChanged: (val) => addServiceController.isRange.value = val ?? true,
                    title: CustomText("Range",
                      fontSize: 12),
                  ),
                ),
                  ],
                ),

              ],
            ),
      addServiceController.isRange.isTrue
          ? Row(
        children: [
          Expanded(
            child: CommonTextField(
              contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
              hintText: "Min - ₹300",
              textEditController: addServiceController.minPriceCtrl,
              keyBoardType: TextInputType.number,
              validator: (value) => ValidationMethod().validateMinPrice(value, addServiceController.maxPriceCtrl),
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: CommonTextField(
              contentPadding: EdgeInsets.symmetric(vertical: 14,horizontal: 12),
              hintText: "Max - ₹800",
              textEditController: addServiceController.maxPriceCtrl,
              keyBoardType: TextInputType.number,
              validator: (value) => ValidationMethod().validateMaxPrice(value, addServiceController.minPriceCtrl),
            ),
          ),
        ],
      ) : CommonTextField(
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        hintText: "E.g. ₹300",
        textEditController: addServiceController.priceCtrl,
        keyBoardType: TextInputType.number,
        validator: addServiceController.validateAmount,
      ),
      SizedBox(height: SizeConfig.size10),
        CustomText("Per (Unit)",
            fontWeight: FontWeight.w400
        ),
        SizedBox(height: SizeConfig.size10),
      CommonTextField(
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        hintText: "E.g. ₹-Per Service, Hours, Course...",
        textEditController: addServiceController.perUnitCtrl,
       ),
      ]
    ));
  }

  Widget _discountSection(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [


        SizedBox(
          height: SizeConfig.size10,
        ),

        Obx(()=> Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomText("Discount", fontWeight: FontWeight.w400),
            SizedBox(
              height: SizeConfig.size8,
            ),

            addServiceController.coupons.isEmpty
                ? Container(
              decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [AppShadows.textFieldShadow],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.greyE5,
                  )
              ),
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16,
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title:  CustomText("Discount Coupon",
                  fontFamily: "Arial",
                ),
                trailing: const Icon(CupertinoIcons.chevron_forward),
                onTap: () {
                  showDiscountCouponDialog(context);
                },
              ),
            )
                : ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: List.generate(
                addServiceController.coupons.length,
                    (index) {
                  final coupon = addServiceController.coupons[index];

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: EdgeInsets.symmetric(
                            horizontal: SizeConfig.size12,
                            vertical: SizeConfig.size15
                        ),
                        decoration: BoxDecoration(
                            color: AppColors.white,
                            boxShadow: [AppShadows.textFieldShadow],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.greyE5,
                            )
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomText(
                                    "Discount worth ₹${coupon.totalOff.toStringAsFixed(0)} T&Cs",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.mainTextColor,
                                  ),
                                  SizedBox(height: 6),
                                  CustomText(
                                      coupon.description,
                                      fontSize: SizeConfig.small,
                                      color: AppColors.secondaryTextColor,
                                      fontWeight: FontWeight.w400
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    children: [
                                      DottedBorder(
                                        borderType: BorderType.RRect,
                                        radius: Radius.circular(6),
                                        dashPattern: [6, 3], // 6px dash, 3px gap
                                        color: Colors.green,
                                        strokeWidth: 1.0,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          child: CustomText(
                                              coupon.codeName ?? "N/A",
                                              fontSize: SizeConfig.small,
                                              color: AppColors.mainTextColor,
                                              fontWeight: FontWeight.w400
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      CustomText(
                                          coupon.discountType == DiscountType.inPercentage
                                              ? "${coupon.totalOff}% Off"
                                              : "₹${coupon.totalOff} Off",
                                          fontSize: SizeConfig.small,
                                          color: AppColors.green7F,
                                          fontWeight: FontWeight.w600
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),

                            // Right side - Icon
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.white,
                                  border: Border.all(color: AppColors.primaryColor, width: 1.1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                      spreadRadius: 0,
                                    )
                                  ]
                              ),
                              child: Icon(
                                Icons.percent,
                                color: AppColors.orange27,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                          right: 6,
                          top: -6,
                          child: InkWell(
                            onTap: ()=> addServiceController.removeCoupon(index),
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
                  );
                },
              ),
            ),
            SizedBox(
              height: SizeConfig.size8,
            ),
            if(addServiceController.coupons.isNotEmpty)
              Row(mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      showDiscountCouponDialog(context);
                    },
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.add, color: Colors.blue,size: 20,),
                        SizedBox(width: 6),
                        const CustomText(
                          "Add More Coupon",
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ],
              )
          ],
        ))
      ],
    );
  }

  Widget _demoVideoSection() {
    return Container(
      padding: EdgeInsets.all(SizeConfig.size16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:  [
          CustomText("Add Demo Video", fontWeight: FontWeight.w500),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.whiteE5
              )
            ),
            child: Center(
              child: Column(
                children: [
                  LocalAssets(imagePath: AppIconAssets
                      .upload_video_service),
                  SizedBox(height: 6),
                  Center(
                    child: CustomText(
                      "Upload your Demo Video",
                      color: Colors.grey,
                    ),
                  )
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Future<void> showAddMoreDetailsDialog(BuildContext context) async {
    if(addServiceController.detailsList.length==5){
      commonSnackBar(message: 'You can\'t add more than five detail');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddMoreDetailsDialog(
          fromScreen: RouteConstant.addServicesScreen
      ),
    );

  }

}

void showAddMoreDetailsDialog(BuildContext context) {
  final titleCtrl = TextEditingController();
  final detailsCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomText(
                "Add More Details",
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              const SizedBox(height: 20),

              // Title Field
              CommonTextField(
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                title: "Title",
                hintText: "e.g. Size",
                textEditController: titleCtrl,
              ),
              const SizedBox(height: 16),

              // Details Field
              CommonTextField(
                contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                title: "Details",
                hintText: "e.g. Wireless Earbuds Box",
                textEditController: detailsCtrl,

              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: SizeConfig.paddingM,
                    ),
                  ),
                  onPressed: () {
                    // handle save
                    Navigator.pop(context);
                  },
                  child: const CustomText(
                    "Save",
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showDiscountCouponDialog(BuildContext context) {
  final _formKey = GlobalKey<FormState>();
  final couponNameCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final codeNameCtrl = TextEditingController();
  final totalOffCtrl = TextEditingController();
  String selectedType = "percentage"; // or "rupees"

  // --- VALIDATIONS ---

  String? validateCouponName(String? value) {
    if (value == null || value.isEmpty) return 'Coupon name is required';
    if (value.length < 3) return 'Coupon name must be at least 3 characters';
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.isEmpty) return 'Description is required';
    if (value.length < 10) return 'Description must be at least 10 characters';
    return null;
  }

  String? validateTotalOff(String? value, String type) {
    if (value == null || value.isEmpty) {
      return "Enter a discount value";
    }
    final num? discount = num.tryParse(value);
    if (discount == null) return "Enter a valid number";

    if (type == "rupees") {
      if (discount <= 0) return "Discount must be greater than 0 ₹";
    } else if (type == "percentage") {
      if (discount <= 0 || discount > 100) {
        return "Discount % must be between 1 and 100";
      }
    }
    return null;
  }

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(
                            "Discount Coupon",
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          IconButton(
                            onPressed: () {
                              Get.back();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.mainTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Coupon Name
                      CommonTextField(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        title: "Coupon Name",
                        hintText: "e.g. FLYDEAL",
                        textEditController: couponNameCtrl,
                        validator: validateCouponName,
                        maxLength: 30,
                        isCounterVisible: true,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      CommonTextField(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        title: "Description / Terms And Condition",
                        hintText:
                        "Horem ipsum dolor sit amet, consectetur adipiscing...",
                        textEditController: descriptionCtrl,
                        validator: validateDescription,
                        maxLength: 200,
                        isCounterVisible: true,
                      ),
                      const SizedBox(height: 16),

                      // Code Name
                      CommonTextField(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        title: "Code Name (Optional)",
                        hintText: "e.g. FLYDEAL",
                        textEditController: codeNameCtrl,
                        isValidate: false,
                      ),
                      const SizedBox(height: 16),

                      // Total Off with radio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CustomText(
                            "Total Off",
                            fontWeight: FontWeight.w500,
                          ),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Radio<String>(
                                    value: "rupees",
                                    groupValue: selectedType,
                                    onChanged: (val) {
                                      setState(() {
                                        selectedType = val!;
                                      });
                                    },
                                    visualDensity: const VisualDensity(
                                        horizontal: -4, vertical: -4),
                                  ),
                                  const CustomText(
                                    "In Rupees",
                                    fontSize: 12,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Radio<String>(
                                    value: "percentage",
                                    groupValue: selectedType,
                                    onChanged: (val) {
                                      setState(() {
                                        selectedType = val!;
                                      });
                                    },
                                    visualDensity: const VisualDensity(
                                        horizontal: -4, vertical: -4),
                                  ),
                                  const CustomText(
                                    "In Percentage",
                                    fontSize: 12,
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Total Off input
                      CommonTextField(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        hintText: selectedType == "rupees"
                            ? "e.g. 300"
                            : "e.g. 10%",
                        textEditController: totalOffCtrl,
                        validator: (value) =>
                            validateTotalOff(value, selectedType),
                        keyBoardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: SizeConfig.paddingM,
                            ),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final coupon = DiscountCoupon(
                                couponName: couponNameCtrl.text,
                                description: descriptionCtrl.text,
                                codeName: codeNameCtrl.text.isEmpty
                                    ? null
                                    : codeNameCtrl.text,
                                totalOff:
                                double.tryParse(totalOffCtrl.text) ?? 0,
                                discountType: selectedType == 'rupees'
                                    ? DiscountType.inRupees
                                    : DiscountType.inPercentage,
                              );

                              Get.find<AddServiceController>().addCoupon(coupon);

                              Get.back();
                              Get.snackbar("Success", "Coupon saved!");
                            }
                          },
                          child: const CustomText(
                            "Save",
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

}

enum DiscountType { inRupees, inPercentage }

class DiscountCoupon {
  final String couponName;
  final String description;
  final String? codeName; // optional
  final double totalOff;
  final DiscountType discountType;

  DiscountCoupon({
    required this.couponName,
    required this.description,
    this.codeName,
    required this.totalOff,
    required this.discountType,
  });

  // CopyWith method
  DiscountCoupon copyWith({
    String? couponName,
    String? description,
    String? codeName,
    double? totalOff,
    DiscountType? discountType,
  }) {
    return DiscountCoupon(
      couponName: couponName ?? this.couponName,
      description: description ?? this.description,
      codeName: codeName ?? this.codeName,
      totalOff: totalOff ?? this.totalOff,
      discountType: discountType ?? this.discountType,
    );
  }

  // From JSON
  factory DiscountCoupon.fromJson(Map<String, dynamic> json) {
    return DiscountCoupon(
      couponName: json['name'] ?? '',
      description: json['description'] ?? '',
      codeName: json['codeName'],
      totalOff: (json['totalOff'] ?? 0).toDouble(),
      discountType: json['type'] == 'flat'
          ? DiscountType.inRupees
          : DiscountType.inPercentage,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'name': couponName,
      'description': description,
      'codeName': codeName,
      'totalOff': totalOff,
      'type': discountType == DiscountType.inRupees ? 'flat' : 'percentage',
    };
  }
}

