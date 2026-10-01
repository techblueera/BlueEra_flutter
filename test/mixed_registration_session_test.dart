import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/features/business/onboarding/controller/business_onboarding_controller.dart';
import 'package:BlueEra/features/chat/auth/controller/payment_qr_controller.dart';
import 'package:BlueEra/features/me/job_seekar/controller/job_seeker_portfolio_professionals_controller.dart';
import 'package:BlueEra/features/me/professionals_consultant/controller/portfolio_professionals_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('the first screen to ask no longer decides how long they live', () {
    final onboarding = BusinessOnboardingController.to;
    final qr = PaymentQrController.to;
    final portfolio = PortfolioProfessionalsController.to;
    final jobSeeker = JobSeekerPortfolioProfessionalsController.to;

    // What GetX does when the route that first registered them closes.
    Get.delete<BusinessOnboardingController>();
    Get.delete<PaymentQrController>();
    Get.delete<PortfolioProfessionalsController>();
    Get.delete<JobSeekerPortfolioProfessionalsController>();

    expect(BusinessOnboardingController.to, same(onboarding));
    expect(PaymentQrController.to, same(qr));
    expect(PortfolioProfessionalsController.to, same(portfolio));
    expect(JobSeekerPortfolioProfessionalsController.to, same(jobSeeker));
  });

  test('logout drops them, so the next account starts clean', () {
    BusinessOnboardingController.to;
    PaymentQrController.to;
    PortfolioProfessionalsController.to;
    JobSeekerPortfolioProfessionalsController.to;

    LogoutHelper.resetAccountControllers();

    expect(Get.isRegistered<BusinessOnboardingController>(), isFalse);
    expect(Get.isRegistered<PaymentQrController>(), isFalse);
    expect(Get.isRegistered<PortfolioProfessionalsController>(), isFalse);
    expect(
        Get.isRegistered<JobSeekerPortfolioProfessionalsController>(), isFalse);
  });
}
