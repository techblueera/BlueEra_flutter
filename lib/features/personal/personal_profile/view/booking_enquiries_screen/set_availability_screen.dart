import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/widget/custom_checkbox.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_btn.dart';
import '../../../../../widgets/visiting_hour_selector.dart';
import 'controller/booking_controller.dart';


class SetAvailabilityScreen extends StatelessWidget {
  final String? id;
  SetAvailabilityScreen({super.key, required this.id});

  final controller = Get.put(BookingTabController());

  @override
  Widget build(BuildContext context) {
 controller.initAvailabilityForEdit(channelId: id ?? '');

    return Scaffold(
        appBar: CommonBackAppBar(
          title: 'Set your Availability',
        ),
        body:  SingleChildScrollView(
          child: SafeArea(
            child: Padding(
              padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size15, vertical: SizeConfig.size15),
              child:
              Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding:  EdgeInsets.symmetric(
                        horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
                      child:Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText('Booking Type',
                              fontSize: SizeConfig.small,
                              fontWeight: FontWeight.w400,
                              color: AppColors.mainTextColor
                          ),

                          SizedBox(height: SizeConfig.size12),
                          Row(
                            children: [
                              buildBookingOption(BookingType.online.title, BookingType.online),
                              SizedBox(width: SizeConfig.size16),
                              buildBookingOption(BookingType.offline.title, BookingType.offline),
                              SizedBox(width: SizeConfig.size16),
                              buildBookingOption(BookingType.both.title, BookingType.both),
                            ],
                          ),

                          SizedBox(height: SizeConfig.size20),

                          Obx(() => controller.selectedType.value != BookingType.online
                              ? Column(
                                  children: [
                                    CommonTextField(
                                        textEditController: controller.locationController,
                                        title: 'Add Location',
                                        hintText: "Enter booking location here..."
                                    ),
                                    SizedBox(height: SizeConfig.size20),
                                  ],
                                )
                              : SizedBox.shrink()),
                          CommonTextField(
                              textEditController: controller.feeController,
                              title: 'Duration & Fee per Appointment (₹)',
                              hintText: "E.g: 500 INR Per hour or 500 Fee",
                              keyBoardType: TextInputType.number,
                          ),

                          SizedBox(height: SizeConfig.size20),

                          buildSlotDurationSection(),
                        ],
                      ),),

                    SizedBox(height: SizeConfig.size10),

                    VisitingHoursSelector(),

                    SizedBox(height: SizeConfig.size24),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12, vertical: SizeConfig.size12),
                        child:
                        Row(
                          children: [
                            Expanded(
                              child: CustomBtn(
                                height: SizeConfig.size45,
                                radius: SizeConfig.size6,
                                bgColor: AppColors.white,
                                borderColor: AppColors.skyBlueDF,
                                onTap: () {
                                  controller.clearValues();
                                },
                                title: "Clear",
                                textColor: AppColors.skyBlueDF,
                              ),
                            ),
                            SizedBox(width: SizeConfig.size12),
                            Expanded(
                              child: CustomBtn(
                                height: SizeConfig.size45,
                                radius: SizeConfig.size10,
                                bgColor: Colors.blue,
                                onTap: () {
                                 print("channelIdto:$id");
                                  controller.addVideoBookingAvailability(id: id??'');
                                },
                                title: "Save",
                                textColor: AppColors.white,
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  Widget buildBookingOption(String label, BookingType type) {
    return Obx(()=> Row(
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
            color: AppColors.mainTextColor
        ),

      ],
    ));
  }


  Widget buildSlotDurationSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left Texts
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:  [
            CustomText(
                'Set your Availability',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor
            ),

            SizedBox(height: SizeConfig.size8),

            CustomText(
                'Choose your slot duration',
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w400,
                color: AppColors.mainTextColor
            ),

          ],
        ),

        // Right Dropdown
       Container(
          padding:  EdgeInsets.symmetric(horizontal: SizeConfig.size12, vertical: SizeConfig.size3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Obx(()=> DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: controller.selectedTimeSlot.value,
              items: ['15 Min', '30 Min', '60 Min']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                controller.selectedTimeSlot.value = val!;
              },
              isDense: true,
              style: TextStyle(fontSize: SizeConfig.size16, fontWeight: FontWeight.w400, color: AppColors.secondaryTextColor),
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.secondaryTextColor),
            ),
          )),
        ),
      ],
    );
  }



}