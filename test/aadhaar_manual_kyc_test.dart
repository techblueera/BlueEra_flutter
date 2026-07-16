import 'dart:io';

import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/services/ai_document_verification_service.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/controller/aadhaar_manual_kyc_controller.dart';
import 'package:BlueEra/features/common/aadhaar_kyc/view/aadhaar_manual_kyc_screen.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Stands in for the AI document verifier, so these tests never touch the
/// network and can assert whether it was called at all — the difference between
/// "the guard blocked submission" and "the guard let it through and the request
/// happened to fail".
class _FakeVerifier extends AiDocumentVerificationService {
  _FakeVerifier(this.result);

  final AiDocumentVerificationResult result;
  final List<String> numbersVerified = [];
  int imagesInLastCall = 0;

  @override
  Future<AiDocumentVerificationResult> verify({
    required String documentName,
    required String documentNumber,
    required List<File> images,
  }) async {
    numbersVerified.add(documentNumber);
    imagesInLastCall = images.length;
    return result;
  }
}

/// Tests for the manual (image-based) Aadhaar verification fallback, reached
/// when OKYC (OTP) can't complete.
void main() {
  setUp(() {
    Get.reset();
    // CommonBackAppBar reads AuthController.isSearchOpen; the app registers it
    // permanently at startup, so a screen test has to stand it up too.
    Get.put(AuthController());
  });
  tearDown(Get.reset);

  /// Aadhaar numbers the host was asked to record.
  late List<String> recorded;
  late _FakeVerifier verifier;

  AadhaarManualKycController buildController({
    String? initialAadhaarNumber,
    AiDocumentVerificationResult verdict =
        const AiDocumentVerificationResult.valid(),
    Future<void> Function()? onRecord,
  }) {
    recorded = [];
    verifier = _FakeVerifier(verdict);
    return AadhaarManualKycController(
      initialAadhaarNumber: initialAadhaarNumber,
      verifier: verifier,
      onManualVerified: (number, front, back) async {
        recorded.add(number);
        if (onRecord != null) await onRecord();
      },
    );
  }

  /// Pumps the screen with SizeConfig initialised, as the real app does at
  /// startup.
  Future<void> pumpScreen(
    WidgetTester tester,
    AadhaarManualKycController controller,
  ) async {
    await tester.pumpWidget(GetMaterialApp(
      home: Builder(builder: (context) {
        SizeConfig.init(context);
        return AadhaarManualKycScreen(controller: controller);
      }),
    ));
    await tester.pump();
  }

  /// Scrolls Submit into view before tapping it. Once a card image is picked
  /// its tile grows and pushes the button past the bottom of the test viewport,
  /// where a plain tap() silently misses — which would make a "didn't happen"
  /// assertion pass for the wrong reason.
  Future<void> tapSubmit(WidgetTester tester) async {
    final submit = find.text('Submit');
    await tester.ensureVisible(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();
  }

  /// A fully valid form: 12-digit number, consent ticked, both sides uploaded.
  void fillValidForm(AadhaarManualKycController controller) {
    controller.consentGiven.value = true;
    controller.frontImage.value = File('front.jpg');
    controller.backImage.value = File('back.jpg');
  }

  testWidgets('entry stage renders the number field, both card tiles and submit',
      (tester) async {
    await pumpScreen(tester, buildController());

    expect(find.text('Aadhaar Number'), findsOneWidget);
    expect(find.text('Front'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
    expect(find.textContaining('I voluntarily share my Aadhaar details'),
        findsOneWidget);
  });

  testWidgets('prefills the number carried over from the failed OTP attempt',
      (tester) async {
    final controller = buildController(initialAadhaarNumber: '5678 1234 6679');
    await pumpScreen(tester, controller);

    // Spaces stripped: the user shouldn't have to retype what they just typed
    // on the OTP screen, and the field itself is digits-only.
    expect(controller.aadharController.text, '567812346679');
    expect(find.text('567812346679'), findsOneWidget);
  });

  testWidgets('a valid submission verifies both sides, then records it',
      (tester) async {
    final controller = buildController(initialAadhaarNumber: '567812346679');
    await pumpScreen(tester, controller);
    fillValidForm(controller);
    await tester.pump();

    await tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(verifier.numbersVerified, ['567812346679']);
    expect(verifier.imagesInLastCall, 2,
        reason: 'both card sides must go to the verifier');
    expect(recorded, ['567812346679']);
    expect(controller.stage.value, AadhaarManualStage.verified);
    expect(find.text('Aadhaar Verified'), findsOneWidget);
  });

  testWidgets('a document the AI rejects is never recorded', (tester) async {
    final controller = buildController(
      initialAadhaarNumber: '567812346679',
      verdict: const AiDocumentVerificationResult.invalid('Blurry number'),
    );
    await pumpScreen(tester, controller);
    fillValidForm(controller);
    await tester.pump();

    await tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(verifier.numbersVerified, hasLength(1));
    expect(recorded, isEmpty,
        reason: 'a rejected document must not reach the document service');
    expect(controller.stage.value, AadhaarManualStage.entry,
        reason: 'the user stays on the form to retry');
  });

  testWidgets('a failure to record leaves the user on the form, not on success',
      (tester) async {
    final controller = buildController(
      initialAadhaarNumber: '567812346679',
      onRecord: () async => throw Exception('upload failed'),
    );
    await pumpScreen(tester, controller);
    fillValidForm(controller);
    await tester.pump();

    await tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(controller.stage.value, AadhaarManualStage.entry,
        reason: 'never show a success state for something that was not saved');
    expect(controller.isSubmitting.value, isFalse,
        reason: 'the button must not be left spinning after a failure');
  });

  testWidgets('an invalid Aadhaar number never reaches the verifier',
      (tester) async {
    final controller = buildController(initialAadhaarNumber: '123');
    await pumpScreen(tester, controller);
    fillValidForm(controller);
    await tester.pump();

    await tapSubmit(tester);

    expect(verifier.numbersVerified, isEmpty);
    expect(recorded, isEmpty);
  });

  testWidgets('submit is blocked until consent is ticked', (tester) async {
    final controller = buildController(initialAadhaarNumber: '567812346679');
    await pumpScreen(tester, controller);
    controller.frontImage.value = File('front.jpg');
    controller.backImage.value = File('back.jpg');
    await tester.pump();

    await tapSubmit(tester);

    expect(verifier.numbersVerified, isEmpty,
        reason: 'consent is a compliance requirement, not a nicety');
    expect(recorded, isEmpty);
  });

  testWidgets('submit is blocked until both card sides are uploaded',
      (tester) async {
    final controller = buildController(initialAadhaarNumber: '567812346679');
    await pumpScreen(tester, controller);
    controller.consentGiven.value = true;
    controller.frontImage.value = File('front.jpg');
    await tester.pump();

    await tapSubmit(tester);

    expect(verifier.numbersVerified, isEmpty,
        reason: 'the back side carries details the verifier needs');
    expect(recorded, isEmpty);
  });

  testWidgets('verified stage shows the masked number, never the full one',
      (tester) async {
    final controller = buildController(initialAadhaarNumber: '567812346679');
    await pumpScreen(tester, controller);
    fillValidForm(controller);
    await tester.pump();

    await tapSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('XXXX XXXX 6679'), findsOneWidget);
    expect(find.text('567812346679'), findsNothing);
    expect(find.text('Done'), findsOneWidget);
  });
}
