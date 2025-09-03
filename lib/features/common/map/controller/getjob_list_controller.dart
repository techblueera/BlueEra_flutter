import 'package:BlueEra/features/common/auth/model/get_all_jobs_model.dart';
import 'package:BlueEra/features/common/map/repo/add_job_repo.dart';
import 'package:get/get.dart';

class JobController extends GetxController {
  RxList<Jobs> allJobs = <Jobs>[].obs;
  var isLoading = false.obs;

  Future<void> fetchJobs(lat,lng) async {
    try {
      isLoading.value = true;
      final response = await AddJobRepo().fetchJobList(lat: lat,lng: lng);
      if (response.statusCode == 200) {
        print("dngkjb ${response.statusCode}");
        final List<Jobs> places = List<Jobs>.from(
          (response.response!.data as List).map((e) => Jobs.fromJson(e)),
        );
        allJobs.value = places;
        update();
        print("dngksafjb ${allJobs.length}");
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
