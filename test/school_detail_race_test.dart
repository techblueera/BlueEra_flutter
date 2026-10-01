import 'dart:async';

import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/api/model/school_details_res_model.dart';
import 'package:BlueEra/features/me/school/controller/school_about_us_controller.dart';
import 'package:BlueEra/features/me/school/repo/school_repo.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

ResponseModel _ok(Object data) => ResponseModel(
      statusCode: 200,
      response: Response(
          requestOptions: RequestOptions(), statusCode: 200, data: data),
    );

/// The school-by-id and courses calls answer only when the test says so; the
/// other sub-fetches the main load triggers never answer (they're not what
/// these tests are about).
class _ControlledSchoolRepo extends SchoolRepo {
  final byId = <String, Completer<ResponseModel>>{};
  final courses = <String, Completer<ResponseModel>>{};

  @override
  Future<ResponseModel> getSchoolByIDRepo({String? schoolID}) =>
      (byId[schoolID!] = Completer<ResponseModel>()).future;

  @override
  Future<ResponseModel> getSchoolCoursesRepo({required String schoolID}) =>
      (courses[schoolID] = Completer<ResponseModel>()).future;

  @override
  Future<ResponseModel> getSchoolAboutUsRepo({String? schoolID}) =>
      Completer<ResponseModel>().future;
  @override
  Future<ResponseModel> getSchoolBranchRepo({required String schoolID}) =>
      Completer<ResponseModel>().future;
  @override
  Future<ResponseModel> getAllCampusLifeRepo({String? schoolID}) =>
      Completer<ResponseModel>().future;
  @override
  Future<ResponseModel> getSchoolQuickInfoRepo({String? schoolID}) =>
      Completer<ResponseModel>().future;

  void answerSchool(String id, String name) => byId[id]!.complete(_ok({
        'success': true,
        'data': {'_id': id, 'name': name},
      }));

  void answerCourses(String id, int count) => courses[id]!.complete(_ok({
        'data': [for (var i = 0; i < count; i++) <String, dynamic>{}],
      }));
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test("a late response for the school the user left doesn't replace this one",
      () async {
    final repo = _ControlledSchoolRepo();
    final c = SchoolAboutUsController(repo: repo);

    final first = c.getSchoolByIdController(schoolID: 'school-a');
    final second = c.getSchoolByIdController(schoolID: 'school-b');

    repo.answerSchool('school-b', 'School B');
    await second;
    repo.answerSchool('school-a', 'School A'); // the slow one, arriving last
    await first;

    expect(c.schoolDetailsData?.value.id, 'school-b');
    expect(c.schoolDetailsData?.value.name, 'School B');
  });

  test("a late sub-fetch for the school the user left doesn't write into this one",
      () async {
    final repo = _ControlledSchoolRepo();
    final c = SchoolAboutUsController(repo: repo);
    c.schoolDetailsData?.value = SchoolDetailsData(id: 'school-b', name: 'B');

    final lateCourses = c.getSchoolCoursesController(schoolID: 'school-a');
    repo.answerCourses('school-a', 3);
    await lateCourses;

    expect(c.schoolDetailsData?.value.courses, isNull);
  });

  test("the current school's sub-fetch still lands", () async {
    final repo = _ControlledSchoolRepo();
    final c = SchoolAboutUsController(repo: repo);
    c.schoolDetailsData?.value = SchoolDetailsData(id: 'school-b', name: 'B');

    final load = c.getSchoolCoursesController(schoolID: 'school-b');
    repo.answerCourses('school-b', 2);
    await load;

    expect(c.schoolDetailsData?.value.courses, hasLength(2));
  });
}
