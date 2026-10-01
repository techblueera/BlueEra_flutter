import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/Discover/controller/finance_discover_controller.dart';
import 'package:dio/dio.dart' show CancelToken, RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

/// Answers each business's `/full` request only when the test says so, so a
/// test can make the first business's response land after the second one
/// was opened.
class _ControlledApi extends ApiBaseHelper {
  final pending = <String, Completer<ResponseModel>>{};

  @override
  Future<ResponseModel> getHTTP(
    String url, {
    dynamic params,
    bool showProgress = true,
    bool throwOnError = false,
    Function(ResponseModel res)? onSuccess,
    Function(DioExceptions dioExceptions)? onError,
    CancelToken? cancelToken,
  }) {
    final id = RegExp(r'business-profile/([^/]+)/full').firstMatch(url)!.group(1)!;
    return (pending[id] = Completer<ResponseModel>()).future;
  }

  void answer(String id) => pending[id]!.complete(ResponseModel(
        statusCode: 200,
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 200,
          data: {
            'data': {'_id': id},
          },
        ),
      ));

  void fail(String id) => pending[id]!.complete(ResponseModel(
        statusCode: 500,
        response: Response(requestOptions: RequestOptions(), statusCode: 500),
      ));
}

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  test("a late response for the business the user left doesn't replace this one",
      () async {
    final api = _ControlledApi();
    final c = FinanceDiscoverController(api: api);

    final first = c.fetchDetail('bank-a');
    final second = c.fetchDetail('bank-b');

    api.answer('bank-b');
    await second;
    api.answer('bank-a'); // the slow one, arriving last
    await first;

    expect(c.selectedDetail.value?.id, 'bank-b');
    expect(c.isDetailLoading.value, isFalse);
  });

  test("a superseded call doesn't end the newer one's loading or set its error",
      () async {
    final api = _ControlledApi();
    final c = FinanceDiscoverController(api: api);

    final first = c.fetchDetail('bank-a');
    final second = c.fetchDetail('bank-b');

    api.fail('bank-a'); // the old call finishes first, and badly
    await first;

    expect(c.isDetailLoading.value, isTrue, reason: 'bank-b still loading');
    expect(c.detailError.value, isEmpty);

    api.answer('bank-b');
    await second;
    expect(c.selectedDetail.value?.id, 'bank-b');
    expect(c.isDetailLoading.value, isFalse);
  });
}
