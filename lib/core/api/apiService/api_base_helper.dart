import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/logger_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/environment_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/service/location_update_service.dart';
import 'package:BlueEra/features/common/feed/controller/feed_controller.dart';
import 'package:BlueEra/features/common/feed/view/home_feed_screen_new.dart';
import 'package:BlueEra/core/language_localization_service/language_controller_new.dart';
import 'package:BlueEra/core/language_localization_service/language_service_app.dart';
import 'package:BlueEra/features/personal/personal_profile/view/account_setting_screen/account_settings_screen.dart';
import 'package:BlueEra/widgets/progrss_dialog.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' as getxObj;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AuthManager {
  static bool isLoggingOut = false;

  static Future<void> handleLogout(Response<dynamic>? response) async {
    if (isLoggingOut) return;
// commonSnackBar(message: response?.data["message"]);
    isLoggingOut = true;
    // E2E: revoke device keys from server before clearing session
    if (getxObj.Get.isRegistered<ChatViewController>()) {
      await getxObj.Get.find<ChatViewController>().revokeE2EDevice();
    }

    deleteIfRegistered<ChatViewController>();
    deleteIfRegistered<FeedController>();
    deleteIfRegistered<LanguageControllerNew>();
    lastHomeFetchTime = null;
    await SharedPreferenceUtils.clearPreference();
    final LiveLocationService locationService = LiveLocationService();

    locationService.stop();
    await clearAllLocalDataOnLogout();

    // Re-init localization Hive box after logout clears disk
    await LocalizationService().init();

    getxObj.Get.offAllNamed(RouteHelper.getMobileNumberLoginRoute());
  }
}

class ApiBaseHelper {
  static int numberOfReq = 0;
  static bool showProgressDialog = true;

  static BaseOptions opts = BaseOptions(
      baseUrl: baseUrl ?? "",
      responseType: ResponseType.json,
      receiveTimeout: Duration(seconds: 60),
      headers: {
        ApiKeys.authorization: 'Bearer $authTokenGlobal',
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Device-Type': 'mobile',
        // Or 'desktop'
        'X-Device-OS': '${Platform.operatingSystem} ${deviceOsVersionGlobal}',
        // e.g., 'android 14'
        'X-Browser-Name': AppConstants.appName,
        // Or your app name
      });

  static Dio createDio() {
    return Dio(opts);
  }

  ///CREATE DIO OBJECT
  static final dio = createDio();
  static final baseAPI = addInterceptors(dio);

  ///DIO INTERCEPTOR...
  static Dio addInterceptors(Dio dio) {
    ///For Print Logs
    // if (!kReleaseMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          error: true,
          responseHeader: false,
          requestHeader: false,
        ),
      );
    // }

    ///For Show Hide Progress Dialog
    return dio
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (RequestOptions options, handler) async {
            numberOfReq++;
            if (showProgressDialog && numberOfReq > 0)
              ProgressDialog.showProgressDialog(true, apiPath: options.path);
            // // Increment the request count and show the loader
            final isFormData = options.data is FormData;

            if (kDebugMode) {
              // ====== 🌟 Beautified Request Log ======

              if (isFormData) {
                final formData = options.data as FormData;
                log("🔹 FormData Fields:");
                for (final field in formData.fields) {
                  log("    ${field.key}: ${field.value}");
                }
                log("🔹 FormData Files:");
                for (final file in formData.files) {
                  log("    ${file.key}: ${file.value.filename}");
                }
              } else if (options.data != null) {
                log("🔹 Body: ${const JsonEncoder.withIndent('  ').convert(options.data)}");
              } else {
                log("🔹 Body: null");
              }
            }
            if (authTokenGlobal != null &&
                (authTokenGlobal?.isNotEmpty ?? false)) {
              options.headers[ApiKeys.authorization] =
                  "Bearer $authTokenGlobal";

              logs("AUTH TOKEN===> ${options.headers[ApiKeys.authorization]}");
            }
            options.headers[ApiKeys.contentType] = "application/json";
            return requestInterceptor(options, handler);
          },
          onResponse: (response, handler) {
            numberOfReq--;
            if (showProgressDialog && numberOfReq == 0) {
              log('close dialog');
              ProgressDialog.showProgressDialog(false);
            }
            // ===== YOUR FIX BELOW: normalize all Map keys to String to prevent _Map<dynamic, dynamic> issues ===
            if (response.data is Map) {
              // convert keys to String here
              response.data = (response.data as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              );
            }

            // Decrement the request count and hide the loader if no pending requests
            if (response.statusCode! >= 100 && response.statusCode! <= 199) {
              Logger.printLog(
                  tag: 'WARNING CODE ${response.statusCode} : ',
                  printLog: response.data.toString(),
                  logIcon: Logger.warning);
            } else {
              logs(
                  'SUCCESS CODE ${response.statusCode} :  ${jsonEncode(response.data)}');
            }

            /// change after upgrade
            return handler.next(response);
          },
          onError: (DioException err, handler) async {
            logs("err====1  ${err.response}");
            numberOfReq--;
            if (numberOfReq == 0) {
              ProgressDialog.showProgressDialog(false);
            }

            final response = err.response;
            logs("err==== response?.statusCode ${response?.statusCode.runtimeType}");

            if (response?.statusCode == 401) {
              logs("ERROR CODE 401 ====");

              await AuthManager.handleLogout(response);
            }
            // Decrement the request count and hide the loader if no pending requests
            // if (response != null &&
            //     // status code for unauthorized usually 401
            //     response.statusCode == 401) {
            //   await SharedPreferenceUtils.clearPreference();
            //   getxObj.Get.offAllNamed(RouteHelper.getMobileNumberLoginRoute());
            // }
            return handler.next(err);
          },
        ),
      );
  }

  static dynamic requestInterceptor(
      RequestOptions options, RequestInterceptorHandler handler) async {
    return handler.next(options);
  }

  ///POST...
  Future<ResponseModel> postHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool isMultipart = false,
    bool isArrayReq = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      showProgressDialog = showProgress;
      Response response;
      if (isMultipart) {
        final formData = FormData();

        params.forEach((key, value) {
          if (key == ApiKeys.websites && value is List<String>) {
            for (final site in value) {
              formData.fields.add(MapEntry(ApiKeys.websites, site));
            }
          }
          // ✅ Add support for multiple files
          else if (value is List<MultipartFile>) {
            for (final file in value) {
              formData.files.add(MapEntry(key, file));
            }
          } else if (value is MultipartFile) {
            formData.files.add(MapEntry(key, value));
          } else {
            formData.fields.add(MapEntry(key, value.toString()));
          }
        });

        response = await baseAPI.post(
          url,
          data: formData,
          onSendProgress: onSendProgress,
          options: Options(headers: {
            "Content-Type": "multipart/form-data",
          }),
        );
      } else if (isArrayReq) {
        response = await baseAPI.post(
          url,
          data: params,
          options: Options(headers: {
            'Content-Type': 'application/json',
          }),
          onSendProgress: onSendProgress,
        );
      } else {
        response = await baseAPI.post(
          url,
          data: params,
          onSendProgress: onSendProgress,
          options: Options(headers: {
            'Content-Type': 'application/json',
          }),
        );
      }

      return handleResponse(
          response, onError ?? (error) {}, onSuccess ?? (res) {});
    } on DioException catch (e) {
      return handleError(e, onError ?? (error) {}, onSuccess ?? (res) {});
    }
  }

  ///POST...
  Future<ResponseModel> workManagerPostHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool isMultipart = false,
    bool isArrayReq = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      final authToken = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.authToken);
      BaseOptions opts = BaseOptions(
          responseType: ResponseType.json,
          sendTimeout: Duration(minutes: 2),
          receiveTimeout: Duration(minutes: 5),
          headers: {ApiKeys.authorization: 'Bearer $authToken'});
      final dio = Dio(opts);
      logs("------URL----$url");
      Response response;
      response = await dio.post(
        "${url}",
        data: params,
        onSendProgress: onSendProgress,
      );

      return handleResponse(
          response, onError ?? (error) {}, onSuccess ?? (res) {});
    } on DioException catch (e) {
      return handleError(e, onError ?? (error) {}, onSuccess ?? (res) {});
    }
  }

  ///POST...
  Future<ResponseModel> postMultiImage(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool isArrayReq = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      logs("------URL----$url");
      logs("------URL files----${params.files}");
      logs("------URL fields ----${params.fields}");

      showProgressDialog = showProgress;
      Response response;
      response = await baseAPI.post(
        url,
        data: params,
        onSendProgress: onSendProgress,
        options: Options(headers: {
          "Content-Type": "multipart/form-data",
        }),
      );

      return handleResponse(
          response, onError ?? (error) {}, onSuccess ?? (res) {});
    } on DioException catch (e) {
      logs("ERROR IN HELPER ${e}");
      return handleError(e, onError ?? (error) {}, onSuccess ?? (res) {});
    }
  }

  Future<ResponseModel> postFileDownloadHTTP(
    String url, {
    required String? containerName,
    bool showProgress = true,
    required bool? isGetReq,
    Map<String, dynamic>? reqParam,
    required String? successMessage,
    required String? fileExtensions,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      // logs("------URL----$url");
      var response;
      if (isGetReq ?? false) {
        response = await baseAPI.get(
          url,
          options: Options(
            responseType: ResponseType.bytes,
          ),
        );
      } else {
        response = await baseAPI.post(
          url,
          data: {
            ApiKeys.template: containerName,
          },
          onSendProgress: onSendProgress,
          options: Options(
            responseType: ResponseType.bytes,
          ),
        );
      }

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! <= 299) {
        Directory? directory;
        if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
        } else if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');

          final plugin = DeviceInfoPlugin();
          final android = await plugin.androidInfo;
          final androidVersion = android.version.sdkInt;
          final storageStatus = androidVersion < 33
              ? await Permission.storage.request()
              : PermissionStatus.granted;
          if (storageStatus == PermissionStatus.granted) {
            if (!(await directory.exists())) {
              await directory.create(
                  recursive: true); // Create folder if it doesn't exist
            }
          }
          if (storageStatus == PermissionStatus.denied) {
            commonSnackBar(
              message: AppStrings.storagePermissionDenied,
            );
          }
          if (storageStatus == PermissionStatus.permanentlyDenied) {
            openAppSettings();
          }
        }

        try {
          logs("fileExtensions=====$fileExtensions");
          if (directory != null) {
            String filePath =
                '${directory.path}/${DateTime.now().microsecondsSinceEpoch}.${fileExtensions}';
            logs("filePath====== ${filePath}");
            File file = File(filePath);
            // Save the file (image or document)
            await file.writeAsBytes(response.businessCategory, flush: true);
            commonSnackBar(message: successMessage ?? "Download successfully");
            logs("filePath 2222====== ${file.path}");

            // return true;
          } else {
            commonSnackBar(message: AppStrings.somethingWentWrong);
            // return false;
          }
        } catch (e) {
          logs("---Error while downloading file: $e");
          commonSnackBar(message: AppStrings.somethingWentWrong);
        }

        return handleResponse(
            response, onError ?? (error) {}, onSuccess ?? (res) {});
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        return handleResponse(
            response, onError ?? (error) {}, onSuccess ?? (res) {});
        // return false;
      }
    } on DioException catch (e) {
      logs("ERROR $e");
      return handleError(e, onError ?? (error) {}, onSuccess ?? (res) {});
    }
  }

  ///GET...
  Future<ResponseModel> getHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
  }) async {
    try {
      showProgressDialog = showProgress;

      Response response = await baseAPI.get(
        url,
        queryParameters: params,
      );

      return handleResponse(
          response, onError ?? (error) {}, onSuccess ?? (res) {});
    } on DioException catch (e) {
      return handleError(e, onError ?? (error) {}, onSuccess ?? (res) {});
    }
  }

  ///PUT
  Future<ResponseModel> putHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool isMultipart = false,
    bool isArrayReq = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      logs("------URL----$url");

      showProgressDialog = showProgress;

      Response response;

      if (isMultipart) {
        FormData formData = FormData.fromMap(params);
        logs("FORM DATA ${formData}");
        logs("FORM DATA ${formData.fields}");
        logs("FORM DATA ${formData.files}");
        response = await baseAPI.put(
          url,
          data: formData,
          onSendProgress: onSendProgress,
          options: Options(headers: {
            "Content-Type": "multipart/form-data",
          }),
        );
      } else if (isArrayReq) {
        response = await baseAPI.put(
          url,
          data: params,
          options: Options(headers: {
            'Content-Type': 'application/json', // 👈 important
          }),
          onSendProgress: onSendProgress,
        );
      } else {
        response = await baseAPI.put(
          url,
          data: params,
          onSendProgress: onSendProgress,
        );
      }

      return handleResponse(
          response, onError ?? (error) {}, onSuccess ?? (res) {});
    } on DioException catch (e) {
      return handleError(e, onError ?? (error) {}, onSuccess ?? (res) {});
    }
  }

  ///PATCH
  Future<ResponseModel> patchHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool isMultipart = false,
    bool isArrayReq = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      logs("------URL----$url");
      showProgressDialog = showProgress;
      Response response;
      if (isMultipart) {
        FormData formData = FormData.fromMap(params);
        response = await baseAPI.patch(
          url,
          data: formData,
          onSendProgress: onSendProgress,
          options: Options(headers: {
            "Content-Type": "multipart/form-data",
          }),
        );
      } else if (isArrayReq) {
        response = await baseAPI.patch(
          url,
          data: params,
          options: Options(headers: {
            'Content-Type': 'application/json',
          }),
          onSendProgress: onSendProgress,
        );
      } else {
        response = await baseAPI.patch(
          url,
          data: params,
          onSendProgress: onSendProgress,
        );
      }
      return handleResponse(
          response, onError ?? (error) {}, onSuccess ?? (res) {});
    } on DioException catch (e) {
      return handleError(e, onError ?? (error) {}, onSuccess ?? (res) {});
    }
  }

  ///DELETE ...
  Future<ResponseModel> deleteHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
  }) async {
    try {
      logs("------URL----$url");

      showProgressDialog = showProgress;
      Response response = await baseAPI.delete(
        url,
        data: params,
      );

      return handleResponse(
          response, onError ?? (error) {}, onSuccess ?? (res) {});
    } on DioException catch (e) {
      return handleError(e, onError ?? (error) {}, onSuccess ?? (res) {});
    }
  }

  /// Upload File To S3
  Future<ResponseModel?> uploadVideoToS3(
    String url, {
    required File file,
    required String fileType,
    Function(double)? onProgress,
    bool showProgress = true,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
  }) async {
    try {
      showProgressDialog = showProgress;

      final fileLength = await file.length();

      final dio = Dio(
        BaseOptions(
          // Give generous timeouts for large file uploads on slow networks
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 120), // Crucial for uploads
        ),
      );

      dio.interceptors.add(
        LogInterceptor(
          request: true,
          error: true,
          responseHeader: true,
        ),
      );

      final response = await dio.put(
        url,
        data: file.openRead(),
        options: Options(
          headers: {
            'Content-Type': fileType, // or your actual video MIME type
            'Content-Length': fileLength,
          },
          responseType: ResponseType.plain, // important for AWS S3
        ),
        onSendProgress: (int sent, int total) {
          if (onProgress != null) {
            // When streaming via file.openRead(), Dio can report total = -1
            // (unknown) or 0 on the first tick → sent/total becomes NaN or
            // Infinity and crashes LinearProgressIndicator. Fall back to the
            // known file length and clamp.
            final int effectiveTotal = total > 0 ? total : fileLength;
            final double progress =
                effectiveTotal > 0 ? (sent / effectiveTotal) : 0.0;
            onProgress(progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0);
          }
        },
      );
      print("url==== ${url}");
      print("response==== ${response}");
      return handleResponse(
          response, onError ?? (error) {}, onSuccess ?? (res) {});
    } on DioException catch (e) {
      print("❌ Error DioException uploading video: $e");

      return handleError(e, onError ?? (error) {}, onSuccess ?? (res) {});
    } catch (e) {
      print("❌ Error uploading video: $e");
      // return handleError(e, onError!, onSuccess!);
      return null;
    }
  }

  /// Upload File To S3
  Future<ResponseModel?> uploadInitGet(
    String url, {
    dynamic params,
    bool showProgress = true,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
  }) async {
    try {
      final authToken = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.authToken);
      BaseOptions opts = BaseOptions(
          responseType: ResponseType.json,
          sendTimeout: Duration(minutes: 2),
          receiveTimeout: Duration(minutes: 5),
          headers: {ApiKeys.authorization: 'Bearer $authToken'});
      final dio = Dio(opts);

      Response response = await dio.get(
        url,
        queryParameters: params,
      );

      return handleResponse(
          response, onError ?? (error) {}, onSuccess ?? (res) {});
    } on DioException catch (e) {
      return handleError(e, onError ?? (error) {}, onSuccess ?? (res) {});
    } catch (e) {
      print("❌ Error uploading video: $e");
      // return handleError(e, onError!, onSuccess!);
      return null;
    }
  }

  handleResponse(
    Response response,
    Function(DioExceptions dioExceptions) onError,
    Function(ResponseModel res) onSuccess,
  ) {
    var successModel =
        ResponseModel(statusCode: response.statusCode, response: response);
    onSuccess(successModel);
    return successModel;
  }

  static handleError(
    DioException e,
    Function(DioExceptions dioExceptions) onError,
    Function(ResponseModel res) onSuccess,
  ) {
    switch (e.type) {
      case DioExceptionType.badResponse:
        var errorModel = ResponseModel(
            statusCode: e.response!.statusCode, response: e.response);
        onSuccess(errorModel);
        return ResponseModel(
            statusCode: e.response!.statusCode, response: e.response);
      default:
        onError(DioExceptions.fromDioError(e));
        // Utils.validationCheck(message: DioExceptions.fromDioError(e).message, isError: true);
        throw DioExceptions.fromDioError(e).message!;
    }
  }
}

class DioExceptions implements Exception {
  String? message;

  DioExceptions.fromDioError(DioException? dioError) {
    logs("dioError!.type==== ${dioError!.type}");
    switch (dioError.type) {
      case DioExceptionType.cancel:
        message = "Request to API server was cancelled";
        break;
      case DioExceptionType.connectionTimeout:
        message = "Connection timeout with API server";
        break;
      case DioExceptionType.unknown:
        message = "No internet connection";
        break;
      case DioExceptionType.receiveTimeout:
        message = "Receive timeout in connection with API server";
        break;
      case DioExceptionType.badResponse:
        message = _handleResponseError(
            dioError.response!.statusCode!, dioError.response!.data);
        break;
      case DioException.sendTimeout:
        message = "Send timeout in connection with API server";
        break;
      default:
        message = "Something went wrong";
        break;
    }
  }

  String _handleResponseError(int statusCode, dynamic error) {
    switch (statusCode) {
      case 400:
        return 'Bad request';
      case 404:
        return error["message"];
      case 500:
        return 'Internal Server Error. Please try again.';
      default:
        return 'Sorry, something went wrong. Please try again.';
    }
  }
}
