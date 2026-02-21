import 'dart:io';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/delivery_partner/widget/common_image_upload_section.dart';
import 'package:BlueEra/features/me/hotel/controller/room_detail_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/progrss_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class HotelImageUploadScreen extends StatelessWidget {
  final controller = Get.find<RoomDetailController>();
  final String roomType;
  final String roomName;

  HotelImageUploadScreen(
      {super.key, required this.roomType, required this.roomName});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return WillPopScope(
        onWillPop: () async => !controller.isLoading.value,
        child: Scaffold(
          appBar: CommonBackAppBar(
            title: "Hotel Images",
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSection(
                        "Upload Exterior Images", controller.exteriorImages,context),
                    _buildSection(
                        "Upload Washrooms Images", controller.washroomImages,context),
                    _buildSection("Upload Amenities Images (Optional)",
                        controller.amenityImages,context),
                    SizedBox(height: 30),
                    Obx(() {
                      return CustomBtn(
                        onTap: controller.isCreateHotel
                            ? () {
                          if (controller.validate()) {
                            // Proceed with submission logic
                            print("Form Submitted Successfully");
                            controller.submitHotelRoom(
                                name: roomName, type: roomType);
                          }
                        }
                            : null,
                        title: AppStrings.submit,
                        isValidate: controller.isCreateHotel,
                      );
                    }),
                  ],
                ),
              ),
              if (controller.isLoading.value) ShimmerListView()
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSection(String title, RxList<XFile> imageList, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(title, fontWeight: FontWeight.w500),
              CustomText("Min-2 Images",
               color: AppColors.secondaryTextColor, fontSize: SizeConfig.size12),
            ],
          ),
          SizedBox(height: 12),
          Obx(() =>
              Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final path = await CommonImageUploadTile.pickImage(context: context);
                        if (path != null) imageList.add(XFile(path));
                      },
                      // onTap: () => _showPickerOptions(imageList),
                      child: Container(
                        height: 80,
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: index < imageList.length
                            ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                  File(imageList[index].path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                height: 80,

                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () =>
                                    controller.removeImage(
                                        index, imageList),
                                child: CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close,
                                        size: 12, color: Colors.white)),
                              ),
                            )
                          ],
                        )
                            : Icon(Icons.image_outlined, color: Colors.grey),
                      ),
                    ),
                  );
                }),
              )),
        ],
      ),
    );
  }

}
