import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_service_repo.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_full_details_res_model.dart';
import 'package:get/get.dart';

class LabProfileListItem {
  final String id;
  final String name;
  final String description;
  final String coverUrl;
  final String logoUrl;
  final Data? fullDetails;

  LabProfileListItem({
    required this.id,
    required this.name,
    required this.description,
    required this.coverUrl,
    required this.logoUrl,
    this.fullDetails,
  });

  factory LabProfileListItem.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('profile')) {
      final profile = json['profile'] ?? {};
      final data = Data.fromJson({
        'profile': json['profile'],
        'tests': json['tests'] ?? [],
        'contactInfo': json['contactInfo'],
        'galleries': json['galleries'] ?? [],
        'healthCamps': json['healthCamps'] ?? [],
        'facility': json['facility'],
      });
      return LabProfileListItem(
        id: profile['_id']?.toString() ?? '',
        name: profile['name']?.toString() ?? '',
        description: profile['description']?.toString() ?? '',
        coverUrl: profile['coverUrl']?.toString() ?? '',
        logoUrl: profile['logoUrl']?.toString() ?? '',
        fullDetails: data,
      );
    } else {
      return LabProfileListItem(
        id: json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        coverUrl: json['coverUrl']?.toString() ?? '',
        logoUrl: json['logoUrl']?.toString() ?? '',
      );
    }
  }
}

class LabProfilesListController extends GetxController {
  final LabServiceRepo _repo = LabServiceRepo();

  final profiles = <LabProfileListItem>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final error = ''.obs;

  int page = 1;
  final int limit = 10;

  @override
  void onInit() {
    super.onInit();
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    profiles.clear();
    page = 1;
    hasMore.value = true;
    await _fetch(page, isLoadMore: false);
  }

  Future<void> fetchMore() async {
    if (!hasMore.value || isLoadingMore.value) return;
    page += 1;
    await _fetch(page, isLoadMore: true);
  }

  Future<void> _fetch(int p, {required bool isLoadMore}) async {
    try {
      if (isLoadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
      }
      error.value = '';

      final ResponseModel res =
          await _repo.listLaboratoryProfiles(page: p, limit: limit);

      if (res.isSuccess) {
        final List data = res.response?.data['data'] ?? [];
        final items =
            data.map((e) => LabProfileListItem.fromJson(e)).toList();
        if (items.isEmpty) {
          hasMore.value = false;
        } else {
          profiles.addAll(items);
        }
      } else {
        hasMore.value = false;
        error.value = res.message ?? AppStrings.somethingWentWrong;
        commonSnackBar(message: error.value);
      }
    } catch (e) {
      hasMore.value = false;
      error.value = e.toString();
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }
}
