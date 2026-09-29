import 'package:BlueEra/features/common/Discover/binding/stay_discover_binding.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/controller/stay_discover_controller.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('the stays screen gets its own controller, not DiscoverController', () {
    StayDiscoverBinding().dependencies();

    final stays = Get.find<StayDiscoverController>();
    expect(stays.rentalServices, isEmpty);
    expect(Get.isRegistered<DiscoverController>(), isFalse);
  });

  test('a hotel offers each named room type once', () {
    final hotel = HotelServiceData.fromJson({
      'rooms': [
        {'type': 'Deluxe'},
        {'type': 'Suite'},
        {'type': 'Deluxe'},
        {'type': ''},
        <String, dynamic>{},
      ],
    });

    expect(StayDiscoverController().getDynamicRoomTypes(hotel),
        ['Deluxe', 'Suite']);
  });
}
