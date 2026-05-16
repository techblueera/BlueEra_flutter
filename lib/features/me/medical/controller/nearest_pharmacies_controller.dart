import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:get/get.dart';

class PharmacyItem {
  final String id;
  final String name;
  final String address;
  final String email;
  final String phone;
  final String pincode;
  final String openFrom;
  final String openTill;
  final String logo;
  final double rating;
  final int reviews;
  final List inventories;
  final Map<String, dynamic> raw;

  PharmacyItem({
    required this.id,
    required this.name,
    required this.address,
    required this.email,
    required this.phone,
    required this.pincode,
    required this.openFrom,
    required this.openTill,
    required this.logo,
    required this.rating,
    required this.reviews,
    required this.inventories,
    required this.raw,
  });

  factory PharmacyItem.fromJson(Map<String, dynamic> json) {
    return PharmacyItem(
      id: json['_id']?.toString() ?? '',
      name: json['business_name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      email: json['business_number']?['email']?.toString() ?? '',
      phone: json['business_number']?['phone']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      openFrom: json['openFrom']?.toString() ?? '',
      openTill: json['openTill']?.toString() ?? '',
      logo: json['logo']?.toString() ?? '',
      rating: (json['avg_rating'] is num)
          ? (json['avg_rating'] as num).toDouble()
          : 0.0,
      reviews:
          json['total_ratings'] is int ? json['total_ratings'] : 0,
      inventories: (json['inventories'] as List?) ?? [],
      raw: json,
    );
  }
}

class NearestPharmaciesController extends GetxController {
  final MedicalRepo _repo = MedicalRepo();
  final pharmacies = <PharmacyItem>[].obs;
  final isLoading = false.obs;
  final error = ''.obs;
  final responseState = ApiResponse.initial('Initial').obs;
  // curl -X 'GET' \
  // 'https://be.beapp.in/api/user-service/business/filter?category=HOSPITAL_SECTOR&page=1&limit=10' \
  // -H 'accept: application/json'
  Future<void> fetchNearest({
    required String category,
    String? subCategory,
    int page = 1,
    int limit = 10,
  }) async {
    isLoading.value = true;
    error.value = '';
    pharmacies.clear();
    responseState.value = ApiResponse.initial('Initial');
    try {
      final ResponseModel res = await _repo.fetchFilteredBusinessRepo(
        category: category,
        subCategory: subCategory,
        page: page,
        limit: limit,
      );
      if (res.isSuccess) {
        responseState.value = ApiResponse.complete(res);
        final List data = res.response?.data?['data'] ?? [];
        final items = data.map((e) => PharmacyItem.fromJson(e)).toList();
        pharmacies.assignAll(items);
        if (items.isEmpty) {
          error.value = 'No pharmacies found';
        }
      } else {
        error.value = res.message ?? AppStrings.somethingWentWrong;
        responseState.value = ApiResponse.error(error.value);
        commonSnackBar(message: error.value);
      }
    } catch (e) {
      error.value = e.toString();
      responseState.value = ApiResponse.error(AppStrings.somethingWentWrong);
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }
}
