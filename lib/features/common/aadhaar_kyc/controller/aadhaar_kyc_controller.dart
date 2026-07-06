import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/model/aadhaar_verification_model.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/repo/aadhaar_kyc_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The visible stage of the Aadhaar OKYC (OTP) verification UI.
enum AadhaarStage {
  /// Enter 12-digit Aadhaar + tick consent → generate OTP.
  entry,

  /// Enter the 6-digit OTP received on the Aadhaar-linked mobile → verify.
  otp,

  /// Identity verified — show name + masked number.
  verified,
}

/// Reusable controller driving the generic per-user Aadhaar OKYC (OTP)
/// verification flow (status → generate-otp → verify-otp). It is host-agnostic:
/// each screen supplies an [onVerified] callback to bridge the verified result
/// into its own flow (e.g. mark a rider onboarding step / record a document).
///
/// This is a plain (non-registered) controller — construct it where the sheet
/// is opened and pass it to [AadhaarKycView], which owns its lifecycle.
/// See docs/backend/aadhaar-verification-ui-integration.md.
class AadhaarKycController extends GetxController {
  AadhaarKycController({this.onVerified});

  /// Invoked once verify-otp succeeds, with the entered 12-digit Aadhaar
  /// number (spaces stripped). Awaited before the verified stage is shown, so
  /// hosts can record the result and surface their own errors. May be null.
  final Future<void> Function(String verifiedAadhaarNumber)? onVerified;

  final AadhaarKycRepo _repo = AadhaarKycRepo();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final aadharController = TextEditingController();
  final otpController = TextEditingController();

  final Rx<AadhaarStage> stage = AadhaarStage.entry.obs;
  final RxBool isStatusLoading = false.obs;
  final RxBool isOtpSending = false.obs;
  final RxBool isOtpVerifying = false.obs;

  /// Mandatory consent — must be explicitly ticked (never pre-ticked).
  final RxBool consentGiven = false.obs;

  /// reference_id returned by generate-otp; sent back with the OTP on verify.
  String referenceId = '';

  /// Verified identity, populated from status / verify-otp responses.
  final RxBool isVerified = false.obs;
  final RxnString verifiedName = RxnString();

  /// Masked number for display — "XXXX XXXX <last4>".
  final RxnString maskedNumber = RxnString();
  final RxnString verifiedAt = RxnString();

  /// Resend cooldown (seconds remaining). Resend is disabled while > 0.
  final RxInt resendSeconds = 0.obs;
  Timer? _resendTimer;

  static const int _resendCooldown = 45; // 30–60 s window per guide.

  String _maskFromLast4(String? last4) =>
      (last4 == null || last4.isEmpty) ? '' : 'XXXX XXXX $last4';

  /// Resets the flow to a clean state and fetches the current status.
  /// Call whenever the sheet opens.
  Future<void> init() async {
    _resendTimer?.cancel();
    resendSeconds.value = 0;
    otpController.clear();
    referenceId = '';
    consentGiven.value = false;
    isVerified.value = false;
    verifiedName.value = null;
    maskedNumber.value = null;
    verifiedAt.value = null;
    stage.value = AadhaarStage.entry;
    await checkStatus();
  }

  /// Cancels the resend timer — call from the view's dispose.
  void disposeFlow() {
    _resendTimer?.cancel();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    resendSeconds.value = _resendCooldown;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendSeconds.value <= 1) {
        resendSeconds.value = 0;
        t.cancel();
      } else {
        resendSeconds.value--;
      }
    });
  }

  /// GET /user/aadhaar/status — an in-progress OTP attempt is treated as not
  /// verified (start fresh).
  Future<void> checkStatus() async {
    try {
      isStatusLoading.value = true;
      final response = await _repo.statusRepo();
      final data = response.data;
      if (response.isSuccess && data is Map) {
        final status =
            AadhaarStatusData.fromJson(Map<String, dynamic>.from(data));
        if (status.isVerified) {
          isVerified.value = true;
          verifiedName.value = status.name;
          maskedNumber.value = _maskFromLast4(status.aadhaarLast4);
          verifiedAt.value = status.verifiedAt;
          stage.value = AadhaarStage.verified;
        } else {
          stage.value = AadhaarStage.entry;
        }
      }
    } catch (e) {
      // Non-fatal: fall back to the entry form so the user can still verify.
      debugPrint('❌ AadhaarKyc.checkStatus error: $e');
    } finally {
      isStatusLoading.value = false;
    }
  }

  /// POST /user/aadhaar/generate-otp — requires a valid 12-digit number and
  /// the consent checkbox ticked.
  Future<void> generateOtp() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (!consentGiven.value) {
      commonSnackBar(
          message: 'Please tick the consent checkbox to verify your Aadhaar.');
      return;
    }

    final aadhaar = aadharController.text.replaceAll(RegExp(r'\s+'), '');

    try {
      isOtpSending.value = true;
      final response = await _repo.generateOtpRepo(
        params: {
          ApiKeys.aadhaarNumber: aadhaar,
          ApiKeys.consent: 'Y',
          ApiKeys.reason: 'For KYC',
        },
      );

      final body = response.response?.data;
      final isBusinessOk = body is Map && body['success'] == true;

      if (response.isSuccess && isBusinessOk) {
        final data = body['data'];
        referenceId =
            (data is Map ? data['reference_id']?.toString() : null) ?? '';
        otpController.clear();
        stage.value = AadhaarStage.otp;
        _startResendCooldown();
        commonSnackBar(
            message: (body['message']?.toString().isNotEmpty ?? false)
                ? body['message'].toString()
                : 'OTP sent to your Aadhaar-linked mobile number');
      } else {
        // 200-with-success:false (e.g. "Invalid Aadhaar Card", "Please retry
        // after 30 seconds") or a real error status — surface the message.
        final msg = (body is Map ? body['message']?.toString() : null) ??
            response.message ??
            AppStrings.somethingWentWrong;
        commonSnackBar(message: msg);
      }
    } catch (e, s) {
      debugPrint('❌ AadhaarKyc.generateOtp error: $e\n$s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isOtpSending.value = false;
    }
  }

  /// POST /user/aadhaar/verify-otp — on success, awaits [onVerified] and then
  /// shows the verified stage.
  Future<void> verifyOtp() async {
    if (referenceId.isEmpty) {
      commonSnackBar(
          message: 'Your session expired. Please request a new OTP.');
      stage.value = AadhaarStage.entry;
      return;
    }
    if (otpController.text.trim().length != 6) {
      commonSnackBar(message: 'Please enter the 6-digit OTP.');
      return;
    }

    try {
      isOtpVerifying.value = true;
      final response = await _repo.verifyOtpRepo(
        params: {
          ApiKeys.referenceId: referenceId,
          ApiKeys.otp: otpController.text.trim(),
        },
      );

      final body = response.response?.data;
      final verified = body is Map &&
          body['success'] == true &&
          body['is_verified'] == true;

      if (response.isSuccess && verified) {
        _resendTimer?.cancel();
        final data = body['data'];
        final identity = data is Map
            ? AadhaarVerifiedIdentity.fromJson(Map<String, dynamic>.from(data))
            : null;
        isVerified.value = true;
        verifiedName.value = identity?.name;
        maskedNumber.value = _maskFromLast4(identity?.aadhaarLast4);
        verifiedAt.value = DateTime.now().toIso8601String();
        commonSnackBar(
            message: (body['message']?.toString().isNotEmpty ?? false)
                ? body['message'].toString()
                : 'Aadhaar verified successfully');

        // Bridge the verified identity into the host flow before revealing the
        // verified stage (keeps the "Verifying…" spinner until it settles).
        final number = aadharController.text.replaceAll(RegExp(r'\s+'), '');
        await onVerified?.call(number);
        stage.value = AadhaarStage.verified;
      } else {
        // "Invalid OTP" / "OTP expired" / "No pending OTP request found" etc.
        final msg = (body is Map ? body['message']?.toString() : null) ??
            response.message ??
            AppStrings.somethingWentWrong;
        commonSnackBar(message: msg);
      }
    } catch (e, s) {
      debugPrint('❌ AadhaarKyc.verifyOtp error: $e\n$s');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isOtpVerifying.value = false;
    }
  }

  /// Go back from the OTP stage to the Aadhaar entry stage (edit number).
  void editNumber() {
    _resendTimer?.cancel();
    resendSeconds.value = 0;
    otpController.clear();
    stage.value = AadhaarStage.entry;
  }
}
