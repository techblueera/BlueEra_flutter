import 'dart:io';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/hotel_details_home_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hotel/repo/hotel_service_repo.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:BlueEra/features/me/school/repo/upload_file_to_s3.dart';
import 'package:get/get.dart';
// Import your model file here

class HotelDetailController extends GetxController {
  var isLoading = true.obs;
  var hotelData = Rxn<HotelDetailsHomeData>();
  var selectedRoomIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadHotelData();
  }

  void loadHotelData() async {
    try {
      isLoading(true);

      // schoolContactUsData=null;
      ResponseModel response = await HotelServiceRepo().getHotelHomeRepo();
      HotelDetailsHomeResModel hotelDetailsHomeResModel =
          HotelDetailsHomeResModel.fromJson(response.response?.data);

      if (response.isSuccess) {
        hotelData.value = hotelDetailsHomeResModel.data;
        if (dynamicRoomTypes.isNotEmpty) {
          selectedRoomType.value = dynamicRoomTypes.first;
        }
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR ${e}");
      // TODO
    } finally {
      isLoading(false);
    }
  }

  uploadSchoolLogoOrBannerImage(
      {required File uploadFile, required String uploadVia}) async {
    try {
      UploadResult? result = await S3UploadService.uploadFile(uploadFile);
      if (result.isSuccess) {
        ResponseModel response = await HotelServiceRepo()
            .updateHotelProfileRepo(reqBODY: {
          uploadVia: result.url,
          // "name": "Space X Hotel",
          // "description": "A hotel is a commercial establishment offering paid, short-term lodging with amenities like beds, bathrooms, and often food, services (room service, laundry), and facilities (pools, gyms, meeting rooms), varying from budget to luxury and classified by star ratings or type (boutique, resort, extended-stay) to indicate expected quality and offerings for travelers.",
          // "location": {
          //   "name": "Saputara",
          //   "type": "Point",
          //   "coordinates": [
          //     20.57669291042334, 73.7400462812614
          //   ]
          // },
          "name": hotelData.value?.profile?.name
        });
        if (response.isSuccess) {
          commonSnackBar(message: response.response?.data['message']);
          loadHotelData();

        } else {
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }
      }
    } on Exception catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);

      // TODO
    }
  }

  // Get unique types dynamically from the data
  List<String> get dynamicRoomTypes {
    final rooms = hotelData.value?.rooms ?? [];
    // Extract types, remove nulls/empty, and get unique values
    return rooms
        .map((e) => e.type ?? "")
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
  }

  var selectedRoomType = "".obs; // Start empty

  List<Rooms> get filteredRooms {
    return hotelData.value?.rooms
            ?.where((room) => room.type == selectedRoomType.value)
            .toList() ??
        [];
  }
}
