import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/api/model/support_model.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../repo/user_repo.dart';

class HelpAndSupportController extends GetxController {
  RxString phoneNumber = '1234567890'.obs;
  RxString email = ''.obs;
  RxString message = ''.obs;
  RxBool isLoading = false.obs;
  RxString index = ' '.obs;
  RxString title = ' '.obs;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  RxList<SupportCase> allList = <SupportCase>[].obs;
  RxList<SupportCase> allList2 = <SupportCase>[].obs;
  RxList<SupportCase> allList3 = <SupportCase>[].obs;
  RxList<SupportCase> allList4 = <SupportCase>[].obs;
  ApiResponse addEmailResponse = ApiResponse.initial('Initial');
  @override
  void onClose() {
    emailController.dispose();
    messageController.dispose();// Clean up
    super.onClose();
  }
  void clearText() {
    emailController.clear();
    messageController.clear();
  }
  void setEmail(String value) {
    email.value = value;
  }

  void setMessage(String value) {
    message.value = value;
  }
  void setIndex(String value) {
    index.value = value;
  }
  void setTitle(String value) {
    title.value = value;
  }


  Future<void> makePhoneCall() async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber.value);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        Get.snackbar(
          'Error',
          'Could not launch phone dialer',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to make phone call: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  Future<void> addEmailSupport({required Map<String, dynamic> params}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final response = await UserRepo().postEmail(bodyRequest: params);
      if (response.statusCode == 201) {
        addEmailResponse = ApiResponse.complete(response);
        commonSnackBar(message: response.message ?? AppStrings.success);
        // Reset form
        clearText();

      } else {
        addEmailResponse = ApiResponse.error('error');
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      addEmailResponse =  ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> getSupportQuery(String filter) async {
    final queryParams = {
      ApiKeys.status: filter!="--"?filter:"",
    };
    try {
      isLoading.value = true;
      final response = await UserRepo().getQueries(queryParams: queryParams);
      print("dngkjb ${response.statusCode}");// Make sure repo uses params
      if (response.statusCode == 200) {
        final List<SupportCase> cases = List<SupportCase>.from(
          (response.response!.data as List).map((e) => SupportCase.fromJson(e)),
        );
        allList.value = cases;

        print("dngksafjb ${allList.length}");
      } else {
        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> getSearchById(String caseId) async {
    print("casee $caseId");
    final queryParams = {
      ApiKeys.caseId: caseId,
    };
    try {
      isLoading.value = true;
      final response = await UserRepo().getQuerySearch(queryParams: queryParams);
      print("dngkjb ${response.statusCode}");// Make sure repo uses params
      if (response.statusCode == 200) {
        final List<SupportCase> cases = List<SupportCase>.from(
          (response.response!.data as List).map((e) => SupportCase.fromJson(e)),
        );
        allList.value = cases;

        print("case id ${allList.length}");
      } else {
        print("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void copyPhoneNumber() {
    Clipboard.setData(ClipboardData(text: phoneNumber.value));
commonSnackBar(message:"phone number copied");
  }

  void submitForm() {
    if (email.value.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (message.value.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your message',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.value)) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;

    // Simulate API call
    Future.delayed(Duration(seconds: 2), () {
      isLoading.value = false;
      Map<String,dynamic> params = {
        ApiKeys.type: "Email",
        ApiKeys.email: "${email.value}",
        ApiKeys.message: "${message.value}",
        ApiKeys.status: "In Progress",
      };
      // Get.snackbar(
      //   'Success',
      //   'Your message has been submitted successfully!',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      // );

      addEmailSupport(params: params);

    });
  }
} 