import 'package:BlueEra/core/constants/logout_helper.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/professional_discover_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('the entry and listing screens share one instance for the session', () {
    final listing = ProfessionalDiscoverController.to;
    listing.setEarnDiscoverLocation(lat: 26.8, lng: 80.9, label: 'Lucknow');
    listing.toggleProviderLocalSave('p1');

    // What GetX does when the route that first used it closes.
    Get.delete<ProfessionalDiscoverController>();

    final again = ProfessionalDiscoverController.to;
    expect(again, same(listing));
    expect(again.earnDiscoverLocationLabel.value, 'Lucknow');
    expect(again.isProviderLocallySaved('p1'), isTrue);
    // The listings no longer need the ride controller.
    expect(Get.isRegistered<DiscoverController>(), isFalse);
  });

  test('saving a provider twice un-saves it', () {
    final listing = ProfessionalDiscoverController.to;

    listing.toggleProviderLocalSave('p1');
    listing.toggleProviderLocalSave('p1');

    expect(listing.isProviderLocallySaved('p1'), isFalse);
  });

  test('logout drops it, so the next account starts with no saved providers',
      () {
    ProfessionalDiscoverController.to.toggleProviderLocalSave('p1');

    LogoutHelper.resetAccountControllers();

    expect(Get.isRegistered<ProfessionalDiscoverController>(), isFalse);
    expect(ProfessionalDiscoverController.to.isProviderLocallySaved('p1'),
        isFalse);
  });
}
