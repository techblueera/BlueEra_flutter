import 'package:BlueEra/core/api/model/hotel_service_categories_res_model.dart';
import 'package:BlueEra/features/me/hotel/controller/hotel_category_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
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
          .addAll(widget.hotelCategoryData.children ?? []);    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Room Details",
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() => ListView.separated(
                  padding: EdgeInsets.all(16),
                  itemCount:  hotelDetailController.hotelServiceSubCategoryList.length ,
                  separatorBuilder: (context, index) => SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final room =  hotelDetailController.hotelServiceSubCategoryList[index];
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
                          value: room.isActive ?? false,
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
          Container(
            padding: EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: ElevatedButton(
              onPressed: () => hotelDetailController.submitData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                "Submit Selection",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
