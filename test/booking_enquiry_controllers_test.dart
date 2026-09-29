import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/controller/appointment_booking_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/controller/send_enquiry_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/model/appointment_booking_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/repo/booking_repo.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

ResponseModel _ok(Map<String, dynamic> data, {int status = 200}) =>
    ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(), statusCode: status, data: data),
    );

/// A channel open on Mondays 10:00–12:00 in 45-minute appointments, and a
/// record of what was posted.
class _FakeBookingRepo extends BookingRepo {
  Map<String, dynamic>? posted;

  @override
  Future<ResponseModel> getavailableCalender(
          {required String channelId,
          required Map<String, dynamic> params}) async =>
      _ok({
        'success': true,
        'data': ['2026-10-05', 'not a date'],
        'fee': 300,
      });

  @override
  Future<ResponseModel> getUserAvailability(
          {required String id,
          required Map<String, dynamic> queryParams}) async =>
      _ok({
        'success': true,
        'data': {
          'fee': 500,
          'durationInMinutes': 45,
          'schedule': [
            {
              'day': 'monday',
              'isOpen': true,
              'timeSlots': [
                {'startTime': '10:00', 'endTime': '12:00'}
              ],
            },
            {'day': 'tuesday', 'isOpen': false, 'timeSlots': []},
          ],
        },
      });

  @override
  Future<ResponseModel> postAppointment(
      {Map<String, dynamic>? bodyRequest}) async {
    posted = bodyRequest;
    return _ok({'message': 'Booked'});
  }

  @override
  Future<ResponseModel> postEnquiry({Map<String, dynamic>? bodyRequest}) async {
    posted = bodyRequest;
    return _ok({'message': 'Sent'});
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('AppointmentBookingController', () {
    test('loads open dates, the fee and the day\'s slots', () async {
      final c = Get.put(AppointmentBookingController(
          repo: _FakeBookingRepo(), channelId: 'ch1', videoId: 'v1'));
      await _settle();

      expect(c.isAvailabilitySet, isTrue);
      expect(c.availableDates, [DateTime(2026, 10, 5)]);
      expect(c.charges.value, '500');
      expect(c.isLoadingCalendar.value, isFalse);

      // 2026-10-05 is a Monday; 10:00–12:00 fits two 45-minute slots.
      expect(c.getAvailableTimeSlotsForDate(DateTime(2026, 10, 5)),
          ['10:00 - 10:45', '10:45 - 11:30']);
      expect(c.getAvailableTimeSlotsForDate(DateTime(2026, 10, 6)), isEmpty);
    });

    test('books for the channel and video it was opened for', () async {
      final repo = _FakeBookingRepo();
      final c = Get.put(AppointmentBookingController(
          repo: repo, channelId: 'ch1', videoId: 'v1'));
      final at = DateTime(2026, 10, 5, 10);

      final booked = await c.book(
          at: at,
          customer: CustomerDetails(
              name: 'Asha', mobileNumber: '9999999999', email: 'a@b.c'));

      expect(booked, isTrue);
      expect(repo.posted?[ApiKeys.serviceProvider_channelId], 'ch1');
      expect(repo.posted?[ApiKeys.videoId], 'v1');
      expect(repo.posted?[ApiKeys.bookingTime], '$at');
      expect(c.isBooking.value, isFalse);
    });
  });

  test('SendEnquiryController sends the enquiry for its channel and video',
      () async {
    final repo = _FakeBookingRepo();
    final c = Get.put(SendEnquiryController(
        repo: repo, channelId: 'ch1', videoId: 'v1'));

    final sent = await c.send(
        name: 'Asha', email: 'a@b.c', mobile: '9999999999', message: 'Hi');

    expect(sent, isTrue);
    expect(repo.posted?[ApiKeys.serviceProvider_channelId], 'ch1');
    expect(repo.posted?[ApiKeys.message], 'Hi');
    expect(repo.posted?[ApiKeys.user_name], 'Asha');
  });
}
