import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:dio/dio.dart';



class ResumeRepo extends BaseService {
  /// GET RESUME DATA (Main API that returns all resume data)
  Future<ResponseModel> getResumeData() async {
    return await ApiBaseHelper().getHTTP(
      '$resumeUrl',
      onError: (error) => print("API error in getResumeData: $error"),
      onSuccess: (res) =>
          print('[API] Resume data received: ${res.response?.data}'),
    );
  }

  ///For Experience
  String getExperienceUrl(bool isFullTime) {
    final url = isFullTime ? addExperienceUrl : addPartExperienceUrl;
    print("[Repo][getExperienceUrl] isFullTime=$isFullTime, using URL: $url");
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

  // ///ProfilePicture
  // Future<ResponseModel> getProfilePic({
  //   required Map<String, dynamic> params,
  // }) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     "$profilePicUrl",
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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

  // ///ProfileBio
  // Future<ResponseModel> getProfileBio(
  //     {required Map<String, dynamic> params}) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     profileBioUrl,
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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

  // Future<ResponseModel> fetchUserBio(
  //     {required Map<String, dynamic> params}) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     updateBioUrl,
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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

  // Future<ResponseModel> fetchSalaryDetails(
  //     {required Map<String, dynamic> params}) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     addSalaryDetailsUrl,
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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

  // Future<ResponseModel> fetchEducationDetails(
  //     {required Map<String, dynamic> params}) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     highestQualificationUrl,
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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

  // /// GET CAREER OBJECTIVE
  // Future<ResponseModel> getCareerObjective() async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     "$getCareerObjectiveUrl",
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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

  // /// Current Job
  // Future<ResponseModel> fetchCurrentJobDetails(
  //     {required Map<String, dynamic> params}) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     currentJobUrl,
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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

  // /// GET PORTFOLIOS
  // Future<ResponseModel> fetchPortfolios(
  //     {required Map<String, dynamic> params}) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     portfoliosUrl,
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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

  /// GET SKILLS
  // Future<ResponseModel> getSkills() async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     "$getSkillsUrl",
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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
    print("Saving languages with payload: $params");

    final response = await ApiBaseHelper().postHTTP(
      "$addLanguageUrl",
      params: params,
      onError: (error) {},
      onSuccess: (res) {},
    );
    return response;
  }

  /// DELETE LANGUAGE
  // Future<ResponseModel> deleteLanguage({
  //   required Map<String, dynamic> params,
  // }) async {
  //   final response = await ApiBaseHelper().deleteHTTP(
  //     "$deleteLanguageUrl",
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }
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

  // /// GET HOBBIES
  // Future<ResponseModel> getHobbies() async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     "$getHobbiesUrl",
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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

  // /// GET ALL AWARDS
  // Future<ResponseModel> getAllAwards({
  //   required Map<String, dynamic> params,
  // }) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     getAllAwardsUrl,
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

  // /// GET AWARD BY ID
  // Future<ResponseModel> getAwardById({
  //   required String id,
  //   required Map<String, dynamic> params,
  // }) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     "$getAwardByIdUrl/$id",
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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
    }else if (removeAttachment) {
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

  /// ACHIEVEMENTS

  // Future<ResponseModel> getAllAchievements(
  //     {required Map<String, dynamic> params}) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     getAllAchievementsUrl,
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

  // Future<ResponseModel> getAchievementById({
  //   required String id,
  //   required Map<String, dynamic> params,
  // }) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     "$getAchievementByIdUrl/$id",
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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

  // GET all certifications (return raw API response)
  // Future<ResponseModel> getAllCertifications() async {
  //   final url = getAllCertificationsUrl;
  //   return await ApiBaseHelper().getHTTP(url);
  // }

// GET certification by ID
  // Future<ResponseModel> getCertificationById({
  //   required String id,
  //   required Map<String, dynamic> params,
  // }) async {
  //   return await ApiBaseHelper().getHTTP(
  //     "$getCertificationByIdUrl/$id",
  //     params: params,
  //   );
  // }

// ADD certification - multipart form
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

// UPDATE certification - multipart form
  Future<ResponseModel> updateCertification({
    required String id,
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

    // Add or remove file param
    if (photoPath != null && File(photoPath).existsSync()) {
      requestParams['certificateAttachment'] =
          await MultipartFile.fromFile(photoPath);
    } else {
      // Explicitly clear if photoPath null
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

  /// GET ALL PUBLICATIONS
  // Future<ResponseModel> getAllPublications({
  //   required Map<String, dynamic> params,
  // }) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     getAllPublicationsUrl,
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

  /// GET PUBLICATION BY ID
  // Future<ResponseModel> getPublicationById({
  //   required String id,
  //   required Map<String, dynamic> params,
  // }) async {
  //   final response = await ApiBaseHelper().getHTTP(
  //     "$getPublicationByIdUrl/$id",
  //     params: params,
  //     onError: (error) {},
  //     onSuccess: (res) {},
  //   );
  //   return response;
  // }

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

    print("[Repo][POST] URL: $url");
    print("[Repo][POST] Params: $params");
    final response = await ApiBaseHelper().postHTTP(
      url,
      params: params,
      onError: (error) {
        print("[Repo][POST][Error] $error");
      },
      onSuccess: (res) {
        print("[Repo][POST][Success] $res");
      },
    );
    print("[Repo][POST] Response isSuccess: ${response.isSuccess}");
    return response;
  }

  // Future<ResponseModel> fetchExperience({required bool isFullTime}) async {
  //   final url = getExperienceUrl(isFullTime);
  //   print("[Repo][GET] URL: $url");
  //   print("[Repo][fetchExperience] URL used: $url (isFullTime: $isFullTime)");

  //   final response = await ApiBaseHelper().getHTTP(
  //     url,
  //     onError: (error) {
  //       print("[Repo][GET][Error] $error");
  //     },
  //     onSuccess: (res) {
  //       print("[Repo][GET][Success] response data: $res");
  //     },
  //   );
  //   print("[Repo][GET] Response isSuccess: ${response.isSuccess}");
  //   print("[Repo][GET] Response data: ${response.response?.data}");
  //   return response;
  // }

  Future<ResponseModel> updateExperience({
    required String id,
    required Map<String, dynamic> params,
    required bool isFullTime,
  }) async {
    final url = "${getExperienceUrl(isFullTime)}/$id";
    print("[Repo][PUT] URL: $url");
    print("[Repo][PUT] Params: $params");
    final response = await ApiBaseHelper().putHTTP(
      url,
      params: params,
      onError: (error) {
        print("[Repo][PUT][Error] $error");
      },
      onSuccess: (res) {
        print("[Repo][PUT][Success] $res");
      },
    );
    print("[Repo][PUT] Response isSuccess: ${response.isSuccess}");
    return response;
  }

  Future<ResponseModel> deleteExperience({
    required String id,
    required bool isFullTime,
  }) async {
    final url = "${getExperienceUrl(isFullTime)}/$id";
    print("[Repo][DELETE] URL: $url");
    final response = await ApiBaseHelper().deleteHTTP(
      url,
      onError: (error) {
        print("[Repo][DELETE][Error] $error");
      },
      onSuccess: (res) {
        print("[Repo][DELETE][Success] $res");
      },
    );
    print("[Repo][DELETE] Response isSuccess: ${response.isSuccess}");
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

  ///NGO/PATENT

  /// Fetch all
  // Future<ResponseModel> fetchAllEntities({required bool isPatent}) async {
  //   final url = getEntityUrl(isPatent);
  //   final response = await ApiBaseHelper().getHTTP(url);
  //   return response;
  // }

  /// Fetch by id
  // Future<ResponseModel> fetchEntityById(
  //     {required bool isPatent, required String id}) async {
  //   final url = getEntityUrl(isPatent, id: id);
  //   final response = await ApiBaseHelper().getHTTP(url);
  //   return response;
  // }

  /// Add
  Future<ResponseModel> addEntity({
    required bool isPatent,
    required Map<String, dynamic> params,
    String? imagePath,
  }) async {
    if (imagePath != null && File(imagePath).existsSync()) {
      params[isPatent ? 'patentCertification' : 'attachment'] =
          await MultipartFile.fromFile(imagePath);
    }
    final url = getEntityUrl(isPatent);
    final response = await ApiBaseHelper().postHTTP(
      url,
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

  /// Add Additional info
  /// GET all
  // Future<ResponseModel> fetchAllAdditionalInfo() async {
  //   final url = additionalInfoUrl();
  //   return await ApiBaseHelper().getHTTP(url);
  // }

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

  // Future<ResponseModel> updateAdditionalInfo(String id,
  //     Map<String, dynamic> inputParams, // includes title, info, additionalDesc
  //     {String? photoPath,
  //     Map<String, dynamic>? date}) async {
  //   final url = additionalInfoUrl(id: id);

  //   final Map<String, dynamic> requestParams = Map.from(inputParams);

  //   // Date fields or empty strings to clear
  //   if (date != null &&
  //       date['date'] != null &&
  //       date['month'] != null &&
  //       date['year'] != null) {
  //     requestParams['infoDate[date]'] = date['date'].toString();
  //     requestParams['infoDate[month]'] = date['month'].toString();
  //     requestParams['infoDate[year]'] = date['year'].toString();
  //   } else {
  //     requestParams['infoDate[date]'] = '';
  //     requestParams['infoDate[month]'] = '';
  //     requestParams['infoDate[year]'] = '';
  //   }

  //   // Photo field: add MultipartFile if photoPath exists, else set empty string to clear
  //   if (photoPath != null && File(photoPath).existsSync()) {
  //     requestParams['photoURL'] = await MultipartFile.fromFile(photoPath);
  //   } else {
  //     requestParams['photoURL'] = '';
  //   }

  //   // AdditionalDesc: you already have in inputParams, ensure empty string to clear

  //   return await ApiBaseHelper().putHTTP(
  //     url,
  //     params: requestParams,
  //     isMultipart: true,
  //   );
  // }
  Future<ResponseModel> updateAdditionalInfo(
    String id,
    Map<String, dynamic> inputParams, {
    String? photoPath,
    Map<String, dynamic>? date,
  }) async {
    final url = additionalInfoUrl(id: id);

    // Clone inputParams to avoid side effects
    final Map<String, dynamic> requestParams = Map.from(inputParams);

    // Handle date fields: send string or empty to clear
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

    // Photo handling: include MultipartFile if photoPath provided, else signal removal with a boolean flag
    if (photoPath != null &&
        photoPath.isNotEmpty &&
        File(photoPath).existsSync()) {
      // Remove previous removePhoto flag if any
      requestParams.remove('removePhoto');
      requestParams['photoURL'] = await MultipartFile.fromFile(photoPath);
    } else {
      // Indicate photo removal explicitly, remove photoURL field from multipart parts
      requestParams['removePhoto'] =
          true; // boolean true, not string 'true' (prefer boolean)
      requestParams.remove('photoURL');
    }

    // Ensure 'additionalDesc' key is always present (with empty string "" or null if clearing)
    if (!requestParams.containsKey('additionalDesc')) {
      requestParams['additionalDesc'] = '';
    }

    // Debug prints to verify entire request payload
    print("== UPDATE PARAMS SUBMITTED TO BACKEND ==");
    requestParams.forEach((key, value) {
      print("$key: $value [${value.runtimeType}]");
    });
    print("isMultipart: true");

    // Send request as multipart
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

  // Future<ResponseModel> downloadResumeTemplate(String templateName) async {
  //   return await ApiBaseHelper().postFileDownloadHTTP(
  //     resumeTemplatesDownload,
  //     containerName: templateName,
  //     isGetReq: false,
  //     successMessage: "Resume Download successfully",
  //     fileExtensions: 'pdf',
  //   );
  // }
  // Future<void> downloadResumeTemplate(String url, String fileBaseName) async {
  //   // if (Platform.isAndroid) {
  //   //   final status = await Permission.storage.request();
  //   //   if (!status.isGranted) {
  //   //     commonSnackBar(message: 'Storage permission denied');
  //   //     return;
  //   //   }
  //   // }
  //   final response = await http.get(Uri.parse(url));
  //   if (response.statusCode == 200) {
  //     String extension = url.split('.').last;
  //     if (extension.length > 5 || extension.contains('/')) extension = 'pdf';
  //     final fileName = '$fileBaseName.$extension';
  //     Directory? dir;
  //     if (Platform.isAndroid) {
  //       dir = await getExternalStorageDirectory();
  //     } else if (Platform.isIOS) {
  //       dir = await getApplicationDocumentsDirectory();
  //     }
  //     if (dir == null) {
  //       commonSnackBar(message: 'Cannot access local storage');
  //       return;
  //     }
  //     final file = File('${dir.path}/$fileName');
  //     await file.writeAsBytes(response.bodyBytes);

  //     commonSnackBar(message: 'Template downloaded: ${file.path}');
  //     print("Template downloaded⭐⭐⭐: ${file.path}");
  //   } else {
  //     commonSnackBar(message: 'Download failed');
  //   }
  // }
 
  Future<void> downloadResumeTemplate( String fileBaseName) async {
    await ApiBaseHelper().postFileDownloadHTTP(
      resumeTemplatesDownload,
      isGetReq: false,

      successMessage: "Download successfully",
      fileExtensions: "pdf",
      containerName: fileBaseName,
    );
    // final response = await http.get(Uri.parse(url));
    // if (response.statusCode == 200) {
    //   String extension = url.split('.').last;
    //   if (extension.length > 5 || extension.contains('/')) extension = 'pdf';
    //   final fileName = '$fileBaseName.$extension';
    //
    //   Directory? dir;
    //   if (Platform.isAndroid) {
    //     dir = await getExternalStorageDirectory();
    //   } else if (Platform.isIOS) {
    //     dir = await getApplicationDocumentsDirectory();
    //   }
    //   if (dir == null) {
    //     print('Cannot access local storage');
    //     return;
    //   }
    //   final file = File('${dir.path}/$fileName');
    //   await file.writeAsBytes(response.bodyBytes);
    //
    //   commonSnackBar(message: 'Template saved in: ${file.path}');
    //   print("Template downloaded: ${file.path}");
    //
    //   // Optionally, let the user open/share the file
    //   await OpenFile.open(file.path);
    // } else {
    //   print('Download failed');
    //   commonSnackBar(message: 'Download failed');
    // }
  }

// ///IMAGE DOWNLOAD
// Future downloadImageRepo({
//   required String? fileName,
//   required String? containerNameData,
//   BuildContext? context,
//   String? vehicleId,
// }) async {
//   await ApiBaseHelper().postFileDownloadHTTP(
//     documentDownload,fileName: fileName, containerName: containerNameData, vehicleId: vehicleId,   onError: (error) {},
//     onSuccess: (data) {},);
//   // return response;
// }
}
