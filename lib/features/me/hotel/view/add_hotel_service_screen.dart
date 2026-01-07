import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/model/hotel_service_categories_res_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_category_controller.dart';
import 'package:BlueEra/features/me/hotel/view/room_detils_screen.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddHotelServiceScreen extends StatefulWidget {
  const AddHotelServiceScreen({super.key});

  @override
  State<AddHotelServiceScreen> createState() => _AddHotelServiceScreenState();
}

class _AddHotelServiceScreenState extends State<AddHotelServiceScreen> {
  final hotelController = Get.put(HotelCategoryController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: "Add Hotel Service",
        isShadowShow: false,
      ),
      body: Obx(() {
        if (hotelController.getAllHotelServiceResponse.value.status ==
            Status.ERROR) {
          return Center(child: CustomText(AppStrings.somethingWentWrong));
        }
        if (hotelController.hotelServiceCategoryList.isNotEmpty) {
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 50, left: 10, right: 10),
            itemBuilder: (context, hotelIndex) {
              HotelServiceCategoriesData data =
                  hotelController.hotelServiceCategoryList[hotelIndex];
              return InkWell(
                onTap: () {
                  if(data.key=="ROOM_DETAILS")
                    {
                  Get.to(RoomSelectionScreen(
                    hotelCategoryData: data,
                  ));}
                },
                child: CommonCardWidget(
                    borderColorColor: AppColors.whiteE5,
                    cardMargin: 7,
                    child: Row(
                      children: [
                        LocalAssets(
                            imagePath:
                                "assets/category/hotel_service/${data.key}.svg"),
                        SizedBox(
                          width: SizeConfig.size10,
                        ),
                        CustomText(
                          data.name,
                          color: AppColors.secondaryTextColor,
                          fontSize: 18,
                        )
                      ],
                    )),
              );
            },
            itemCount: hotelController.hotelServiceCategoryList.length,
          );
        }
        return Center(child: CustomText("No Hotel Service Available"));
      }),
    );
  }
}
