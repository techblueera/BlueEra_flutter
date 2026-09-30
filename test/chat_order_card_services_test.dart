import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/chat/auth/service/rider_association_service.dart';
import 'package:BlueEra/features/chat/auth/service/self_pickup_ready_service.dart';
import 'package:BlueEra/features/common/delivery_partner/repo/delivery_partner_repo.dart';
import 'package:BlueEra/features/me/food/repo/food_repo.dart';
import 'package:BlueEra/features/me/grocery/repo/grocery_repo.dart';
import 'package:BlueEra/features/me/medical/repo/medical_repo.dart';
import 'package:BlueEra/features/me/product/repo/product_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/view/earn_with_blueera/repo/earn_profile_repo.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

ResponseModel _res(int status) => ResponseModel(
      statusCode: status,
      response: Response(
          requestOptions: RequestOptions(),
          statusCode: status,
          data: {'message': 'Already ready'}),
    );

/// Every mark-ready call lands here, tagged with the service it went to.
final List<String> _calls = [];

class _Grocery extends GroceryRepo {
  @override
  Future<ResponseModel> markSelfPickupOrderReadyRepo(
      {required String orderId}) async {
    _calls.add('grocery:$orderId');
    return _res(200);
  }
}

class _Food extends FoodRepo {
  @override
  Future<ResponseModel> markFoodOrderReadyRepo(
      {required String orderId}) async {
    _calls.add('food:$orderId');
    return _res(200);
  }
}

class _Earn extends EarnProfileRepo {
  @override
  Future<ResponseModel> markHomeFoodOrderReadyRepo(
      {required String orderId}) async {
    _calls.add('homeMade:$orderId');
    return _res(200);
  }

  @override
  Future<ResponseModel> markTiffinOrderReadyRepo(
      {required String orderId}) async {
    _calls.add('tiffin:$orderId');
    return _res(200);
  }
}

class _Product extends ProductRepo {
  @override
  Future<ResponseModel> markProductOrderReadyRepo(
      {required String orderId}) async {
    _calls.add('product:$orderId');
    return _res(200);
  }
}

class _Medical extends MedicalRepo {
  @override
  Future<ResponseModel> markMedicalOrderReadyRepo(
      {required String orderId}) async {
    _calls.add('medical:$orderId');
    return _res(409);
  }
}

class _Rider extends DeliveryPartnerRepo {
  _Rider(this.status);

  final int status;
  final List<String> sent = [];

  @override
  Future<ResponseModel> respondToAssociationRepo(
      {required String associationId,
      required String action,
      String? reason}) async {
    sent.add('$associationId:$action');
    return _res(status);
  }
}

void main() {
  setUp(() {
    Get.reset();
    _calls.clear();
  });
  tearDown(Get.reset);

  test('each kind of self-pickup order is marked ready on its own service',
      () async {
    final service = SelfPickupReadyService(
      groceryRepo: _Grocery(),
      foodRepo: _Food(),
      earnRepo: _Earn(),
      productRepo: _Product(),
      medicalRepo: _Medical(),
    );

    for (final kind in SelfPickupOrderKind.values) {
      await service.markReady(kind, 'o1');
    }

    expect(_calls, [
      'grocery:o1',
      'food:o1',
      'homeMade:o1',
      'tiffin:o1',
      'product:o1',
      'medical:o1',
    ]);
  });

  test('mark ready returns null on success and the message on refusal',
      () async {
    final service = SelfPickupReadyService(
        productRepo: _Product(), medicalRepo: _Medical());

    expect(await service.markReady(SelfPickupOrderKind.product, 'o1'), isNull);
    expect(await service.markReady(SelfPickupOrderKind.medical, 'o1'),
        'Already ready');
  });

  Messages association(String? id) => Messages(
        metadata: MessageMetadata(
          riderAssociation:
              RiderAssociationMetadata(associationId: id, status: 'pending'),
        ),
      );

  test('answering an association records the new status on the message',
      () async {
    final repo = _Rider(200);
    final message = association('a1');

    expect(await RiderAssociationService(repo: repo).respond(message, 'accept'),
        'accepted');
    expect(repo.sent, ['a1:accept']);
    expect(message.metadata!.riderAssociation!.status, 'accepted');
  });

  test('a refused or id-less answer changes nothing', () async {
    final refused = association('a1');
    expect(
        await RiderAssociationService(repo: _Rider(500))
            .respond(refused, 'reject'),
        isNull);
    expect(refused.metadata!.riderAssociation!.status, 'pending');

    final repo = _Rider(200);
    expect(
        await RiderAssociationService(repo: repo)
            .respond(association(null), 'accept'),
        isNull);
    expect(repo.sent, isEmpty);
  });
}
