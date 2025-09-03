import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:get/get.dart';

class EntityController extends GetxController {
  final bool isPatent; 

  EntityController({required this.isPatent});

  final additionalInfoList = <Map<String, String>>[].obs;
  void addAdditionalInfoToList(String title, String description) {
    additionalInfoList.add({
      'title': title,
      'subtitle1': description,
    });
  }

  final ResumeRepo repo = ResumeRepo();

  final RxList<Map<String, dynamic>> entityList = <Map<String, dynamic>>[].obs;



  // Future<void> fetchEntities() async {
  //   final res = await repo.fetchAllEntities(isPatent: isPatent);
  //   if (res.isSuccess && res.response?.data != null) {
  //     final rawList = res.response!.data as List<dynamic>;
  //     entityList.assignAll(rawList.map((e) {
  //       final item = e as Map<String, dynamic>;
  //       return {
  //         '_id': item['_id'],
  //         'title': item['title'] ?? '',
  //         'subtitle1': formatDate(isPatent
  //             ? item['issuedDate']
  //             : item['certifiedDate']), 
  //         'document': isPatent
  //             ? (item['patentCertification'] != null
  //                 ? [item['patentCertification']]
  //                 : [])
  //             : (item['attachment'] != null ? [item['attachment']] : []),
  //         'subtitle2': item['description'] ?? '', 
  //       };
  //     }).toList());
  //   } else {
  //     entityList.clear();
  //   }
  // }

  /// Add new entity
Future<ResponseModel> addEntity(Map<String, dynamic> params, {String? imagePath}) async {
  final res = await repo.addEntity(isPatent: isPatent, params: params, imagePath: imagePath);
  // if (res.isSuccess) await fetchEntities();
  return res;
}


  Future<ResponseModel> updateEntity(
    String id, Map<String, dynamic> params, {String? imagePath}) async {
  final res = await repo.updateEntity(
    isPatent: isPatent,
    id: id,
    params: params,
    imagePath: imagePath, 
  );
  if (res.isSuccess) {
    commonSnackBar(message: isPatent ? "Patent updated" : "NGO Org updated");
    // await fetchEntities();
  }
  return res;
}


  /// Delete entity by id
  Future<ResponseModel> deleteEntity(String id) async {
    final res = await repo.deleteEntity(isPatent: isPatent, id: id);
    if (res.isSuccess) {
      commonSnackBar(message: isPatent ? "Patent deleted" : "NGO Org deleted");
      // await fetchEntities();
    }
    return res;
  }

  // Utility: Format date map to string dd/mm/yyyy
  String formatDate(Map<String, dynamic>? dateMap) {
    if (dateMap == null) return '';
    final int? d = dateMap['date'];
    final int? m = dateMap['month'];
    final int? y = dateMap['year'];
    if (d != null && m != null && y != null) return '$d/$m/$y';
    return '';
  }
}
