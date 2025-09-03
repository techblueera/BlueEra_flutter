// // import 'dart:io';
// // import 'package:BlueEra/core/api/apiService/api_keys.dart';
// // import 'package:BlueEra/core/constants/app_strings.dart';
// // import 'package:BlueEra/core/constants/snackbar_helper.dart';
// // import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// //
// // class PublicationsController extends GetxController {
// //   final ResumeRepo _repo = ResumeRepo();
// //
// //   // Form controllers
// //   final titleController = TextEditingController();
// //   final linkController = TextEditingController();
// //   final descriptionController = TextEditingController();
// //
// //   // Date controllers
// //   final dateController = TextEditingController();
// //   final monthController = TextEditingController();
// //   final yearController = TextEditingController();
// //
// //   // Observables
// //   final publications = <Map<String, dynamic>>[].obs;
// //   final isLoading = false.obs;
// //   final selectedPublication = Rxn<Map<String, dynamic>>();
// //   RxnString selectedPublicationId = RxnString();
// //
// //   @override
// //   void onInit() {
// //     getAllPublicationsApi();
// //     super.onInit();
// //   }
// //
// //   @override
// //   void onClose() {
// //     titleController.dispose();
// //     linkController.dispose();
// //     descriptionController.dispose();
// //     dateController.dispose();
// //     monthController.dispose();
// //     yearController.dispose();
// //     super.onClose();
// //   }
// //
// //   // Clear form
// //   void clearForm() {
// //     titleController.clear();
// //     linkController.clear();
// //     descriptionController.clear();
// //     dateController.clear();
// //     monthController.clear();
// //     yearController.clear();
// //     selectedPublication.value = null;
// //     selectedPublicationId.value = null;
// //   }
// //
// //   // Fill form for editing
// //   void fillFormForEdit(Map<String, dynamic> publication) {
// //     selectedPublication.value = publication;
// //     selectedPublicationId.value = publication['_id'] ?? '';
// //
// //     titleController.text = publication['title'] ?? '';
// //     linkController.text = publication['link'] ?? '';
// //     descriptionController.text = publication['description'] ?? '';
// //
// //     // Handle date parsing
// //     if (publication['publishedDate'] != null) {
// //       final publishedDate = publication['publishedDate'];
// //       dateController.text = publishedDate['date']?.toString() ?? '';
// //       monthController.text = publishedDate['month']?.toString() ?? '';
// //       yearController.text = publishedDate['year']?.toString() ?? '';
// //     }
// //   }
// //
// //   /// GET ALL PUBLICATIONS
// //   Future<void> getAllPublicationsApi() async {
// //     try {
// //       isLoading.value = true;
// //       final response = await _repo.getAllPublications(params: {});
// //
// //       if (response.isSuccess) {
// //         final data = response.response?.data;
// //         if (data != null && data['data'] is List) {
// //           publications.value = List<Map<String, dynamic>>.from(data['data']);
// //         }
// //       } else {
// //         commonSnackBar(
// //             message: response.response?.data['message'] ?? AppStrings.somethingWentWrong
// //         );
// //       }
// //     } catch (e) {
// //       print("ERROR in getAllPublicationsApi: $e");
// //       commonSnackBar(message: AppStrings.somethingWentWrong);
// //     } finally {
// //       isLoading.value = false;
// //     }
// //   }
// //
// //   /// GET PUBLICATION BY ID
// //   Future<void> getPublicationByIdApi(String id) async {
// //     try {
// //       isLoading.value = true;
// //       final response = await _repo.getPublicationById(id: id, params: {});
// //
// //       if (response.isSuccess) {
// //         selectedPublication.value = response.response?.data;
// //         commonSnackBar(
// //             message: response.response?.data['message'] ?? AppStrings.success
// //         );
// //       } else {
// //         commonSnackBar(
// //             message: response.response?.data['message'] ?? AppStrings.somethingWentWrong
// //         );
// //       }
// //     } catch (e) {
// //       print("ERROR in getPublicationByIdApi: $e");
// //       commonSnackBar(message: AppStrings.somethingWentWrong);
// //     } finally {
// //       isLoading.value = false;
// //     }
// //   }
// //
// //   /// ADD PUBLICATION
// //   Future<void> addPublicationApi() async {
// //     if (!_validateForm()) return;
// //
// //     try {
// //       isLoading.value = true;
// //
// //       // Create publication object as per API requirement
// //       final publicationData = {
// //         "publications": [
// //           {
// //             "title": titleController.text.trim(),
// //             "link": linkController.text.trim(),
// //             "publishedDate": {
// //               "date": int.parse(dateController.text),
// //               "month": int.parse(monthController.text),
// //               "year": int.parse(yearController.text)
// //             },
// //             "description": descriptionController.text.trim()
// //           }
// //         ]
// //       };
// //
// //       final response = await _repo.addPublication(params: publicationData);
// //
// //       if (response.isSuccess) {
// //         commonSnackBar(
// //             message: response.response?.data['message'] ?? 'Publication added successfully!'
// //         );
// //         clearForm();
// //         await getAllPublicationsApi();
// //       } else {
// //         commonSnackBar(
// //             message: response.response?.data['message'] ?? AppStrings.somethingWentWrong
// //         );
// //       }
// //     } catch (e) {
// //       print("ERROR in addPublicationApi: $e");
// //       commonSnackBar(message: AppStrings.somethingWentWrong);
// //     } finally {
// //       isLoading.value = false;
// //     }
// //   }
// //
// //   /// UPDATE PUBLICATION
// //   Future<void> updatePublicationApi() async {
// //     if (!_validateForm()) return;
// //
// //     final id = selectedPublicationId.value;
// //     if (id == null || id.isEmpty) {
// //       commonSnackBar(message: "Publication ID missing for update.");
// //       return;
// //     }
// //
// //     try {
// //       isLoading.value = true;
// //
// //       // Create publication object as per API requirement
// //       final publicationData = {
// //         "publications": [
// //           {
// //             "title": titleController.text.trim(),
// //             "link": linkController.text.trim(),
// //             "publishedDate": {
// //               "date": int.parse(dateController.text),
// //               "month": int.parse(monthController.text),
// //               "year": int.parse(yearController.text)
// //             },
// //             "description": descriptionController.text.trim()
// //           }
// //         ]
// //       };
// //
// //       final response = await _repo.updatePublication(
// //         id: id,
// //         params: publicationData,
// //       );
// //
// //       if (response.isSuccess) {
// //         commonSnackBar(
// //           message: response.response?.data['message'] ?? 'Publication updated successfully!',
// //         );
// //         clearForm();
// //         await getAllPublicationsApi();
// //       } else {
// //         commonSnackBar(
// //           message: response.response?.data['message'] ?? AppStrings.somethingWentWrong,
// //         );
// //       }
// //     } catch (e) {
// //       print("ERROR in updatePublicationApi: $e");
// //       commonSnackBar(message: AppStrings.somethingWentWrong);
// //     } finally {
// //       isLoading.value = false;
// //     }
// //   }
// //
// //   /// DELETE PUBLICATION
// //   Future<void> deletePublicationApi(String id) async {
// //     try {
// //       isLoading.value = true;
// //       final response = await _repo.deletePublication(id: id);
// //
// //       if (response.isSuccess) {
// //         commonSnackBar(
// //             message: response.response?.data['message'] ?? 'Publication deleted successfully!'
// //         );
// //         await getAllPublicationsApi();
// //       } else {
// //         commonSnackBar(
// //             message: response.response?.data['message'] ?? AppStrings.somethingWentWrong
// //         );
// //       }
// //     } catch (e) {
// //       print("ERROR in deletePublicationApi: $e");
// //       commonSnackBar(message: AppStrings.somethingWentWrong);
// //     } finally {
// //       isLoading.value = false;
// //     }
// //   }
// //
// //   /// VALIDATE FORM
// //   bool _validateForm() {
// //     if (titleController.text.trim().isEmpty) {
// //       commonSnackBar(message: 'Please enter publication title');
// //       return false;
// //     }
// //
// //     if (linkController.text.trim().isEmpty) {
// //       commonSnackBar(message: 'Please enter publication link');
// //       return false;
// //     }
// //
// //     // Validate URL format
// //     if (!GetUtils.isURL(linkController.text.trim())) {
// //       commonSnackBar(message: 'Please enter a valid URL');
// //       return false;
// //     }
// //
// //     if (dateController.text.trim().isEmpty ||
// //         monthController.text.trim().isEmpty ||
// //         yearController.text.trim().isEmpty) {
// //       commonSnackBar(message: 'Please enter complete published date');
// //       return false;
// //     }
// //
// //     // Validate date values
// //     try {
// //       final date = int.parse(dateController.text);
// //       final month = int.parse(monthController.text);
// //       final year = int.parse(yearController.text);
// //
// //       if (date < 1 || date > 31) {
// //         commonSnackBar(message: 'Please enter valid date (1-31)');
// //         return false;
// //       }
// //
// //       if (month < 1 || month > 12) {
// //         commonSnackBar(message: 'Please enter valid month (1-12)');
// //         return false;
// //       }
// //
// //       if (year < 1900 || year > DateTime.now().year) {
// //         commonSnackBar(message: 'Please enter valid year');
// //         return false;
// //       }
// //     } catch (e) {
// //       commonSnackBar(message: 'Please enter valid numeric values for date');
// //       return false;
// //     }
// //
// //     if (descriptionController.text.trim().isEmpty) {
// //       commonSnackBar(message: 'Please enter description');
// //       return false;
// //     }
// //
// //     return true;
// //   }
// // }
// import 'dart:io';
// import 'package:BlueEra/core/api/apiService/api_keys.dart';
// import 'package:BlueEra/core/constants/app_strings.dart';
// import 'package:BlueEra/core/constants/snackbar_helper.dart';
// import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// class PublicationsController extends GetxController {
//   final ResumeRepo _repo = ResumeRepo();
//
//   // Form controllers
//   final titleController = TextEditingController();
//   final linkController = TextEditingController();
//   final descriptionController = TextEditingController();
//
//   // Date controllers
//   final dateController = TextEditingController();
//   final monthController = TextEditingController();
//   final yearController = TextEditingController();
//
//   // Observables
//   final publications = <Map<String, dynamic>>[].obs;
//   final isLoading = false.obs;
//   final selectedPublication = Rxn<Map<String, dynamic>>();
//   RxnString selectedPublicationId = RxnString();
//
//   @override
//   void onInit() {
//     getAllPublicationsApi();
//     super.onInit();
//   }
//
//   @override
//   void onClose() {
//     titleController.dispose();
//     linkController.dispose();
//     descriptionController.dispose();
//     dateController.dispose();
//     monthController.dispose();
//     yearController.dispose();
//     super.onClose();
//   }
//
//   // Clear form
//   void clearForm() {
//     titleController.clear();
//     linkController.clear();
//     descriptionController.clear();
//     dateController.clear();
//     monthController.clear();
//     yearController.clear();
//     selectedPublication.value = null;
//     selectedPublicationId.value = null;
//   }
//
//   // Fill form for editing
//   void fillFormForEdit(Map<String, dynamic> publication) {
//     selectedPublication.value = publication;
//     selectedPublicationId.value = publication['_id']?.toString() ?? '';
//
//     titleController.text = publication['title']?.toString() ?? '';
//     linkController.text = publication['link']?.toString() ?? '';
//     descriptionController.text = publication['description']?.toString() ?? '';
//
//     // Handle date parsing - FIXED VERSION
//     if (publication['publishedDate'] != null) {
//       final publishedDate = publication['publishedDate'];
//
//       // Safe parsing with proper type conversion
//       if (publishedDate['date'] != null) {
//         dateController.text = publishedDate['date'].toString();
//       }
//       if (publishedDate['month'] != null) {
//         monthController.text = publishedDate['month'].toString();
//       }
//       if (publishedDate['year'] != null) {
//         yearController.text = publishedDate['year'].toString();
//       }
//     }
//   }
//
//   /// GET ALL PUBLICATIONS - FIXED VERSION
//   // Future<void> getAllPublicationsApi() async {
//   //   try {
//   //     isLoading.value = true;
//   //     final response = await _repo.getAllPublications(params: {});
//   //
//   //     print("API Response: ${response.response?.data}"); // Debug log
//   //
//   //     if (response.isSuccess) {
//   //       final data = response.response?.data;
//   //
//   //       if (data != null) {
//   //         // Handle different response formats
//   //         List<dynamic> publicationsList = [];
//   //
//   //         if (data['data'] is List) {
//   //           publicationsList = data['data'];
//   //         } else if (data['publications'] is List) {
//   //           publicationsList = data['publications'];
//   //         } else if (data is List) {
//   //           publicationsList = data;
//   //         }
//   //
//   //         // Safe conversion with proper type handling
//   //         publications.value = publicationsList.map((item) {
//   //           if (item is Map<String, dynamic>) {
//   //             return Map<String, dynamic>.from(item);
//   //           }
//   //           return <String, dynamic>{};
//   //         }).toList();
//   //
//   //         print("Publications loaded: ${publications.length}"); // Debug log
//   //       } else {
//   //         publications.clear();
//   //       }
//   //     } else {
//   //       final errorMessage = response.response?.data?['message']?.toString() ??
//   //           AppStrings.somethingWentWrong;
//   //       commonSnackBar(message: errorMessage);
//   //       publications.clear();
//   //     }
//   //   } catch (e) {
//   //     print("ERROR in getAllPublicationsApi: $e");
//   //     commonSnackBar(message: AppStrings.somethingWentWrong);
//   //     publications.clear();
//   //   } finally {
//   //     isLoading.value = false;
//   //   }
//   // }
//   Future<void> getAllPublicationsApi() async {
//     try {
//       print("🔄 Starting getAllPublicationsApi...");
//       isLoading.value = true;
//
//       final response = await _repo.getAllPublications(params: {});
//       print("📡 API Response received: ${response.response?.data}");
//       print("✅ Response success: ${response.isSuccess}");
//
//       if (response.isSuccess) {
//         final data = response.response?.data;
//         print("📊 Raw data: $data");
//
//         if (data != null) {
//           List<dynamic> publicationsList = [];
//
//           if (data['data'] is List) {
//             publicationsList = data['data'];
//             print("📋 Found data in 'data' key");
//           } else if (data['publications'] is List) {
//             publicationsList = data['publications'];
//             print("📋 Found data in 'publications' key");
//           } else if (data is List) {
//             publicationsList = data;
//             print("📋 Data itself is a list");
//           } else {
//             print("❌ No valid list found in response");
//           }
//
//           publications.value = publicationsList.map((item) {
//             if (item is Map<String, dynamic>) {
//               return Map<String, dynamic>.from(item);
//             }
//             return <String, dynamic>{};
//           }).toList();
//
//           print("✅ Publications loaded: ${publications.length} items");
//           print("📝 Publications data: ${publications.value}");
//         } else {
//           print("❌ Data is null");
//           publications.clear();
//         }
//       } else {
//         print("❌ API call failed");
//         final errorMessage = response.response?.data?['message']?.toString() ??
//             AppStrings.somethingWentWrong;
//         commonSnackBar(message: errorMessage);
//         publications.clear();
//       }
//     } catch (e) {
//       print("💥 ERROR in getAllPublicationsApi: $e");
//       print("📍 Stack trace: ${StackTrace.current}");
//       commonSnackBar(message: AppStrings.somethingWentWrong);
//       publications.clear();
//     } finally {
//       isLoading.value = false;
//       print("🏁 getAllPublicationsApi completed. Loading: ${isLoading.value}");
//     }
//   }
//
//
//   /// GET PUBLICATION BY ID
//   Future<void> getPublicationByIdApi(String id) async {
//     try {
//       isLoading.value = true;
//       final response = await _repo.getPublicationById(id: id, params: {});
//
//       if (response.isSuccess) {
//         selectedPublication.value = response.response?.data;
//         commonSnackBar(
//             message: response.response?.data['message'] ?? AppStrings.success
//         );
//       } else {
//         commonSnackBar(
//             message: response.response?.data['message'] ?? AppStrings.somethingWentWrong
//         );
//       }
//     } catch (e) {
//       print("ERROR in getPublicationByIdApi: $e");
//       commonSnackBar(message: AppStrings.somethingWentWrong);
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   /// ADD PUBLICATION
//   Future<void> addPublicationApi() async {
//     if (!_validateForm()) return;
//
//     try {
//       isLoading.value = true;
//
//       // Create publication object as per API requirement
//       final publicationData = {
//         "publications": [
//           {
//             "title": titleController.text.trim(),
//             "link": linkController.text.trim(),
//             "publishedDate": {
//               "date": int.parse(dateController.text),
//               "month": int.parse(monthController.text),
//               "year": int.parse(yearController.text)
//             },
//             "description": descriptionController.text.trim()
//           }
//         ]
//       };
//
//       final response = await _repo.addPublication(params: publicationData);
//
//       if (response.isSuccess) {
//         commonSnackBar(
//             message: response.response?.data['message'] ?? 'Publication added successfully!'
//         );
//         clearForm();
//         await getAllPublicationsApi();
//       } else {
//         commonSnackBar(
//             message: response.response?.data['message'] ?? AppStrings.somethingWentWrong
//         );
//       }
//     } catch (e) {
//       print("ERROR in addPublicationApi: $e");
//       commonSnackBar(message: AppStrings.somethingWentWrong);
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   /// UPDATE PUBLICATION
//   Future<void> updatePublicationApi() async {
//     if (!_validateForm()) return;
//
//     final id = selectedPublicationId.value;
//     if (id == null || id.isEmpty) {
//       commonSnackBar(message: "Publication ID missing for update.");
//       return;
//     }
//
//     try {
//       isLoading.value = true;
//
//       // Create publication object as per API requirement
//       final publicationData = {
//         "publications": [
//           {
//             "title": titleController.text.trim(),
//             "link": linkController.text.trim(),
//             "publishedDate": {
//               "date": int.parse(dateController.text),
//               "month": int.parse(monthController.text),
//               "year": int.parse(yearController.text)
//             },
//             "description": descriptionController.text.trim()
//           }
//         ]
//       };
//
//       final response = await _repo.updatePublication(
//         id: id,
//         params: publicationData,
//       );
//
//       if (response.isSuccess) {
//         commonSnackBar(
//           message: response.response?.data['message'] ?? 'Publication updated successfully!',
//         );
//         clearForm();
//         await getAllPublicationsApi();
//       } else {
//         commonSnackBar(
//           message: response.response?.data['message'] ?? AppStrings.somethingWentWrong,
//         );
//       }
//     } catch (e) {
//       print("ERROR in updatePublicationApi: $e");
//       commonSnackBar(message: AppStrings.somethingWentWrong);
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   /// DELETE PUBLICATION
//   Future<void> deletePublicationApi(String id) async {
//     try {
//       isLoading.value = true;
//       final response = await _repo.deletePublication(id: id);
//
//       if (response.isSuccess) {
//         commonSnackBar(
//             message: response.response?.data['message'] ?? 'Publication deleted successfully!'
//         );
//         await getAllPublicationsApi();
//       } else {
//         commonSnackBar(
//             message: response.response?.data['message'] ?? AppStrings.somethingWentWrong
//         );
//       }
//     } catch (e) {
//       print("ERROR in deletePublicationApi: $e");
//       commonSnackBar(message: AppStrings.somethingWentWrong);
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   /// VALIDATE FORM
//   bool _validateForm() {
//     if (titleController.text.trim().isEmpty) {
//       commonSnackBar(message: 'Please enter publication title');
//       return false;
//     }
//
//     if (linkController.text.trim().isEmpty) {
//       commonSnackBar(message: 'Please enter publication link');
//       return false;
//     }
//
//     // Validate URL format
//     if (!GetUtils.isURL(linkController.text.trim())) {
//       commonSnackBar(message: 'Please enter a valid URL');
//       return false;
//     }
//
//     if (dateController.text.trim().isEmpty ||
//         monthController.text.trim().isEmpty ||
//         yearController.text.trim().isEmpty) {
//       commonSnackBar(message: 'Please enter complete published date');
//       return false;
//     }
//
//     // Validate date values
//     try {
//       final date = int.parse(dateController.text);
//       final month = int.parse(monthController.text);
//       final year = int.parse(yearController.text);
//
//       if (date < 1 || date > 31) {
//         commonSnackBar(message: 'Please enter valid date (1-31)');
//         return false;
//       }
//
//       if (month < 1 || month > 12) {
//         commonSnackBar(message: 'Please enter valid month (1-12)');
//         return false;
//       }
//
//       if (year < 1900 || year > DateTime.now().year) {
//         commonSnackBar(message: 'Please enter valid year');
//         return false;
//       }
//     } catch (e) {
//       commonSnackBar(message: 'Please enter valid numeric values for date');
//       return false;
//     }
//
//     if (descriptionController.text.trim().isEmpty) {
//       commonSnackBar(message: 'Please enter description');
//       return false;
//     }
//
//     return true;
//   }
// }
// FIXED Publications Controller - Handles String to Int conversion properly

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/controller/profile_pic_controller.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PublicationsController extends GetxController {
  final ResumeRepo _repo = ResumeRepo();
  
  final getResumeController = Get.find<ProfilePicController>();

  // Form controllers
  final titleController = TextEditingController();
  final linkController = TextEditingController();
  final descriptionController = TextEditingController();

  // Date controllers
  final dateController = TextEditingController();
  final monthController = TextEditingController();
  final yearController = TextEditingController();

  // Observables
  final publications = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final selectedPublication = Rxn<Map<String, dynamic>>();
  RxnString selectedPublicationId = RxnString();

  @override
  void onInit() {
    print("🚀 PublicationsController onInit called");
    // getAllPublicationsApi();
    super.onInit();
  }

  @override
  void onClose() {
    titleController.dispose();
    linkController.dispose();
    descriptionController.dispose();
    dateController.dispose();
    monthController.dispose();
    yearController.dispose();
    super.onClose();
  }

  // Clear form
  void clearForm() {
    titleController.clear();
    linkController.clear();
    descriptionController.clear();
    dateController.clear();
    monthController.clear();
    yearController.clear();
    selectedPublication.value = null;
    selectedPublicationId.value = null;
  }

  // Fill form for editing - FIXED VERSION
  void fillFormForEdit(Map<String, dynamic> publication) {
    try {
      selectedPublication.value = publication;
      selectedPublicationId.value = publication['_id']?.toString() ?? '';

      titleController.text = publication['title']?.toString() ?? '';
      linkController.text = publication['link']?.toString() ?? '';
      descriptionController.text = publication['description']?.toString() ?? '';

      // FIXED: Handle date parsing with proper null checks and type conversion
      if (publication['publishedDate'] != null) {
        final publishedDate = publication['publishedDate'];

        // Safe parsing with type conversion
        dateController.text = _safeParseInt(publishedDate['date']).toString();
        monthController.text = _safeParseInt(publishedDate['month']).toString();
        yearController.text = _safeParseInt(publishedDate['year']).toString();
      }
    } catch (e) {
      print("Error in fillFormForEdit: $e");
      clearForm();
    }
  }

  // Helper method to safely parse int values
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }


  /// ADD PUBLICATION
  Future<void> addPublicationApi() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      // Create publication object as per API requirement
      final publicationData = {
        "publications": [
          {
            "title": titleController.text.trim(),
            "link": linkController.text.trim(),
            "publishedDate": {
              "date": int.parse(dateController.text),
              "month": int.parse(monthController.text),
              "year": int.parse(yearController.text)
            },
            "description": descriptionController.text.trim()
          }
        ]
      };

      final response = await _repo.addPublication(params: publicationData);

      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                'Publication added successfully!');
        clearForm();
        await getResumeController.getMyResume();
      } else {
        commonSnackBar(
            message: response.response?.data['message'] ??
                AppStrings.somethingWentWrong);
      }
    } catch (e) {
      print("ERROR in addPublicationApi: $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  /// UPDATE PUBLICATION - FIXED VERSION
  Future<void> updatePublicationApi() async {
    if (!_validateForm()) return;

    final id = selectedPublicationId.value;
    if (id == null || id.isEmpty) {
      commonSnackBar(message: "Publication ID missing.");
      return;
    }

    final publicationData = {
      "title": titleController.text.trim(),
      "link": linkController.text.trim(),
      "publishedDate": {
        "date": _safeParseInt(dateController.text),
        "month": _safeParseInt(monthController.text),
        "year": _safeParseInt(yearController.text),
      },
      "description": descriptionController.text.trim(),
    };

    try {
      isLoading.value = true;
      final response = await _repo.updatePublication(
        id: id,
        params: publicationData,
      );
      print('Update response: ${response.statusCode}, body: ${response.data}');

      if (response.statusCode == 200) {
        commonSnackBar(message: "Publication updated successfully");
        clearForm();
        // await getAllPublicationsApi();
        await getResumeController.getMyResume();
      } else {
        commonSnackBar(message: response.data?['message'] ?? "Update failed");
      }
    } catch (e) {
      print("Update error: $e");
      commonSnackBar(message: "Update failed");
    } finally {
      isLoading.value = false;
    }
  }

  /// DELETE PUBLICATION
  Future<void> deletePublicationApi(String id) async {
    try {
      isLoading.value = true;
      final response = await _repo.deletePublication(id: id);

      if (response.isSuccess) {
        commonSnackBar(
            message: response.response?.data['message'] ??
                'Publication deleted successfully!');
        // await getAllPublicationsApi();
       await getResumeController.getMyResume();
      } else {
        commonSnackBar(
            message: response.response?.data['message'] ??
                AppStrings.somethingWentWrong);
      }
    } catch (e) {
      print("ERROR in deletePublicationApi: $e");
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  /// VALIDATE FORM
  bool _validateForm() {
    if (titleController.text.trim().isEmpty) {
      commonSnackBar(message: 'Please enter publication title');
      return false;
    }

    if (linkController.text.trim().isEmpty) {
      commonSnackBar(message: 'Please enter publication link');
      return false;
    }

    // Validate URL format
    if (!GetUtils.isURL(linkController.text.trim())) {
      commonSnackBar(message: 'Please enter a valid URL');
      return false;
    }

    if (dateController.text.trim().isEmpty ||
        monthController.text.trim().isEmpty ||
        yearController.text.trim().isEmpty) {
      commonSnackBar(message: 'Please enter complete published date');
      return false;
    }

    // Validate date values with safe parsing
    try {
      final date = _safeParseInt(dateController.text);
      final month = _safeParseInt(monthController.text);
      final year = _safeParseInt(yearController.text);

      if (date < 1 || date > 31) {
        commonSnackBar(message: 'Please enter valid date (1-31)');
        return false;
      }

      if (month < 1 || month > 12) {
        commonSnackBar(message: 'Please enter valid month (1-12)');
        return false;
      }

      if (year < 1900 || year > DateTime.now().year) {
        commonSnackBar(message: 'Please enter valid year');
        return false;
      }
    } catch (e) {
      commonSnackBar(message: 'Please enter valid numeric values for date');
      return false;
    }

    if (descriptionController.text.trim().isEmpty) {
      commonSnackBar(message: 'Please enter description');
      return false;
    }

    return true;
  }
}
