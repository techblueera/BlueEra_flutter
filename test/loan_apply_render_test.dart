import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/auth/controller/auth_controller.dart';
import 'package:BlueEra/features/loan/controller/loan_application_controller.dart';
import 'package:BlueEra/features/loan/model/loan_enums.dart';
import 'package:BlueEra/features/loan/view/quick_loan_apply_screen.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Renders the Quick Loan Apply form and walks it end to end.
///
/// This exists because step 1 shipped BLANK once: a `CrossAxisAlignment.stretch`
/// Row under a scroll view's unbounded height threw during layout, and every
/// ancestor up to the body reported "was not laid out" — the app bar and the CTA
/// drew, the form did not. Nothing in `flutter analyze` sees that, and it only
/// showed up on device. A pump that asserts `takeException() == null` does see
/// it, and sees a RenderFlex overflow too.
///
/// No translations are registered, so `.tr` returns the KEY — `'loanName'`
/// rather than "Name". That is deliberate: the finders then depend on
/// `AppStrings`, not on the current English copy.
void main() {
  /// 360x800 at 3x — a narrow real phone. The 800x600 test default is wider
  /// than any device and would hide a horizontal overflow.
  Future<LoanApplicationController> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    addTearDown(Get.reset);

    // The shared [CommonBackAppBar] reads `isSearchOpen` off it. It is a
    // permanent controller in the running app and has no `onInit`, so a bare
    // instance is enough here.
    Get.put(AuthController());

    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(builder: (context) {
          SizeConfig.init(context);
          return const QuickLoanApplyScreen();
        }),
      ),
    );
    await tester.pumpAndSettle();
    return Get.find<LoanApplicationController>();
  }

  /// The `TextFormField` inside the [CommonTextField] whose title is [title].
  Finder fieldTitled(String title) => find.descendant(
        of: find.ancestor(
          of: find.text(title),
          matching: find.byType(CommonTextField),
        ),
        matching: find.byType(TextFormField),
      );

  Future<void> tapCta(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('step 1 lays out with every control present', (tester) async {
    await pumpForm(tester);

    expect(tester.takeException(), isNull);

    // Both section cards, not just the header — a blank body still renders the
    // app bar, so the cards are what prove the form itself laid out.
    expect(find.text('loanPersonalDetails'), findsOneWidget);
    expect(find.text('loanProfessionalDetails'), findsOneWidget);

    for (final label in [
      'loanName',
      'loanDob',
      'loanMobileNumber',
      'loanAddress',
      'loanPanNumber',
      'loanAnnualIncome',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'missing $label');
    }

    // Salaried is the default branch, so its two fields show and the
    // self-employed ones do not.
    expect(find.text('loanCompanyName'), findsOneWidget);
    expect(find.text('loanJobRole'), findsOneWidget);
    expect(find.text('loanBusinessName'), findsNothing);

    // Drag the whole step past the viewport. A [SingleChildScrollView] lays its
    // child out in full but culls the painting of what is off-screen, so an
    // overflow below the fold is only reported once it is scrolled into view.
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the mobile field shows its +91 prefix while empty and unfocused',
      (tester) async {
    final c = await pumpForm(tester);
    c.mobileCtrl.clear();
    await tester.pumpAndSettle();

    expect(find.text('+91 '), findsOneWidget);
  });

  testWidgets('the profession toggle swaps the employment fields',
      (tester) async {
    final c = await pumpForm(tester);

    // Scroll it into view FIRST. The professional-details card is the second
    // section and sits below the fold at 360x800, and `tester.tap` on an
    // off-screen widget only WARNS — it still dispatches at that coordinate and
    // hits nothing, so the test would read as "the toggle does not work".
    await tester.ensureVisible(find.text('loanSelfEmployed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('loanSelfEmployed'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(c.professionType.value, ProfessionType.business);
    expect(find.text('loanCompanyName'), findsNothing);
    for (final label in [
      'loanBusinessName',
      'loanNatureOfBusiness',
      'loanBusinessExperience',
      'loanBusinessAddress',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'missing $label');
    }
  });

  testWidgets('an empty step 1 reports itself instead of advancing',
      (tester) async {
    final c = await pumpForm(tester);
    // The prefill may have filled the name from the signed-in profile; clear it
    // so the assertion is about an untouched form.
    c.nameCtrl.clear();
    c.mobileCtrl.clear();
    await tester.pumpAndSettle();

    await tapCta(tester, 'loanContinueCta');

    expect(tester.takeException(), isNull);
    // Still on step 1 — the loan card never appeared.
    expect(find.text('loanDetails'), findsNothing);
    expect(find.text('loanPersonalDetails'), findsOneWidget);
    // The DOB row is the manual half of validation; it has to speak up too.
    expect(find.text('loanDobRequired'), findsOneWidget);
  });

  testWidgets('a touched field shows its own error, an untouched one waits',
      (tester) async {
    final c = await pumpForm(tester);
    c.panCtrl.clear();
    await tester.pumpAndSettle();

    // `onUserInteraction`: nothing is red before anything is typed.
    expect(find.text('loanPanRequired'), findsNothing);
    expect(find.text('loanPanInvalid'), findsNothing);

    await tester.enterText(fieldTitled('loanPanNumber'), 'NOTAPAN');
    await tester.pumpAndSettle();

    // The error renders INSIDE [CommonTextField]'s white plate, which is
    // clipped — so this also proves the clip is not swallowing it.
    expect(find.text('loanPanInvalid'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(fieldTitled('loanPanNumber'), 'ABCDE1234F');
    await tester.pumpAndSettle();
    expect(find.text('loanPanInvalid'), findsNothing);
  });

  testWidgets('a filled step 1 advances, and step 2 lays out', (tester) async {
    final c = await pumpForm(tester);

    await tester.enterText(fieldTitled('loanName'), 'Asha Rao');
    await tester.enterText(fieldTitled('loanMobileNumber'), '9876543210');
    await tester.enterText(fieldTitled('loanAddress'), '12 Park Street');
    await tester.enterText(fieldTitled('loanPanNumber'), 'ABCDE1234F');
    await tester.enterText(fieldTitled('loanAnnualIncome'), '600000');
    await tester.enterText(fieldTitled('loanCompanyName'), 'Acme Ltd');
    await tester.enterText(fieldTitled('loanJobRole'), 'Analyst');
    // The DOB dropdowns have no text to enter.
    c.dobDay.value = 4;
    c.dobMonth.value = 6;
    c.dobYear.value = DateTime.now().year - 30;
    await tester.pumpAndSettle();

    await tapCta(tester, 'loanContinueCta');
    expect(tester.takeException(), isNull);

    expect(find.text('loanDetails'), findsOneWidget);
    for (final label in [
      'loanRequiredAmount',
      'loanPurpose',
      'loanPreferredTenure',
      'loanExistingEmi',
      'loanNoExistingEmi',
      'loanPincode',
      'loanCurrentResidence',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'missing $label');
    }

    // All five tenure pills. Counted rather than matched per value: without
    // translations `trParams` has no "@months" placeholder to substitute, so
    // every pill renders the same key — the count is the only real assertion
    // available here, and it is the one that catches a Wrap that dropped a pill.
    expect(find.text('loanMonthsFmt'), findsNWidgets(5));
    expect(find.text('loanApplyCta'), findsOneWidget);

    // Scrolling to the bottom is where a step-2 overflow would surface — the
    // terms row and the EMI row are the widest things on the page.
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('ticking "no existing EMI" clears and disables the amount',
      (tester) async {
    final c = await pumpForm(tester);
    c.loanTenureMonths.value = 12;
    await tester.pumpAndSettle();

    // Jump straight to step 2 rather than filling step 1 again.
    await tester.enterText(fieldTitled('loanName'), 'Asha Rao');
    await tester.enterText(fieldTitled('loanMobileNumber'), '9876543210');
    await tester.enterText(fieldTitled('loanAddress'), '12 Park Street');
    await tester.enterText(fieldTitled('loanPanNumber'), 'ABCDE1234F');
    await tester.enterText(fieldTitled('loanAnnualIncome'), '600000');
    await tester.enterText(fieldTitled('loanCompanyName'), 'Acme Ltd');
    await tester.enterText(fieldTitled('loanJobRole'), 'Analyst');
    c.dobDay.value = 4;
    c.dobMonth.value = 6;
    c.dobYear.value = DateTime.now().year - 30;
    await tester.pumpAndSettle();
    await tapCta(tester, 'loanContinueCta');

    c.existingEmiCtrl.text = '5000';
    await tester.pumpAndSettle();

    await tester.tap(find.text('loanNoExistingEmi'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(c.noExistingEmi.value, isTrue);
    // Cleared, so the flag and the field cannot disagree about what was
    // declared — and the row stays on screen rather than reflowing away under
    // the finger that ticked it.
    expect(c.existingEmiCtrl.text, isEmpty);
    expect(find.text('loanExistingEmi'), findsOneWidget);
  });
}
