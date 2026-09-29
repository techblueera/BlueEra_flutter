import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/business/auth/controller/view_business_details_controller.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_package_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_test_controller.dart';
import 'package:BlueEra/features/me/laboratory/controller/visited_lab_controller.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_full_details_repo.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_package_repo.dart';
import 'package:BlueEra/features/me/laboratory/repo/lab_test_repo.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

ResponseModel _ok(Map<String, dynamic> data) => ResponseModel(
      statusCode: 200,
      response: Response(
          requestOptions: RequestOptions(), statusCode: 200, data: data),
    );

/// The visited business resolves to user `u1`.
class _FakeBusinessDetails extends ViewBusinessDetailsController {
  final visited = <String>[];

  @override
  Future<void> viewBusinessProfileById(String userId,
      {bool silent = false}) async {
    visited.add(userId);
    visitedBusinessProfileDetails = ViewBusinessProfileModel.fromJson({
      'data': {'user_id': 'u1'},
    });
  }
}

class _FakeFullDetailsRepo extends LabFullDetailsRepo {
  String? askedFor;

  @override
  Future<ResponseModel> getFullDetailsByUserId(String targetUserId) async {
    askedFor = targetUserId;
    return _ok({
      'data': {
        'profile': {'_id': 'lab-profile-1'}
      }
    });
  }
}

class _FakeTestRepo extends LabTestRepo {
  String? askedFor;

  @override
  Future<ResponseModel> getPathologyTestsByLab(
      String labId, String collection) async {
    askedFor = labId;
    return _ok({
      'data': [
        {'_id': 't1', 'testName': 'CBC'},
        {'_id': 't2', 'testName': 'Lipid profile'},
      ]
    });
  }
}

class _FakePackageRepo extends LabPackageRepo {
  @override
  Future<ResponseModel> getPackagesByLab(String labId) async =>
      _ok({'data': []});
}

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('the owner\'s lab controllers are shared, permanent instances', () {
    expect(LabTestController.to, same(LabTestController.to));
    expect(LabPackageController.to, same(LabPackageController.to));

    // A route-scoped cleanup (non-forced delete) must not take them away.
    Get.delete<LabPackageController>();
    expect(Get.isRegistered<LabPackageController>(), isTrue);
  });

  test('a visited lab loads its tests by the lab profile id', () async {
    final business = _FakeBusinessDetails();
    final fullDetails = _FakeFullDetailsRepo();
    final tests = _FakeTestRepo();
    final c = Get.put(
      VisitedLabController(
        businessId: 'biz-1',
        businessDetails: business,
        testRepo: tests,
        packageRepo: _FakePackageRepo(),
        fullDetailsRepo: fullDetails,
      ),
      tag: 'biz-1',
    );
    await _settle();

    expect(business.visited, ['biz-1']);
    expect(fullDetails.askedFor, 'u1');
    expect(tests.askedFor, 'lab-profile-1');
    expect(c.laboratoryId, 'lab-profile-1');
    expect(c.tests.length, 2);
    expect(c.packages, isEmpty);
    expect(c.isLoading.value, isFalse);
    // The owner's shared list is untouched.
    expect(Get.isRegistered<LabTestController>(), isFalse);
  });
}
