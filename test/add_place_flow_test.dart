import 'dart:convert';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/add_place_req_model.dart';
import 'package:BlueEra/features/common/map/binding/add_place_binding.dart';
import 'package:BlueEra/features/common/map/controller/add_place_step_one_controller.dart';
import 'package:BlueEra/features/common/map/controller/add_place_step_two_controller.dart';
import 'package:BlueEra/features/common/map/controller/visiting_hour_selector_controller.dart';
import 'package:BlueEra/features/common/map/repo/add_place_repo.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

/// Records the submitted place and answers with [statusCode].
class _FakeAddPlaceRepo extends AddPlaceRepo {
  _FakeAddPlaceRepo({this.statusCode = 200});

  final int statusCode;
  AddPlaceReqModel? submitted;

  @override
  Future<ResponseModel> addPlacePost(
      {required AddPlaceReqModel placeReq}) async {
    submitted = placeReq;
    return ResponseModel(
      statusCode: statusCode,
      response: Response(
        requestOptions: RequestOptions(),
        statusCode: statusCode,
        data: {'message': 'nope'},
      ),
    );
  }
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test('each flow starts with fresh step and visiting-hours controllers', () {
    AddPlaceBinding().dependencies();
    Get.find<AddPlaceStepTwoController>().emailController.text = 'a@b.c';
    Get.find<VisitingHoursSelectorController>()
        .toggleDayStatus('Monday', true);

    AddPlaceBinding().dependencies();

    expect(Get.find<AddPlaceStepTwoController>().emailController.text, isEmpty);
    expect(Get.find<VisitingHoursSelectorController>().visitingHours['Monday'],
        isFalse);
  });

  test('submitting sends step one\'s place with the open days', () async {
    final stepOne = Get.put(AddPlaceStepOneController());
    final hours = Get.put(VisitingHoursSelectorController());
    final repo = _FakeAddPlaceRepo();
    final stepTwo = Get.put(AddPlaceStepTwoController(
        repo: repo, stepOne: stepOne, visitingHours: hours));

    stepOne.placesController.text = 'City Park';
    stepOne.lat.value = '12.9';
    stepOne.long.value = '77.6';
    hours.toggleDayStatus('Sunday', true);
    hours.updateStartTime('Sunday', const TimeOfDay(hour: 9, minute: 0));
    stepTwo.emailController.text = 'park@example.com';

    expect(await stepTwo.submitPlace(), isTrue);
    final sent = repo.submitted!;
    expect(sent.name, 'City Park');
    expect(sent.latitude, '12.9');
    expect(sent.email, 'park@example.com');
    final days = jsonDecode(sent.visitingHours!) as List;
    expect(days.map((d) => d['day']), ['Sunday']);
  });

  test('a rejected submission reports failure', () async {
    final stepOne = Get.put(AddPlaceStepOneController());
    final hours = Get.put(VisitingHoursSelectorController());
    final stepTwo = Get.put(AddPlaceStepTwoController(
        repo: _FakeAddPlaceRepo(statusCode: 400),
        stepOne: stepOne,
        visitingHours: hours));

    expect(await stepTwo.submitPlace(), isFalse);
    expect(hours.visitingHours.values.every((open) => !open), isTrue);
  });
}
