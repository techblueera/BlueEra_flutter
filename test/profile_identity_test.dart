import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/profile_identity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prerequisites for the profile-category change feature (§3.1 and §3.2 of
/// FLUTTER_PROFILE_CATEGORY_CHANGE_GUIDE.md).
///
/// Both are the kind of thing that fails silently in production — a
/// `profileType` comparison that stops matching, or a rider gate that hides
/// the rider tab from a profession it doesn't recognise — so they are pinned
/// here rather than left to a manual pass on a test account.
void main() {
  group('normalizeProfileType — backend catalog spellings', () {
    test('maps the four catalog display strings to the app constants', () {
      expect(normalizeProfileType('GigWork'), GIG_WORKER);
      expect(normalizeProfileType('Self Employed'), SELF_EMPLOYED);
      expect(normalizeProfileType('Professional'), PROFESSIONAL);
      expect(normalizeProfileType('Social Profile'), SOCIAL_PROFILE);
    });

    test('is idempotent — the app constants pass through unchanged', () {
      // This is what makes it safe to apply unconditionally, whichever way the
      // backend contract lands (§3.2).
      for (final v in [GIG_WORKER, SELF_EMPLOYED, PROFESSIONAL, SOCIAL_PROFILE]) {
        expect(normalizeProfileType(v), v);
        expect(normalizeProfileType(normalizeProfileType(v)), v);
      }
    });

    test('folds the catalog aliases the taxonomy already knew about', () {
      // One shared table with profile_taxonomy.dart — SKILL_WORKER is how the
      // catalog buckets "Self Employed" professions, and CONSULTANT is its
      // spelling of Professional. The app has no screen for either name, so
      // leaving them unmapped drops those accounts on the unknown fallback.
      expect(normalizeProfileType('SKILL_WORKER'), SELF_EMPLOYED);
      expect(normalizeProfileType('Skill Work'), SELF_EMPLOYED);
      expect(normalizeProfileType('CONSULTANT'), PROFESSIONAL);
    });

    test('ignores case, spacing and punctuation', () {
      expect(normalizeProfileType('gigwork'), GIG_WORKER);
      expect(normalizeProfileType('  GigWork  '), GIG_WORKER);
      expect(normalizeProfileType('gig_worker'), GIG_WORKER);
      expect(normalizeProfileType('SELF-EMPLOYED'), SELF_EMPLOYED);
      expect(normalizeProfileType('self employed'), SELF_EMPLOYED);
    });

    test('empty and null collapse to empty, never to a wrong profile type', () {
      // An unhydrated global must not read as SOCIAL_PROFILE — that would hide
      // go-live from an account whose type simply hasn't loaded yet.
      expect(normalizeProfileType(null), '');
      expect(normalizeProfileType(''), '');
      expect(normalizeProfileType('   '), '');
    });

    test('an unknown type keeps its meaning in the app shape', () {
      // Not blanked: a profileType the backend adds later arrives as
      // SOME_NEW_TYPE, so whichever constant is written for it matches without
      // this function needing an edit.
      expect(normalizeProfileType('Some New Type'), 'SOME_NEW_TYPE');
      expect(normalizeProfileType('FRANCHISE'), 'FRANCHISE');
    });
  });

  group('rider professions — §3.1', () {
    test('Bicycle Rider is a rider', () {
      // The whole point of the prerequisite: without this, a user who changes
      // to Bicycle Rider gets a correct backend record and no rider UI at all.
      expect(BICYCLE_RIDER, 'BICYCLE_RIDER');
      expect(isRiderProfession(BICYCLE_RIDER), isTrue);
      expect(kRiderProfessions.contains(BICYCLE_RIDER), isTrue);
    });

    test('every dispatch profession still counts', () {
      for (final p in GigProfession.values) {
        expect(isRiderProfession(p.tag), isTrue,
            reason: '${p.tag} should be a rider');
      }
    });

    test('matches the GigWork bucket the catalog actually serves', () {
      // Observed from GET user-service/individual-professions — the five tags
      // returned for profileType "GigWork". If the server adds a sixth, this
      // fails and [GigProfession] gets the new value, rather than the app
      // quietly having no rider gate for it.
      expect(
        GigProfession.values.map((p) => p.tag).toSet(),
        {
          'BIKE_RIDER',
          'CAR_TAXI_DRIVER',
          'GOODS_SUPPLY',
          'AUTO_ERICKSHAW',
          'BICYCLE_RIDER',
        },
      );
    });

    test('the dead CAR_DRIVER_TAXI spelling is gone', () {
      // The old CAR_TAXI constant. The catalog never sent it, so every check
      // against it silently failed and the Discover icon map keyed the cab
      // icon off it.
      expect(kRiderProfessions.contains('CAR_DRIVER_TAXI'), isFalse);
      expect(GigProfession.fromTag('CAR_DRIVER_TAXI'), isNull);
      expect(GigProfession.fromTag('CAR_TAXI_DRIVER'),
          GigProfession.carTaxiDriver);
    });

    test('kRiderProfessions is derived from the enum, not a second list', () {
      expect(kRiderProfessions, GigProfession.values.map((p) => p.tag).toSet());
    });

    test('only the bicycle is not a motor vehicle', () {
      // The one distinction the rider gates must not flatten: RC and driving
      // licence apply to everything here except the bicycle.
      for (final p in GigProfession.values) {
        expect(p.isMotorVehicle, p != GigProfession.bicycleRider,
            reason: '${p.tag}.isMotorVehicle');
      }
    });

    test('fromTag ignores non-gig and unset professions', () {
      expect(GigProfession.fromTag(PLUMBER), isNull);
      expect(GigProfession.fromTag(''), isNull);
      expect(GigProfession.fromTag(null), isNull);
    });

    test('non-dispatch professions do not', () {
      for (final p in [PLUMBER, ELECTRICIAN, TUTOR, MECHANIC, CONSULTANT]) {
        expect(isRiderProfession(p), isFalse, reason: '$p is not a rider');
      }
      expect(isRiderProfession(null), isFalse);
      expect(isRiderProfession(''), isFalse);
    });
  });
}
