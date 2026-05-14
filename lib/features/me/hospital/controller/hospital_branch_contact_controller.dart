import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/school_contact_us_res_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/me/hospital/repo/hospital_contact_us_repo.dart';
import 'package:get/get.dart';

class HospitalBranchContactController extends GetxController {
  HospitalContactUsRepo hospitalContactUsRepo = HospitalContactUsRepo();

  // Validation regexes — shared by every validate* method below.
  static final RegExp _nameRegex = RegExp(r'^[a-zA-Z0-9\s\.\-]{3,50}$');
  static final RegExp _gmailRegex = RegExp(r'^[a-zA-Z0-9][\w\-\.]*@gmail\.com$');
  static final RegExp _websiteRegex =
      RegExp(r'^https?://[\w\-]+(\.[\w\-]+)+.*$', caseSensitive: false);
  // Indian mobile: starts with 6-9, exactly 10 digits.
  static final RegExp _phoneRegex = RegExp(r'^[6-9][0-9]{9}$');

  Rx<ApiResponse> updateSchoolContactInfoResponse =
      ApiResponse.initial('Initial').obs;
  Rx<ApiResponse> getSchoolContactUsResponse =
      ApiResponse.initial('Initial').obs;

  // Loading state for the submit button
  var isLoading = false.obs;

  // Validation state
  var isFormValid = false.obs;

  // Values to store from location picker
  double? selectedLat;
  double? selectedLng;

  // Per-field error messages
  var branchNameError = ''.obs;
  var websiteError = ''.obs;
  var addressError = ''.obs;
  var departmentError = ''.obs;
  var emailError = ''.obs;
  var phoneError = ''.obs;

  RxList<SchoolContactUsData>? schoolContactUsData =
      <SchoolContactUsData>[].obs;

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Returns `''` if `value` passes, otherwise the appropriate error message.
  /// Pass [required] = false to allow empty input (used for optional website).
  String _validate(
    String value, {
    required String requiredMsg,
    required RegExp pattern,
    required String invalidMsg,
    bool required = true,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return required ? requiredMsg : '';
    return pattern.hasMatch(trimmed) ? '' : invalidMsg;
  }

  void validateForm({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
  }) {
    branchNameError.value = _validate(
      branchName,
      requiredMsg: 'Branch name is required',
      pattern: _nameRegex,
      invalidMsg:
          'Branch name must be 3-50 characters (letters, numbers, spaces)',
    );

    websiteError.value = _validate(
      website,
      requiredMsg: '', // optional field
      pattern: _websiteRegex,
      invalidMsg: 'Please enter a valid website URL (e.g. https://example.com)',
      required: false,
    );

    addressError.value =
        address.trim().isEmpty ? 'Location is required' : '';

    departmentError.value = _validate(
      department,
      requiredMsg: 'Department name is required',
      pattern: _nameRegex,
      invalidMsg:
          'Department must be 3-50 characters (letters, numbers, spaces)',
    );

    emailError.value = _validate(
      email,
      requiredMsg: 'Email is required',
      pattern: _gmailRegex,
      invalidMsg: 'Please enter a valid Gmail address (e.g. name@gmail.com)',
    );

    phoneError.value = _validate(
      phone,
      requiredMsg: 'Phone number is required',
      pattern: _phoneRegex,
      invalidMsg:
          'Please enter a valid 10-digit mobile number (starts with 6-9)',
    );

    isFormValid.value = _orderedErrors.every((e) => e.value.isEmpty);
  }

  /// Ordered list of error Rxs — drives both [isFormValid] and [getFirstError]
  /// so the displayed error always matches form-field order.
  List<RxString> get _orderedErrors => [
        branchNameError,
        websiteError,
        addressError,
        departmentError,
        emailError,
        phoneError,
      ];

  /// Returns the first validation error message, or null if all valid.
  String? getFirstError() {
    for (final e in _orderedErrors) {
      if (e.value.isNotEmpty) return e.value;
    }
    return null;
  }

  void departmentValidateForm({
    required String departmentRole,
    required String departmentEmailAddress,
    required String departmentPhoneNo,
  }) {
    isFormValid.value = _nameRegex.hasMatch(departmentRole.trim()) &&
        _phoneRegex.hasMatch(departmentPhoneNo.trim()) &&
        _gmailRegex.hasMatch(departmentEmailAddress.trim());
  }

  /// Only Branch Validation — used by edit-branch screen which has no
  /// department fields.
  void branchValidateForm({
    required String branchName,
    required String branchWebsiteUrl,
    required String branchLocation,
  }) {
    isFormValid.value = branchName.isNotEmpty &&
        branchWebsiteUrl.isNotEmpty &&
        branchLocation.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // API helpers
  // ---------------------------------------------------------------------------

  /// Wraps the common pattern: call repo, on success pop + show server message
  /// (or fallback), then refresh; on failure or exception show a generic error.
  Future<void> _runApi({
    required Future<ResponseModel> Function() call,
    String fallbackSuccessMsg = AppStrings.successful,
    bool popOnSuccess = true,
    bool refreshOnSuccess = true,
    void Function(ResponseModel response)? onSuccess,
  }) async {
    try {
      final response = await call();
      if (response.isSuccess) {
        if (popOnSuccess) Get.back();
        commonSnackBar(
          message:
              response.response?.data['message'] ?? fallbackSuccessMsg,
        );
        onSuccess?.call(response);
        if (refreshOnSuccess) await getBranchDetailsController();
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR $e");
    }
  }

  // ---------------------------------------------------------------------------
  // API calls
  // ---------------------------------------------------------------------------

  /// Create a new branch (with one initial department).
  Future<void> submitBranchDetails({
    required String branchName,
    required String website,
    required String address,
    required String department,
    required String email,
    required String phone,
  }) async {
    if (selectedLat == null || selectedLng == null) {
      commonSnackBar(message: AppStrings.hospitalCtrlSelectValidLocation.tr);
      return;
    }

    final body = <String, dynamic>{
      "hospitalId": hospitalIDGlobal,
      "branch": {
        "name": branchName,
        "website": website,
        "location": {
          "name": address,
          "type": "Point",
          // GeoJSON is [lng, lat].
          "coordinates": [selectedLng, selectedLat],
        },
      },
      "departments": [
        {
          "department": department,
          "role": department, // UI maps department -> role.
          "email": email,
          "phone": phone,
        },
      ],
    };

    try {
      isLoading.value = true;
      await _runApi(
        call: () =>
            hospitalContactUsRepo.createSchoolBranchContactRepo(reqParm: body),
        fallbackSuccessMsg: AppStrings.hospitalCtrlBranchAddedSuccessfully.tr,
      );
    } catch (_) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  /// GET branch contact details.
  Future<void> getBranchDetailsController() async {
    try {
      schoolContactUsData?.clear();
      final response = await hospitalContactUsRepo.getSchoolContactRepo();
      final model = SchoolContactUsResModel.fromJson(response.response?.data);
      schoolContactUsData?.value = model.data ?? [];

      if (response.isSuccess) {
        getSchoolContactUsResponse.value = ApiResponse.complete(model);
      } else {
        commonSnackBar(message: AppStrings.somethingWentWrong);
        getSchoolContactUsResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    } on Exception catch (e) {
      logs("ERROR $e");
      getSchoolContactUsResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }
  }

  /// Add a new department under an existing branch.
  Future<void> addBranchDepartmentController({
    required Map<String, dynamic> reqBody,
    required String branchID,
  }) async {
    await _runApi(
      call: () => hospitalContactUsRepo.addBranchDepartmentRepo(
        reqParm: reqBody,
        branchId: branchID,
      ),
    );
  }

  /// Update an existing department's contact info.
  Future<void> updateBranchContactDetailsController({
    required Map<String, dynamic> reqBody,
    required String contactID,
    required String branchID,
  }) async {
    await _runApi(
      call: () => hospitalContactUsRepo.updateSchoolContactRepo(
        reqParm: reqBody,
        contactID: contactID,
        branchId: branchID,
      ),
      onSuccess: (response) {
        updateSchoolContactInfoResponse.value =
            ApiResponse.complete(response.response?.data);
      },
    );
  }

  /// Delete a single department from a branch.
  Future<void> deleteSchoolBranchDepartmentController({
    required String departmentId,
    required String contactId,
  }) async {
    await _runApi(
      call: () => hospitalContactUsRepo.deleteSchoolBranchDeptRepo(
        contactID: contactId,
        deptID: departmentId,
      ),
    );
  }

  /// Delete an entire branch.
  Future<void> deleteSchoolBranchController({required String contactId}) async {
    await _runApi(
      call: () =>
          hospitalContactUsRepo.deleteSchoolBranchRepo(contactID: contactId),
    );
  }

  /// Update branch-level info (name / website / location).
  Future<void> updateBranchContactController({
    required Map<String, dynamic> reqBody,
    required String branchId,
  }) async {
    await _runApi(
      call: () => hospitalContactUsRepo.updateSchoolBranchRepo(
        reqParm: reqBody,
        branchID: branchId,
      ),
      onSuccess: (response) {
        updateSchoolContactInfoResponse.value =
            ApiResponse.complete(response.response?.data);
      },
    );
  }
}
