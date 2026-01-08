import 'package:BlueEra/core/api/model/hotel_service_categories_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_category_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoomAmenitiesScreen extends StatefulWidget {
  final HotelServiceCategoriesData hotelCategoryData;

  const RoomAmenitiesScreen({super.key, required this.hotelCategoryData});

  @override
  State<RoomAmenitiesScreen> createState() => _RoomAmenitiesScreenState();
}

class _RoomAmenitiesScreenState extends State<RoomAmenitiesScreen> {
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
        title:"${widget.hotelCategoryData.name}",
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount:
                      hotelDetailController.hotelServiceSubCategoryList.length,
                  separatorBuilder: (context, index) => SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final room = hotelDetailController
                        .hotelServiceSubCategoryList[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.bed_outlined, color: Colors.grey),
                        title: Text(
                          room.name ?? "",
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        trailing: Switch(
                          value: room.isEnabled ?? false,
                          activeColor: Colors.blue,
                          onChanged: (val) =>
                              hotelDetailController.toggleRoom(index, val),
                        ),
                      ),
                    );
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
