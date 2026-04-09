// add_tiffin_response_model.dart

import 'package:BlueEra/features/personal/personal_profile/view/self_employed/model/tiffin_meal_model.dart';

class AddTiffinResponseModel {
  final bool success;
  final TiffinMealModel? tiffin;
  final List<String> uploadUrls;

  const AddTiffinResponseModel({
    this.success    = false,
    this.tiffin,
    this.uploadUrls = const [],
  });

  factory AddTiffinResponseModel.fromJson(Map<String, dynamic> json) {
    return AddTiffinResponseModel(
      success:    json['success']    ?? false,
      tiffin:     json['tiffin'] != null
          ? TiffinMealModel.fromJson(json['tiffin'])
          : null,
      uploadUrls: List<String>.from(json['uploadUrls'] ?? []), // ✅ direct array
    );
  }
}