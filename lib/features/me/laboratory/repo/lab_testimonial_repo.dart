import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

/// Wraps `/testimonials` — see lib/docs/LABORATORY_INTEGRATION.md §2.
class LabTestimonialRepo extends BaseService {
  Future<ResponseModel> createTestimonial(Map<String, dynamic> data) async {
    return await ApiBaseHelper().postHTTP(labTestimonials, params: data);
  }

  Future<ResponseModel> getTestimonialsByLab(String labId) async {
    return await ApiBaseHelper().getHTTP('$labTestimonialsByLab/$labId');
  }

  Future<ResponseModel> getMyTestimonials() async {
    return await ApiBaseHelper().getHTTP(labTestimonials);
  }

  Future<ResponseModel> fetchTestimonialById(String id) async {
    return await ApiBaseHelper().getHTTP('$labTestimonials/$id');
  }

  Future<ResponseModel> updateTestimonial(
      String id, Map<String, dynamic> data) async {
    return await ApiBaseHelper().putHTTP('$labTestimonials/$id', params: data);
  }

  Future<ResponseModel> deleteTestimonial(String id) async {
    return await ApiBaseHelper().deleteHTTP('$labTestimonials/$id');
  }
}
