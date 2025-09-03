import 'package:get/get.dart';

import '../model/store_list_model.dart';
import '../repo/store_repo.dart';

class StoreController extends GetxController {
  RxList<StoreDataModel> allStore = <StoreDataModel>[].obs;
  var isLoading = false.obs;

  Future<void> fetchStores(lat,lng) async {
    try {
      isLoading.value = true;
      final response = await StoreDataRepo().fetchStoreList(lat: lat,lng: lng);
      if (response.statusCode == 200) {
        print("dngkjb ${response.statusCode}");
        final List<StoreDataModel> stores = List<StoreDataModel>.from(
          (response.response!.data as List).map((e) => StoreDataModel.fromJson(e)),
        );
        allStore.value = stores;
        update();
        print("dngksafjb ${allStore.length}");
      } else {
        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStoreDetail({required String? storeId}) async {
    try {
      isLoading.value = true;
      final response = await StoreDataRepo().fetchStoreDetails(storeId: storeId!); // Make sure repo uses params
      if (response.statusCode == 200) {
        final List<StoreDataModel> places = List<StoreDataModel>.from(
          (response.response!.data as List).map((e) => StoreDataModel.fromJson(e)),
        );
        allStore.value = places;
      } else {
        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

}
