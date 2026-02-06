import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/api/model/support_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/common_methods.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../model/faq_details_model.dart';
import '../repo/user_repo.dart';

class HelpAndSupportController extends GetxController {
  RxString phoneNumber = '1234567890'.obs;
  RxString email = ''.obs;
  RxString message = ''.obs;
  RxBool isLoading = false.obs;
  String index = '0';
  String title = 'Help & Support';
  final TextEditingController emailController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  RxList<SupportCase> allList = <SupportCase>[].obs;
  RxList<SupportCase> allList2 = <SupportCase>[].obs;
  RxList<SupportCase> allList3 = <SupportCase>[].obs;
  RxList<SupportCase> allList4 = <SupportCase>[].obs;
  RxList<FaqModel> faqDetailsList = <FaqModel>[].obs;
  RxList<String> pickedQueriesImages = <String>[].obs;

  ApiResponse addEmailResponse = ApiResponse.initial('Initial');
  Rx<ApiResponse> getFAQResponse = ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getQueryResponse = ApiResponse.initial('Initial').obs;
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
    index = value;
    update();
  }
  void setTitle(String value) {
    title = value;
    update();
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

    final queryParams = {
      ApiKeys.caseId: caseId,
    };
    try {
      isLoading.value = true;
      final response = await UserRepo().getQuerySearch(queryParams: queryParams);

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
//faq
  Future<void> getFaqsForHelp() async {
    try {

      final response = await UserRepo().getFaqsForHelp();

      if (response.statusCode == 200) {
        final List list =
            response.response!.data['faqs'] ?? [];

        final faqs = list
            .map((e) => FaqModel.fromJson(e))
            .toList();
        faqDetailsList.value = faqs;
        getFAQResponse.value=ApiResponse.complete(faqDetailsList);
      } else {
        print("API failed with status: ${response.statusCode}");
        getFAQResponse.value=ApiResponse.error("Error");
      }
    } catch (e) {
      print("Error: $e");
      getFAQResponse.value=ApiResponse.error("Error");
    } finally {
      isLoading.value = false;
    }
  }
  //queries
  Future<void> getQueriesForHelp() async {
    try {
      final response = await UserRepo().getQueriesHelp();

      if (response.statusCode == 200) {
        // final List list =
        //     response.response!.data['faqs'] ?? [];

        // final faqs = list
        //     .map((e) => FaqModel.fromJson(e))
        //     .toList();
        // faqDetailsList.value = faqs;
        // getFAQResponse.value=ApiResponse.complete(faqDetailsList);
      } else {
        print("API failed with status: ${response.statusCode}");
        //getFAQResponse.value=ApiResponse.error("Error");
      }
    } catch (e) {
      print("Error: $e");
      getFAQResponse.value = ApiResponse.error("Error");
    } finally {
      isLoading.value = false;
    }
  }


   Future<void> getQueriesVByIdForHelp(String Qid) async {
    try {

      final response = await UserRepo().getQueriesByIdForHelp(Qid);

      if (response.statusCode == 200) {
        // final List list =
        //     response.response!.data['faqs'] ?? [];

        // final faqs = list
        //     .map((e) => FaqModel.fromJson(e))
        //     .toList();
        // faqDetailsList.value = faqs;
        // getFAQResponse.value=ApiResponse.complete(faqDetailsList);
      } else {
        print("API failed with status: ${response.statusCode}");
        //getFAQResponse.value=ApiResponse.error("Error");
      }
    } catch (e) {
      print("Error: $e");
      getFAQResponse.value=ApiResponse.error("Error");
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> getPreSignUrl({File? selectedFile}) async {
    File? selectedFiles = selectedFile;
    String? fileNames;
    String? fileTypes;

    Map<String, String?> fileInfo = getFileInfo(selectedFiles ?? File(""));
    fileNames = fileInfo['fileName'];
    fileTypes = fileInfo['mimeType'];

    final uploadParams = {
      ApiKeys.fileName: fileNames,
      ApiKeys.fileType: fileTypes,
    };

    ResponseModel response =
    await UserRepo().uploadUserImageDocument(uploadParams);
    if (response.isSuccess) {
      await uploadFileToS3(
          file: selectedFiles ?? File(''),
          fileType: fileTypes ?? '',
          preSignedUrl: response.response?.data['uploadUrl']);
      return response.response?.data['publicUrl'];
    } else {
      commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong);
    }
    return null;
  }
  Future<void> uploadFileToS3(
      {required File file,
        required String fileType,
        required String preSignedUrl}) async {
    try {
      ResponseModel? response = await UserRepo().uploadVideoToS3(
          onProgress: (double progress) {
            // VideoUploadProgress.value = (progress * 100).toStringAsFixed(2);
          },
          file: file,
          fileType: fileType,
          preSignedUrl: preSignedUrl);
      if (response?.isSuccess ?? false) {
      } else {
        commonSnackBar(
            message: response?.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<List<Map<String, dynamic>>> getVariantImages() async {
    return await Future.wait(
      pickedQueriesImages.map((e) async {
        String? publicUrl =
        await getPreSignUrl(selectedFile: File(e));

        return {
          ApiKeys.url: publicUrl, // optional
          ApiKeys.mimeType: "image/png",
          ApiKeys.name: "Query Image",
        };
      }),
    );
  }

  Future<void> addQuery(Map<String,dynamic> params) async {
    isLoading.value = true;
    try {
      if (pickedQueriesImages.isNotEmpty) {
        final list = await getVariantImages();

        params[ApiKeys.attachments] = list;
      }
      final ResponseModel response = await UserRepo().addFQueriesHelp(reqPar: params);

      if (response.isSuccess) {
        isLoading.value = false;
        getSupportQueries();
        Get.back();
        Future.delayed(const Duration(milliseconds: 100), () {
          commonSnackBar(message: "Query submitted successfully");
        });

      } else {
        isLoading.value = false;
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } catch (e) {
      isLoading.value = false;
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> getSupportQueries() async {

    try {
      final ResponseModel response = await UserRepo().getQueriesHelp();

      if (response.isSuccess) {
        final List list =
            response.response?.data['queries'] ?? [];

        final cases = list
            .map((e) => SupportCase.fromJson(e))
            .toList();

        allList.value = cases;
        getQueryResponse.value=ApiResponse.complete(allList);
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
        getQueryResponse.value=ApiResponse.error("Error");

      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
      getQueryResponse.value=ApiResponse.error("Error");

    } finally {

    }
  }



}