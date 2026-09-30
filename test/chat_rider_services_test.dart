import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/chat/auth/repo/chat_view_repo.dart';
import 'package:BlueEra/features/chat/auth/repo/make_order_repo.dart';
import 'package:BlueEra/features/chat/auth/service/order_support_service.dart';
import 'package:BlueEra/features/chat/auth/service/rider_order_service.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';

ResponseModel _res(int status, Object? data) => ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(), statusCode: status, data: data),
    );

class _FakeChatRepo extends ChatViewRepo {
  _FakeChatRepo({this.location, this.support, this.status = 200});

  final Object? location;
  final Object? support;
  final int status;

  @override
  Future<ResponseModel> getRiderLiveLocationApi(String orderId) async =>
      _res(status, location);

  @override
  Future<ResponseModel> openOrderSupportApi({
    required String orderId,
    required String reason,
    String? note,
    String? vehicleType,
    Map<String, dynamic>? ride,
  }) async =>
      _res(status, support);
}

class _FakeOrderRepo extends MakeOrderRepo {
  _FakeOrderRepo(this.status);

  final int status;
  final List<String> calls = [];

  @override
  Future<ResponseModel> uploadThePickupOtp(
      Map<String, dynamic> params, String orderId) async {
    calls.add('single:$orderId:${params['pickupOTP']}');
    return _res(status, {'message': 'Wrong OTP'});
  }

  @override
  Future<ResponseModel> multiShopStopPickupApi(
      {required String orderId,
      required String businessId,
      required String pickupOTP}) async {
    calls.add('multi:$orderId:$businessId:$pickupOTP');
    return _res(status, {'message': 'Wrong OTP'});
  }
}

void main() {
  group('RiderOrderService', () {
    test('reads the location whether or not it is wrapped in data', () async {
      final wrapped = await RiderOrderService(
          chatRepo: _FakeChatRepo(location: {
        'data': {'status': 'picked-up', 'rideActive': true}
      })).riderLocation('o1');
      final bare = await RiderOrderService(
              chatRepo: _FakeChatRepo(location: {'status': 'assigned'}))
          .riderLocation('o1');

      expect(wrapped?['status'], 'picked-up');
      expect(bare?['status'], 'assigned');
    });

    test('no location for a failed read or an empty order id', () async {
      expect(
          await RiderOrderService(chatRepo: _FakeChatRepo(status: 500))
              .riderLocation('o1'),
          isNull);
      expect(await RiderOrderService().riderLocation(''), isNull);
    });

    test('a multi-stop OTP goes to its per-shop endpoint', () async {
      final repo = _FakeOrderRepo(200);
      final service = RiderOrderService(orderRepo: repo);

      expect(await service.verifyPickupOtp(orderId: 'o1', otp: '1234'), isNull);
      expect(
          await service.verifyPickupOtp(
              orderId: 'o2', otp: '5678', businessId: 'b1', multiStop: true),
          isNull);
      expect(repo.calls, ['single:o1:1234', 'multi:o2:b1:5678']);
    });

    test('a rejected OTP carries the server message', () async {
      expect(
          await RiderOrderService(orderRepo: _FakeOrderRepo(400))
              .verifyPickupOtp(orderId: 'o1', otp: '0000'),
          'Wrong OTP');
    });
  });

  group('OrderSupportService', () {
    test('returns the thread to open', () async {
      final thread = await OrderSupportService(
          repo: _FakeChatRepo(support: {
        'conversation_id': 'c1',
        'display_name': ' Ride Support ',
      })).open(orderId: 'o1', reason: 'Driver was rude');

      expect(thread, (conversationId: 'c1', displayName: 'Ride Support'));
    });

    test('nothing to open without a conversation', () async {
      expect(
          await OrderSupportService(
                  repo: _FakeChatRepo(status: 500, support: {'message': 'x'}))
              .open(orderId: 'o1', reason: 'x'),
          isNull);
      expect(
          await OrderSupportService(repo: _FakeChatRepo(support: {}))
              .open(orderId: 'o1', reason: 'x'),
          isNull);
    });
  });
}
