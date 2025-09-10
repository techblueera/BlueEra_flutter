import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/photo_post_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/features/common/post/controller/photo_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' as GET;

class PostRepo extends BaseService {
  ///ADD POST MSG/PHOTO/QA...
  Future<ResponseModel> addPostRepo(
      {required Map<String, dynamic>? bodyReq,
      required bool? isMultiPartPost}) async {
    final response = await ApiBaseHelper().postHTTP(addPost,
        params: bodyReq,
        onError: (error) {},
        onSuccess: (data) {},
        isMultipart: isMultiPartPost ?? true);

    return response;
  }

  Future<ResponseModel> updatePostRepo(
      {required Map<String, dynamic>? bodyReq,
      required bool? isMultiPartPost,
      required String? postId}) async {
    final response = await ApiBaseHelper().putHTTP("${updatePost}$postId",
        params: bodyReq,
        onError: (error) {},
        onSuccess: (data) {},
        isMultipart: isMultiPartPost ?? true);

    return response;
  }

  Future<ResponseModel> createPost(
    PhotoPost photoPost,
    List<File> mediaFiles,
    double? latitude,
    double? longitude,
    PostVia? postVia,
    void Function(double progress) onProgress,
    String natureOfPost,
    String visibilityDuration
  ) async {
    try {
      log('natureOfPost-- $natureOfPost');
      FormData formData = FormData();

      String? tagUserIds = GET.Get.find<TagUserController>()
          .selectedUsers
          .map((user) => user.id.toString())
          .join(',');

      // Add media files
      for (int i = 0; i < mediaFiles.length; i++) {
        String fileName = mediaFiles[i].path.split('/').last;
        formData.files.add(
          MapEntry(
            ApiKeys.media,
            await MultipartFile.fromFile(
              mediaFiles[i].path,
              filename: fileName,
            ),
          ),
        );
      }

      // Add other fields
      if (photoPost.description.isNotEmpty)
        formData.fields.add(MapEntry(ApiKeys.sub_title, photoPost.description));
      if (tagUserIds.isNotEmpty)
        formData.fields.add(MapEntry(ApiKeys.tagged_users, tagUserIds));
      formData.fields.add(MapEntry(
          ApiKeys.type,
          AppConstants
              .PHOTO_POST)); // Assuming 'photo' is the type for photo posts
      formData.fields.add(MapEntry(ApiKeys.postVia, postVia!.name));
      if (photoPost.natureOfPost.isNotEmpty)
        formData.fields
            .add(MapEntry(ApiKeys.nature_of_post, photoPost.natureOfPost));
      // final position = await getCurrentLocation();

      // Add location if available
      if (GET.Get.find<PhotoPostController>().latitude.value != null &&
          GET.Get.find<PhotoPostController>().longitude.value != null) {
        formData.fields.add(MapEntry(ApiKeys.latitude,
            GET.Get.find<PhotoPostController>().latitude.toString()));
        formData.fields.add(MapEntry(ApiKeys.longitude,
            GET.Get.find<PhotoPostController>().longitude.toString()));
      }
      if (natureOfPost.isNotEmpty)
      formData.fields
          .add(MapEntry(ApiKeys.nature_of_post, natureOfPost));
        formData.fields
            .add(MapEntry(ApiKeys.visibilityDuration, visibilityDuration));
      final response = await ApiBaseHelper().postMultiImage(
        addPost,
        params: formData,
        isArrayReq: true,
        isMultipart: true,
        showProgress: false,
        onSendProgress: (sent, total) {
          double progress = sent / total;
          onProgress(progress);
        },
      );
      return response;
    } catch (e) {
      logs("ERROR ${e.toString()}");
      rethrow;
    }
  }

  Future<ResponseModel> postByIDApi({required String id}) async {
    var response = await ApiBaseHelper().getHTTP(
      postByID + id,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }
}
