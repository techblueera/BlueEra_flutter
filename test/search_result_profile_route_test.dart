import 'package:BlueEra/features/business/visit_business_profile/view/visit_business_profile_new.dart';
import 'package:BlueEra/features/common/search/controller/global_search_controller.dart';
import 'package:BlueEra/features/common/search/model/search_models.dart';
import 'package:BlueEra/features/personal/personal_profile/view/visit_personal_profile/new_visiting_profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';

SearchResultItem _item(Map<String, dynamic> o) =>
    SearchResultItem.fromJson({'_id': 'index-doc-id', ...o});

void main() {
  group('profileScreenFor', () {
    test('a person opens their visiting profile, keyed on sourceId', () {
      final screen = GlobalSearchController.profileScreenFor(_item({
        'entityType': 'user',
        'sourceId': 'user-1',
        'title': 'Ravi Gupta',
      }));
      expect(screen, isA<NewVisitProfileScreen>());
      // Never the search-index `_id` — it resolves to nothing in any service.
      expect((screen as NewVisitProfileScreen).authorId, 'user-1');
    });

    test('a provider listing opens its owner, not the listing id', () {
      final screen = GlobalSearchController.profileScreenFor(_item({
        'entityType': 'home_service_provider',
        'sourceId': 'listing-9',
        'ownerId': 'owner-7',
      }));
      expect((screen as NewVisitProfileScreen).authorId, 'owner-7');
    });

    test('every business vertical opens the business profile', () {
      for (final type in GlobalSearchController.businessEntityTypes) {
        final screen = GlobalSearchController.profileScreenFor(
            _item({'entityType': type, 'sourceId': 'biz-1'}));
        expect(screen, isA<VisitBusinessProfileNew>(), reason: type);
        expect((screen as VisitBusinessProfileNew).businessId, 'biz-1');
      }
    });

    test('rows owned by another service have no profile to open', () {
      // Their ids belong to their own service, so the business profile screen
      // would open on an id it cannot fetch.
      for (final type in ['hospital', 'hotel', 'school', 'job', 'rental']) {
        expect(
          GlobalSearchController.profileScreenFor(
              _item({'entityType': type, 'sourceId': 'x-1'})),
          isNull,
          reason: type,
        );
      }
    });

    test('products are not profiles', () {
      expect(
        GlobalSearchController.profileScreenFor(
            _item({'entityType': 'product', 'sourceId': 'p-1'})),
        isNull,
      );
    });

    test('a row with no usable id resolves to nothing rather than a dead screen',
        () {
      expect(
        GlobalSearchController.profileScreenFor(
            _item({'entityType': 'user', 'sourceId': ''})),
        isNull,
      );
      expect(
        GlobalSearchController.profileScreenFor(
            _item({'entityType': 'business'})),
        isNull,
      );
    });
  });
}
