import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/business/auth/repo/business_profile_repo.dart';
import 'package:BlueEra/features/common/Discover/model/hotel_search_model.dart';
import 'package:BlueEra/features/common/Discover/repo/discover_repo.dart';
import 'package:BlueEra/features/me/hotel/model/hotel_booking_models.dart';
import 'package:BlueEra/features/me/hotel/service/hotel_room_catalog.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_booking_models.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:BlueEra/features/me/laboratory/service/lab_test_catalog.dart';
import 'package:BlueEra/features/me/medical/model/hospital_appointment_models.dart';
import 'package:BlueEra/features/me/medical/service/hospital_doctor_catalog.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';

ResponseModel _res(int status, Object? data) => ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(), statusCode: status, data: data),
    );

class _FakeLabRepo extends LabTestRepo {
  int calls = 0;

  @override
  Future<ResponseModel> getPathologyTestsByLab(
      String labId, String collection) async {
    calls++;
    return _res(200, {
      'data': [
        {'_id': 't1', 'testName': 'CBC'},
        {'testName': 'no id'},
      ],
    });
  }
}

class _FakeProfileRepo extends BusinessProfileRepo {
  int calls = 0;

  @override
  Future<ResponseModel> viewBusinessProfileById(String? userId) async {
    calls++;
    return _res(200, {
      'data': {
        'hospital': {
          '_id': 'h1',
          'name': 'City Hospital',
          'departments': [
            {
              'name': 'Cardiology',
              'opd': [
                {'_id': 'd1', 'name': 'Dr. Rao', 'timing': '10-2'},
                {'name': 'no id'},
              ],
            },
          ],
        },
      },
    });
  }
}

class _FakeDiscoverRepo extends DiscoverRepo {
  @override
  Future<HotelServiceData?> fetchHotelByBusinessId(String businessId) async =>
      HotelServiceData.fromJson({
        'rooms': [
          {'_id': 'r1', 'name': 'Deluxe', 'type': 'deluxe', 'isActive': true},
          {'_id': 'r2', 'name': 'Closed', 'isActive': false},
          {'name': 'no id'},
        ],
      });
}

void main() {
  setUp(() {
    LabTestCatalog.clear();
    HospitalDoctorCatalog.clear();
    HotelRoomCatalog.clear();
  });

  group('LabTestCatalog', () {
    test('fetches the lab\'s tests once, skipping rows without an id',
        () async {
      final repo = _FakeLabRepo();
      final catalog = LabTestCatalog(repo: repo);

      final tests = await catalog.fetch('lab1');
      await catalog.fetch('lab1');

      expect(tests.map((t) => t.id), ['t1']);
      expect(LabTestCatalog.cached('lab1')?.single.name, 'CBC');
      expect(repo.calls, 1);
    });

    test('an empty list never replaces a good one', () {
      LabTestCatalog.remember(
          'lab1', const [LabBookingTestOption(id: 't1', name: 'CBC')]);
      LabTestCatalog.remember('lab1', const []);

      expect(LabTestCatalog.cached('lab1'), hasLength(1));
    });
  });

  group('HospitalDoctorCatalog', () {
    test('flattens the OPD doctors out of the hospital profile', () async {
      final repo = _FakeProfileRepo();
      final catalog = HospitalDoctorCatalog(repo: repo);

      final doctors = await catalog.fetch('h1');
      await catalog.fetch('h1');

      expect(doctors.map((d) => (d.id, d.department, d.timing)),
          [('d1', 'Cardiology', '10-2')]);
      expect(HospitalDoctorCatalog.cachedIds, ['h1']);
      expect(repo.calls, 1);
    });

    test('an empty list never replaces a good one', () {
      HospitalDoctorCatalog.remember('h1',
          const [HospitalAppointmentDoctorOption(id: 'd1', name: 'Dr. Rao')]);
      HospitalDoctorCatalog.remember('h1', const []);

      expect(HospitalDoctorCatalog.cached('h1'), hasLength(1));
    });
  });

  group('HotelRoomCatalog', () {
    test('keeps only active rooms with an id', () async {
      final rooms = await HotelRoomCatalog(repo: _FakeDiscoverRepo()).fetch(
          const HotelBookingListing(
              hotelId: 'hotel1',
              ownerId: 'owner1',
              ownerName: 'Asha',
              hotelName: 'Sea View'));

      expect(rooms.map((r) => (r.id, r.name)), [('r1', 'Deluxe')]);
    });

    test('an empty list forgets the hotel', () {
      HotelRoomCatalog.remember('hotel1', const [
        HotelBookingRoomOption(id: 'r1', name: 'Deluxe', type: 'deluxe')
      ]);
      HotelRoomCatalog.remember('hotel1', const []);

      expect(HotelRoomCatalog.cached('hotel1'), isNull);
    });
  });
}
