import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';

class AIService extends BaseService {
  Future<List<String>?> generateDescriptionRepo({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final response = await ApiBaseHelper().postHTTP(generateAIDescription,
        params: {
          "type": type,
          "data": data,
        },
        onError: (error) {},
        onSuccess: (data) {});

    if (response.response?.data['success'] == true) {
      return List<String>.from(response.response?.data['data']);
    }
    return null;
    // return response;
  }
}
