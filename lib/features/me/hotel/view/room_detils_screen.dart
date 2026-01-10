import 'package:BlueEra/core/api/model/hotel_service_categories_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_category_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoomSelectionScreen extends StatefulWidget {
  final HotelServiceCategoriesData hotelCategoryData;

  const RoomSelectionScreen({super.key, required this.hotelCategoryData});

  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  final hotelDetailController = Get.find<HotelCategoryController>();

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      hotelDetailController.hotelServiceSubCategoryList.clear();
      hotelDetailController.hotelServiceSubCategoryList
          .addAll(widget.hotelCategoryData.children ?? []);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "${widget.hotelCategoryData.name}",
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.builder(
                  itemCount:
                      hotelDetailController.hotelServiceSubCategoryList.length,
                  itemBuilder: (context, index) {
                    final room = hotelDetailController
                        .hotelServiceSubCategoryList[index];
                    return CommonCardWidget(
                        borderColorColor: AppColors.whiteE5,
                        cardMargin: 7,
                        padding: 10,
                        child: Row(
                          children: [
                            LocalAssets(
                                imagePath:
                                "assets/category/hotel_service/${room.key}.svg"),
                            SizedBox(
                              width: SizeConfig.size10,
                            ),
                            Expanded(
                              child: CustomText(
                                room.name,
                                color: AppColors.secondaryTextColor,
                                fontSize: 18,
                              ),
                            ),
                            Switch(
                              value: room.isEnabled ?? false,
                              activeColor: AppColors.primaryColor,
                              onChanged: (val) =>
                                  hotelDetailController.toggleRoom(index, val),
                            ),
                          ],
                        ));

                  },
                )),
          ),
          // Submit Button Section
          Padding(
            padding:
                EdgeInsets.only(bottom: 20.0, right: 20, left: 20, top: 20),
            child: PositiveCustomBtn(
                padding: EdgeInsets.zero,
                onTap: () {
                  hotelDetailController.updateHotelBulkStatus();
                },
                title: AppStrings.submit),
          ),
          SizedBox(
            height: 30,
          )
        ],
      ),
    );
  }
}
