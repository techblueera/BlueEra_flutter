import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/service/model/get_service_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// One ViewBusinessDetailsController serves every visited business, so what it
/// holds is the LAST business opened. Opening a different one must drop it
/// straight away — visitor pages read it ahead of their own data.
///
/// Only the switch itself is under test; the fetches that follow go to the
/// network and are left to run out.
void _ignore(Future<void> f) => unawaited(f.catchError((_) {}));

ViewBusinessProfileModel _profile(String name) => ViewBusinessProfileModel.fromJson({
      'data': {'business_name': name},
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(Get.reset);
  tearDown(Get.reset);

  group('visited profile', () {
    test("opening another business drops the last one's profile at once", () {
      final c = ViewBusinessDetailsController();
      _ignore(c.viewBusinessProfileById('highway-dhaba'));
      c.visitedBusinessProfileDetails = _profile('highway dhaba');
      c.viewBusinessResponseNew = ApiResponse.complete('highway dhaba');

      _ignore(c.viewBusinessProfileById('bhagwati-traders'));

      expect(c.visitedBusinessProfileDetails, isNull);
      // The hospital page merges sections out of this response; left at the
      // previous business's COMPLETE one, a failed load merged it in.
      expect(c.viewBusinessResponseNew.status, Status.INITIAL);
    });

    test('refreshing the same business keeps its profile on screen', () {
      final c = ViewBusinessDetailsController();
      _ignore(c.viewBusinessProfileById('highway-dhaba'));
      final shown = _profile('highway dhaba');
      c.visitedBusinessProfileDetails = shown;

      _ignore(c.viewBusinessProfileById('highway-dhaba', silent: true));

      expect(c.visitedBusinessProfileDetails, same(shown));
    });
  });

  group('services rail', () {
    test("opening another business clears the last one's services", () async {
      final c = ViewBusinessDetailsController();
      _ignore(c.fetchServices(visitBusinessId: 'finance-a'));
      c.services.add(GetServiceModel.fromJson({}));

      _ignore(c.fetchServices(visitBusinessId: 'finance-b'));
      // Cleared a microtask late: callers run this from initState, where
      // notifying the list's listeners synchronously would throw.
      await Future<void>.delayed(Duration.zero);

      expect(c.services, isEmpty);
    });

    test('the same business keeps its services while they refresh', () async {
      final c = ViewBusinessDetailsController();
      _ignore(c.fetchServices(visitBusinessId: 'finance-a'));
      await Future<void>.delayed(Duration.zero);
      c.services.add(GetServiceModel.fromJson({}));

      _ignore(c.fetchServices(visitBusinessId: 'finance-a'));
      await Future<void>.delayed(Duration.zero);

      expect(c.services, hasLength(1));
    });
  });
}
