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
  

  void addPortfolioLink(String link) {
  final normalizedLink = link.trim().toLowerCase();
  final existingLinks = portfolioLinks.map((e) => e.trim().toLowerCase()).toList();

  if (normalizedLink.isNotEmpty && !existingLinks.contains(normalizedLink)) {
    portfolioLinks.add(link.trim()); 
    portfolioController.clear();
    isAddPortfolioValidate.value = false;
    validateForm();
  } else {
    commonSnackBar(message: AppStrings.portfolioLinkExists);
  }
}

 Future<void> deletePortfolioLink(String link) async {
  try {
    final res = await ResumeRepo().deletePortfolio(portfolioLink: link);
    if (res.isSuccess) {
      portfolioLinks.remove(link);
      validateForm();
      commonSnackBar(message: res.response?.data['message'] ?? AppStrings.portfolioDeletedSuccess);
    } else {
      commonSnackBar(message: res.message ?? AppStrings.portfolioDeleteFailed);
    }
  } catch (e) {
    commonSnackBar(message:AppStrings.portfolioDeleteError);
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
        commonSnackBar(message: res.response?.data['message'] ?? AppStrings.portfolioAddedSuccess);
      } else {
        commonSnackBar(message: res.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      addPortfolioResponse = ApiResponse.error('Addition failed');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}