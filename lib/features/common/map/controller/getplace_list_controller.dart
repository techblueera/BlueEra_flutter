import 'package:get/get.dart';

// Adjust import path
import '../place_list_model.dart';
import '../repo/add_place_repo.dart';    // Your API service

class PlaceController extends GetxController {
  RxList<PlaceList> allPlaces = <PlaceList>[].obs;
  RxList<Coordinates> locationGet = <Coordinates>[].obs;
  var isLoading = false.obs;

  Future<void> fetchPlaces(double lat,double lng) async {
    try {
      isLoading.value = true;
      final response = await AddPlaceRepo().fetchPlaceList(lat: lat,lng: lng); // Make sure repo uses params
      if (response.statusCode == 200) {
        final List<PlaceList> places = List<PlaceList>.from(
          (response.response!.data as List).map((e) => PlaceList.fromJson(e)),
        );
        allPlaces.value = places;
        print("dngksafjb ${allPlaces.length}");
      } else {
        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPlaceDetail({required String? placeId}) async {
    try {
      isLoading.value = true;
      final response = await AddPlaceRepo().fetchPlaceDetails(placeId: placeId!); // Make sure repo uses params
      if (response.statusCode == 200) {
        final List<PlaceList> places = List<PlaceList>.from(
          (response.response!.data as List).map((e) => PlaceList.fromJson(e)),
        );
        allPlaces.value = places;
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
