import 'dart:io';

import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/core/services/ai_document_verification_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The visible stage of the manual (image-based) Aadhaar verification UI.
enum AadhaarManualStage {
  /// Enter Aadhaar number + front/back images + consent → submit.
  entry,

  /// Images validated and recorded — show the outcome.
  verified,
}

/// Drives the manual Aadhaar verification fallback, used when OKYC (OTP) can't
/// complete — no Aadhaar-linked mobile, OTP undelivered, provider down, or the
/// number rejected by UIDAI.
///
/// Instead of an OTP, the user's Aadhaar number and card images are checked by
/// the AI document verifier, which confirms the images really are an Aadhaar
/// card and that the number on them matches what was typed.
///
/// Host-agnostic, like [AadhaarKycController]: it performs the AI check and
/// hands the validated result to [onManualVerified] for the host to record.
/// Construct it where the screen is opened and pass it to
/// AadhaarManualKycScreen, which owns its lifecycle.
class AadhaarManualKycController extends GetxController {
  AadhaarManualKycController({
    this.onManualVerified,
    String? initialAadhaarNumber,
    AiDocumentVerificationService? verifier,
  }) : _verifier = verifier ?? AiDocumentVerificationService() {
    if (initialAadhaarNumber != null) {
      aadharController.text =
          initialAadhaarNumber.replaceAll(RegExp(r'\s+'), '');
    }
  }

  /// Invoked once the AI verification passes, with the entered 12-digit Aadhaar
  /// number (spaces stripped) and both card images, so the host can record the
  /// document.
  ///
  /// Awaited before the verified stage is shown. **Throw** to signal that
  /// recording failed — the user is kept on the form to retry rather than shown
  /// a success state for something that wasn't saved. May be null.
  final Future<void> Function(
    String aadhaarNumber,
    File frontImage,
    File backImage,
  )? onManualVerified;

  /// Overridable so tests can drive the verifier's outcome without a network
  /// call. Defaults to the real service.
  final AiDocumentVerificationService _verifier;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final aadharController = TextEditingController();

  final Rx<AadhaarManualStage> stage = AadhaarManualStage.entry.obs;
  final Rxn<File> frontImage = Rxn<File>();
  final Rxn<File> backImage = Rxn<File>();
  final RxBool isSubmitting = false.obs;

  /// Mandatory consent — must be explicitly ticked (never pre-ticked), matching
  /// the OKYC flow's compliance requirement.
  final RxBool consentGiven = false.obs;

  /// Masked number for the verified stage — "XXXX XXXX <last4>".
  final RxnString maskedNumber = RxnString();

  /// What the verifier read off the card (name, date of birth, address), set
  /// just before [onManualVerified] runs so a host can carry it forward — the
  /// gig-work onboarding step pre-fills its form from this. Null until a
  /// successful check, and still null after one if the card was unreadable.
  final Rxn<AiExtractedIdentity> extractedIdentity = Rxn<AiExtractedIdentity>();

  /// Disposes the text controller — call from the screen's dispose.
  void disposeFlow() {
    aadharController.dispose();
  }

  /// Validates the form, runs the AI document check and, on success, hands the
  /// result to [onManualVerified].
  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await _run();
  }

  /// Same check, driven from a host that owns the number and the consent
  /// itself — the photo section sitting on the OTP screen, where this
  /// controller's own [formKey] was never mounted and `currentState` is null.
  ///
  /// The number is validated as a string here for the same reason: there is no
  /// field of ours to ask.
  Future<void> submitWithNumber(String aadhaarNumber) async {
    final aadhaar = aadhaarNumber.replaceAll(RegExp(r'\s+'), '');
    if (aadhaar.length != 12) {
      commonSnackBar(message: 'Please enter a valid 12-digit Aadhaar number.');
      return;
    }
    aadharController.text = aadhaar;
    await _run();
  }

  /// Consent is checked HERE, not in [submit], so both entry points enforce
  /// it — it is a compliance requirement, not a property of one form.
  Future<void> _run() async {
    if (!consentGiven.value) {
      commonSnackBar(
          message: 'Please tick the consent checkbox to verify your Aadhaar.');
      return;
    }

    final front = frontImage.value;
    final back = backImage.value;
    if (front == null) {
      commonSnackBar(message: 'Please upload the front side of your Aadhaar card.');
      return;
    }
    if (back == null) {
      commonSnackBar(message: 'Please upload the back side of your Aadhaar card.');
      return;
    }

    final aadhaar = aadharController.text.replaceAll(RegExp(r'\s+'), '');

    try {
      isSubmitting.value = true;

      final result = await _verifier.verify(
        documentName: AiDocumentVerificationService.aadhaar,
        documentNumber: aadhaar,
        images: [front, back],
      );

      if (!result.isValid) {
        // Rejected, or a check we couldn't complete — the reason is actionable
        // (wrong document, blurry number, mismatch), so let the user retry.
        commonSnackBar(message: result.failureMessage!);
        return;
      }

      // Published BEFORE the bridge so `onManualVerified` can read it — that
      // callback is where a host records the document, and for the onboarding
      // step it is also where the extracted name/DOB get carried forward.
      extractedIdentity.value = result.extracted;

      // Bridge into the host before revealing the verified stage, so the button
      // keeps its spinner until the document is actually recorded. A throw here
      // means the record failed — stay on the form.
      await onManualVerified?.call(aadhaar, front, back);

      maskedNumber.value = 'XXXX XXXX ${aadhaar.substring(aadhaar.length - 4)}';
      stage.value = AadhaarManualStage.verified;
    } catch (e, s) {
      debugPrint('❌ AadhaarManualKyc.submit error: $e\n$s');
      // The host surfaces its own recording errors; don't double-report.
    } finally {
      isSubmitting.value = false;
    }
  }
}
