import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/personal/resume/repo/resume_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PortfolioController extends GetxController {
  final portfolioLinks = <String>[].obs;
  final portfolioController = TextEditingController();
  final isValidate = false.obs;
  final isAddPortfolioValidate = false.obs;
  
  ApiResponse addPortfolioResponse = ApiResponse.initial('Initial');
  ApiResponse fetchPortfoliosResponse = ApiResponse.initial('Initial');
  
  @override
  void onInit() {
    super.onInit();
    // fetchPortfolios();
    portfolioController.addListener(validateForm);
  }
  
  @override
  void onClose() {
    portfolioController.dispose();
    super.onClose();
  }
  
  void validateForm() {
    isAddPortfolioValidate.value = portfolioController.text.isNotEmpty;
    isValidate.value = portfolioLinks.isNotEmpty;
  }
  
  // void addPortfolioLink(String link) {
  //   if (link.isNotEmpty && !portfolioLinks.contains(link)) {
  //     portfolioLinks.add(link);
  //     portfolioController.clear();
  //     isAddPortfolioValidate.value = false;
  //     validateForm();
  //   }
  // }
  void addPortfolioLink(String link) {
  final normalizedLink = link.trim().toLowerCase();
  final existingLinks = portfolioLinks.map((e) => e.trim().toLowerCase()).toList();

  if (normalizedLink.isNotEmpty && !existingLinks.contains(normalizedLink)) {
    portfolioLinks.add(link.trim()); 
    portfolioController.clear();
    isAddPortfolioValidate.value = false;
    validateForm();
  } else {
    commonSnackBar(message: "This link is already added");
  }
}

 Future<void> deletePortfolioLink(String link) async {
  try {
    final res = await ResumeRepo().deletePortfolio(portfolioLink: link);
    if (res.isSuccess) {
      portfolioLinks.remove(link);
      validateForm();
      commonSnackBar(message: res.response?.data['message'] ?? "Portfolio deleted successfully");
    } else {
      commonSnackBar(message: res.message ?? "Failed to delete portfolio link");
    }
  } catch (e) {
    commonSnackBar(message: "Error occurred while deleting portfolio");
  }
}


  
  void removePortfolioLink(String link) {
    portfolioLinks.remove(link);
    validateForm();
  }
  
  Future<void> savePortfolio(BuildContext context) async {
    try {
      final params = {
        "portfolios": portfolioLinks.isNotEmpty ? portfolioLinks : ""
      };
      
      final res = await ResumeRepo().addPortfolio(params: params);
      if (res.isSuccess) {
        addPortfolioResponse = ApiResponse.complete(res);
        // await fetchPortfolios(); // Update the portfolio list
        Get.back();
        commonSnackBar(message: res.response?.data['message'] ?? "Portfolio added successfully");
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      addPortfolioResponse = ApiResponse.error('Addition failed');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  
  // Future<void> fetchPortfolios() async {
  //   try {
  //     final res = await ResumeRepo().fetchPortfolios(params: {});
  //     if (res.isSuccess) {
  //       fetchPortfoliosResponse = ApiResponse.complete(res);
  //       final data = res.response?.data;
  //       portfolioLinks.clear();
        
  //       if (data != null && data['portfolio'] != null) {
  //         portfolioLinks.add(data['portfolio']);
  //       }
        
  //       validateForm();
  //     } else {
  //       fetchPortfoliosResponse = ApiResponse.error(res.message ?? 'Failed to fetch portfolios');
  //     }
  //   } catch (e) {
  //     fetchPortfoliosResponse = ApiResponse.error('Failed to fetch portfolios');
  //   }
  // }
//   Future<void> fetchPortfolios() async {
//   try {
//     final res = await ResumeRepo().fetchPortfolios(params: {});
//     if (res.isSuccess) {
//       fetchPortfoliosResponse = ApiResponse.complete(res);
//       final data = res.response?.data;
//       portfolioLinks.clear();

//       if (data != null && data['portfolios'] != null) {
//         if (data['portfolios'] is List) {
//           for (final link in data['portfolios']) {
//             if (link is String && link.isNotEmpty) {
//               portfolioLinks.add(link);
//             }
//           }
//         } else if (data['portfolios'] is String && data['portfolios'].isNotEmpty) {
//           portfolioLinks.add(data['portfolios']);
//         }
//       }
//       validateForm();
//     } else {
//       fetchPortfoliosResponse = ApiResponse.error(res.message ?? 'Failed to fetch portfolios');
//     }
//   } catch (e) {
//     fetchPortfoliosResponse = ApiResponse.error('Failed to fetch portfolios');
//   }
// }

}