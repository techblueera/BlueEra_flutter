import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:dio/dio.dart';

class ResumeRepo extends BaseService {
  /// GET RESUME DATA (Main API that returns all resume data)
  Future<ResponseModel> getResumeData() async {
    return await ApiBaseHelper().getHTTP(
      '$resumeUrl',
    );
  }

  ///For Experience
  String getExperienceUrl(bool isFullTime) {
    final url = isFullTime ? addExperienceUrl : addPartExperienceUrl;
    return url;
  }

  /// Add patent/Add NGO
  String getEntityUrl(bool isPatent, {String? id}) {
    String baseUrl = isPatent ? patentsBaseUrl : ngoBaseUrl;
    return id != null ? "$baseUrl/$id" : baseUrl;
  }

  /// Add Additional Info
  String additionalInfoUrl({String? id}) =>
      id != null ? "$additionalInfoBaseUrl/$id" : additionalInfoBaseUrl;

  Future<ResponseModel> editProfilePicWithFile(File imageFile) async {
    final params = {
      'profilePicture': await MultipartFile.fromFile(imageFile.path),
    };
    final response = await ApiBaseHelper().putHTTP(
      profilePicUrl,
      params: params,
      isMultipart: true,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> updateProfile(Map<String, dynamic> params) async {
    final String url = profileBioUrl;

    final response = await ApiBaseHelper().putHTTP(
      url,
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// USER BIO

  Future<ResponseModel> addBio({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      "$updateBioUrl",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> updateBio({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      "$updateBioUrl",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> deleteBio() async {
    final response = await ApiBaseHelper().deleteHTTP(
      updateBioUrl,
      params: {},
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// ADD SALARY
  Future<ResponseModel> addSalaryDetails({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      "$addSalaryDetailsUrl",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> updateSalary({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      addSalaryDetailsUrl,
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> deleteSalary() async {
    final response = await ApiBaseHelper().putHTTP(
      addSalaryDetailsUrl,
      params: {
        "grossSalary": 0,
        "monthlyDeduction": 0,
        "monthlyEarningViaPartTime": 0,
        "monthlyEarningViaFreelancing": 0,
        "monthlyTotalEarning": 0,
        "annualPackage": 0,
      },
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// highest qualification
  Future<ResponseModel> addEducation({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      "$highestQualificationUrl",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> updateEducation({
    required String id,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      "$highestQualificationUrl/$id",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> deleteEducation({required String id}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$highestQualificationUrl/$id",
      params: {},
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// add career objective
  Future<ResponseModel> addCareerObjective({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      "$addCareerObjectiveUrl",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// UPDATE CAREER OBJECTIVE
  Future<ResponseModel> updateCareerObjective({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      "$updateCareerObjectiveUrl",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// DELETE CAREER OBJECTIVE
  Future<ResponseModel> deleteCareerObjective() async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$deleteCareerObjectiveUrl",
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> saveCurrentJob(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().putHTTP(
      currentJobUrl,
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> deleteCurrentJob() async {
    final response = await ApiBaseHelper().deleteHTTP(
      currentJobUrl,
      params: {},
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// ADD PORTFOLIO
  Future<ResponseModel> addPortfolio({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      portfoliosUrl,
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// DELETE PORTFOLIO LINK
  Future<ResponseModel> deletePortfolio({
    required String portfolioLink,
  }) async {
    return await ApiBaseHelper().deleteHTTP(
      portfoliosUrl,
      params: {'portfolio': portfolioLink},
    );
  }

  /// ADD SKILLS
  Future<ResponseModel> addSkills({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      "$addSkillsUrl",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// DELETE SKILLS
  Future<ResponseModel> deleteSkills({required String skill}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$deleteSkillsUrl",
      params: {
        "skill": skill,
      },
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// GET LANGUAGES
  Future<ResponseModel> getLanguages() async {
    final response = await ApiBaseHelper().getHTTP(
      "$getLanguageUrl",
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// ADD LANGUAGES
  Future<ResponseModel> addLanguages({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      "$addLanguageUrl",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// DELETE LANGUAGE
  Future<ResponseModel> deleteLanguage({
    required String category,
    required String language,
  }) async {
    final url = "$deleteLanguageUrl/$category/$language";
    final response = await ApiBaseHelper().deleteHTTP(
      url,
      // No params in body or query as these are path params
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// POST HOBBIES
  Future<ResponseModel> postHobbies({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      "$addHobbiesUrl",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// DELETE HOBBY
  Future<ResponseModel> deleteHobby({
    required String id,
  }) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$deleteHobbiesUrl/$id",
      params: {},
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// ADD AWARD (Multipart Form Data)
  Future<ResponseModel> addAward({
    required String title,
    required String issuedBy,
    required int date,
    required int month,
    required int year,
    required String description,
    File? attachment,
  }) async {
    final params = <String, dynamic>{
      'title': title,
      'issuedBy': issuedBy,
      'issuedDate[date]': date,
      'issuedDate[month]': month,
      'issuedDate[year]': year,
      'description': description,
    };

    if (attachment != null) {
      params['attachment'] = await MultipartFile.fromFile(attachment.path);
    }

    final response = await ApiBaseHelper().postHTTP(
      addAwardUrl,
      params: params,
      isMultipart: true,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// UPDATE AWARD (Multipart Form Data)
  Future<ResponseModel> updateAward({
    required String id,
    required String title,
    required String issuedBy,
    required int date,
    required int month,
    required int year,
    required String description,
    File? attachment,
    bool removeAttachment = false,
  }) async {
    final params = <String, dynamic>{
      'title': title,
      'issuedBy': issuedBy,
      'issuedDate[date]': date,
      'issuedDate[month]': month,
      'issuedDate[year]': year,
      'description': description,
    };

    if (attachment != null) {
      params['attachment'] = await MultipartFile.fromFile(attachment.path);
    } else if (removeAttachment) {
      params['attachment'] = '';
    }

    final response = await ApiBaseHelper().putHTTP(
      "$updateAwardUr/$id",
      params: params,
      isMultipart: true,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// DELETE AWARD
  Future<ResponseModel> deleteAward({required String id}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$deleteAwardUrl/$id",
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> addAchievement({
    required String title,
    required String description,
    required int date,
    required int month,
    required int year,
    File? attachment,
  }) async {
    final params = {
      'title': title,
      'description': description,
      'achieveDate[date]': date,
      'achieveDate[month]': month,
      'achieveDate[year]': year,
    };

    if (attachment != null) {
      params['attachment'] = await MultipartFile.fromFile(attachment.path);
    }

    final response = await ApiBaseHelper().postHTTP(
      "$addAchievementUrl",
      params: params,
      isMultipart: true,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> updateAchievement({
    required String id,
    required String title,
    required String description,
    required int date,
    required int month,
    required int year,
    File? attachment,
  }) async {
    final params = {
      'title': title,
      'description': description,
      'achieveDate[date]': date,
      'achieveDate[month]': month,
      'achieveDate[year]': year,
    };

    if (attachment != null) {
      params['attachment'] = await MultipartFile.fromFile(attachment.path);
    }

    final response = await ApiBaseHelper().putHTTP(
      "$updateAchievementUrl/$id",
      params: params,
      isMultipart: true,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> deleteAchievement({required String id}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$deleteAchievementUrl/$id",
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> addCertification({
    required Map<String, dynamic> params,
    String? photoPath,
  }) async {
    final Map<String, dynamic> requestParams = Map.from(params);

    // Flatten certificateDate if provided
    if (params['certificateDate'] != null) {
      final dateMap = params['certificateDate'] as Map<String, dynamic>;
      requestParams['certificateDate[date]'] = dateMap['date'].toString();
      requestParams['certificateDate[month]'] = dateMap['month'].toString();
      requestParams['certificateDate[year]'] = dateMap['year'].toString();
      requestParams.remove('certificateDate');
    }

    // Add file if exists
    if (photoPath != null && File(photoPath).existsSync()) {
      requestParams['certificateAttachment'] =
          await MultipartFile.fromFile(photoPath);
    }

    return await ApiBaseHelper().postHTTP(
      addCertificationUrl,
      params: requestParams,
      isMultipart: photoPath != null,
    );
  }

  Future<ResponseModel> updateCertification({
    required String id,
    required Map<String, dynamic> params,
    String? photoPath,
  }) async {
    final Map<String, dynamic> requestParams = Map.from(params);

    if (params['certificateDate'] != null) {
      final dateMap = params['certificateDate'] as Map<String, dynamic>;
      requestParams['certificateDate[date]'] = dateMap['date'].toString();
      requestParams['certificateDate[month]'] = dateMap['month'].toString();
      requestParams['certificateDate[year]'] = dateMap['year'].toString();
      requestParams.remove('certificateDate');
    }

    // Add or remove file param
    if (photoPath != null && File(photoPath).existsSync()) {
      requestParams['certificateAttachment'] =
          await MultipartFile.fromFile(photoPath);
    } else {
      requestParams['certificateAttachment'] = '';
    }

    return await ApiBaseHelper().putHTTP(
      "$updateCertificationUrl/$id",
      params: requestParams,
      isMultipart: true,
    );
  }

// DELETE certification
  Future<ResponseModel> deleteCertification({required String id}) async {
    return await ApiBaseHelper().deleteHTTP("$deleteCertificationUrl/$id");
  }

  /// ADD PUBLICATION
  Future<ResponseModel> addPublication({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().postHTTP(
      addPublicationUrl,
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// UPDATE PUBLICATION
  Future<ResponseModel> updatePublication({
    required String id,
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      "$updatePublicationUrl/$id",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// DELETE PUBLICATION
  Future<ResponseModel> deletePublication({required String id}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$deletePublicationUrl/$id",
      params: {},
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  ///Experiece Section
  Future<ResponseModel> addExperience({
    required Map<String, dynamic> params,
    required bool isFullTime,
  }) async {
    final url = getExperienceUrl(isFullTime);

    final response = await ApiBaseHelper().postHTTP(
      url,
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> updateExperience({
    required String id,
    required Map<String, dynamic> params,
    required bool isFullTime,
  }) async {
    final url = "${getExperienceUrl(isFullTime)}/$id";
    final response = await ApiBaseHelper().putHTTP(
      url,
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> deleteExperience({
    required String id,
    required bool isFullTime,
  }) async {
    final url = "${getExperienceUrl(isFullTime)}/$id";
    final response = await ApiBaseHelper().deleteHTTP(
      url,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> updateUser({
    required Map<String, dynamic> params,
  }) async {
    final response = await ApiBaseHelper().putHTTP(
      updateUserProfile,
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  Future<ResponseModel> deleteProject({required String id}) async {
    final response = await ApiBaseHelper().deleteHTTP(
      "$updateUserProfile/projects/$id",
      params: {},
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// Add
  Future<ResponseModel> addEntity({
    required bool isPatent,
    required Map<String, dynamic> params,
    String? imagePath,
  }) async {
    if (imagePath != null && File(imagePath).existsSync()) {
      var data=await MultipartFile.fromFile(imagePath);
      logs("RUN TIME TYPE ${data.runtimeType}");


      params[isPatent ? 'patentCertification' : 'attachment'] =
          data;

    }
    final url = getEntityUrl(isPatent);
    final response = await ApiBaseHelper().postHTTP(
      url,
      params: params,
      isMultipart: true,
    );
    return response;
  }

  /// Add
  Future<ResponseModel> addEntity1({
    required Map<String, dynamic> params,
    String? imagePath,
  }) async {
    try {
      if (imagePath != null && File(imagePath).existsSync()) {
        var data=await MultipartFile.fromFile(imagePath);
        params['projectImage'] =data;
      }
    } on Exception catch (e) {
      logs("ERRO IMG ===${e}");
      // TODO
    }
    final response = await ApiBaseHelper().postHTTP(
      resumeProjects,
      params: params,
      isMultipart: true,
    );
    return response;
  }

  /// Update

  Future<ResponseModel> updateEntity({
    required bool isPatent,
    required String id,
    required Map<String, dynamic> params,
    String? imagePath,
  }) async {
    if (imagePath != null && File(imagePath).existsSync()) {
      params[isPatent ? 'patentCertification' : 'attachment'] =
          await MultipartFile.fromFile(imagePath);
    }
    final url = getEntityUrl(isPatent, id: id);
    final response = await ApiBaseHelper().putHTTP(
      url,
      params: params,
      isMultipart: true,
    );
    return response;
  }

  /// Delete
  Future<ResponseModel> deleteEntity({
    required bool isPatent,
    required String id,
  }) async {
    final url = getEntityUrl(isPatent, id: id);
    final response = await ApiBaseHelper().deleteHTTP(url);
    return response;
  }

  /// POST (add)
  Future<ResponseModel> addAdditionalInfo(
    Map<String, dynamic> params, {
    String? photoPath,
    Map<String, dynamic>? date,
  }) async {
    final Map<String, dynamic> requestParams = Map.from(params);

    if (date != null &&
        date['date'] != null &&
        date['month'] != null &&
        date['year'] != null) {
      requestParams['infoDate[date]'] = date['date'].toString();
      requestParams['infoDate[month]'] = date['month'].toString();
      requestParams['infoDate[year]'] = date['year'].toString();
    }

    requestParams.remove('infoDate');

    if (photoPath != null && File(photoPath).existsSync()) {
      requestParams['photoURL'] = await MultipartFile.fromFile(photoPath);
    }

    final url = additionalInfoUrl();
    return await ApiBaseHelper().postHTTP(
      url,
      params: requestParams,
      isMultipart: photoPath != null,
    );
  }

  Future<ResponseModel> updateAdditionalInfo(
    String id,
    Map<String, dynamic> inputParams, {
    String? photoPath,
    Map<String, dynamic>? date,
  }) async {
    final url = additionalInfoUrl(id: id);
    final Map<String, dynamic> requestParams = Map.from(inputParams);
    if (date != null &&
        date['date'] != null &&
        date['month'] != null &&
        date['year'] != null) {
      requestParams['infoDate[date]'] = date['date'].toString();
      requestParams['infoDate[month]'] = date['month'].toString();
      requestParams['infoDate[year]'] = date['year'].toString();
    } else {
      requestParams['infoDate[date]'] = '';
      requestParams['infoDate[month]'] = '';
      requestParams['infoDate[year]'] = '';
    }

    if (photoPath != null &&
        photoPath.isNotEmpty &&
        File(photoPath).existsSync()) {
      requestParams.remove('removePhoto');
      requestParams['photoURL'] = await MultipartFile.fromFile(photoPath);
    } else {
      requestParams['removePhoto'] =
          true; // boolean true, not string 'true' (prefer boolean)
      requestParams.remove('photoURL');
    }
    if (!requestParams.containsKey('additionalDesc')) {
      requestParams['additionalDesc'] = '';
    }
    return await ApiBaseHelper().putHTTP(
      url,
      params: requestParams,
      isMultipart: true,
    );
  }

  /// DELETE
  Future<ResponseModel> deleteAdditionalInfo(String id) async {
    final url = additionalInfoUrl(id: id);
    return await ApiBaseHelper().deleteHTTP(url);
  }

  Future<ResponseModel> getResumeTemplates() async {
    return await ApiBaseHelper().getHTTP(
      resumesTemplates,
    );
  }

  Future<void> downloadResumeTemplate(String fileBaseName) async {
    await ApiBaseHelper().postFileDownloadHTTP(
      resumeTemplatesDownload,
      isGetReq: false,
      successMessage: "Download successfully",
      fileExtensions: "pdf",
      containerName: fileBaseName,
    );
  }

  /// Add
  Future<ResponseModel> addJobPortfolioResume({
    required Map<String, dynamic> params,
    String? imagePath,
  }) async {
    if (imagePath != null && File(imagePath).existsSync()) {
      params['patentCertification'] = await MultipartFile.fromFile(imagePath);
    }
    // final formData = FormData.fromMap(params);

    // if (imagePath != null && File(imagePath).existsSync()) {
    //   formData.files.add(
    //     MapEntry(
    //       'projectImages',
    //       await MultipartFile.fromFile(imagePath),
    //     ),
    //   );
    // }
    final response = await ApiBaseHelper().postHTTP(
      resumeProjects,
      params: params,
      isMultipart: true,
    );
    return response;
  }

  /// Update
  Future<ResponseModel> updateJobPortfolioResume({
    required Map<String, dynamic> params,
    String? imagePath,
    String? projectID,
  }) async {
    if (imagePath != null && File(imagePath).existsSync()) {
      params['projectImage'] = await MultipartFile.fromFile(imagePath);
    }

    final response = await ApiBaseHelper().putHTTP(
      "${resumeProjects}/$projectID",
      params: params,
      isMultipart: imagePath?.isNotEmpty ?? false,
    );
    return response;
  }

  /// DELETE
  Future<ResponseModel> deleteJobPortfolioResume(String projectID) async {
    return await ApiBaseHelper().deleteHTTP(
      "${resumeProjects}/$projectID",
    );
  }
}
