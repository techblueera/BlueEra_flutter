import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class HotelServiceRepo extends BaseService {
  ///GET SCHOOL/UNIVERSITY DETAILS...
  Future<ResponseModel> getHotelServiceCategoryRepo() async {
    final response = await ApiBaseHelper().getHTTP("${hotelServiceCategory}",
        onError: (error) {}, onSuccess: (data) {});
    return response;
  }
}
