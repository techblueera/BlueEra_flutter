import 'dart:async';
import 'dart:convert';
import 'dart:developer';


import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/api/apiService/response_model.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../chat/auth/model/rider_orders_details_model.dart';
import '../../../chat/auth/repo/make_order_repo.dart';
import '../../../chat/auth/stream/get_orders_stream.dart';

class DeliverPartnerOrdersController extends GetxController {
  final List<DeliveryPartnerOrdersTab> deliveryPartnerOrdersTabs =
      DeliveryPartnerOrdersTab.values;
  RxInt selectedDeliveryPartnerOrderIndex = 0.obs;

  final List<PickUpTab> pickUpTabs = PickUpTab.values;
  Rx<PickUpTab> selectedPickUp = PickUpTab.newOrder.obs;
  RxList<RiderOrdersDetailsModel> riderOrdersList =
      <RiderOrdersDetailsModel>[].obs;
  Rx<ApiResponse> ordersListResponse = ApiResponse.initial('Initial').obs;// Declare your RxLists
  RxList<RiderOrdersDetailsModel> riderOrdersDetailsModel = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> completedOrders = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> cancelledOrders = <RiderOrdersDetailsModel>[].obs;
  RxList<RiderOrdersDetailsModel> rejectedOrders = <RiderOrdersDetailsModel>[].obs;

  late Stream<dynamic> stream;
  StreamSubscription? subscription;

  Future<void> fetchStream() async {
    stream = await getOrderFromUserStream();

    subscription = stream.listen((event) {
      if (event is List) {
        riderOrdersList.value = event
            .map((item) => RiderOrdersDetailsModel.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList();

        ordersListResponse.value = ApiResponse.complete(riderOrdersList);
      } else {
        ordersListResponse.value =
            ApiResponse.error(AppStrings.somethingWentWrong);
      }
    }, onError: (error) {
      ordersListResponse.value =
          ApiResponse.error(AppStrings.somethingWentWrong);
    }, onDone: () {});
  }

  Future<void> updateOrderStatusFromPialot(Map<String,dynamic> params,String orderId) async {
    try {
      ResponseModel? response = await MakeOrderRepo().updateOrderStatusFromPt(params,orderId);
      if (response.isSuccess ) {
        commonSnackBar(
            message: response.message ?? "Order Status Updated Successfully");
      } else {
        commonSnackBar(
            message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
  Future<void> getRidersBookingOrders() async {
    try {
      ordersListResponse.value=ApiResponse.initial('initial');
      ResponseModel? response = await MakeOrderRepo().getRidersBookingOrders();
      if (response.isSuccess ) {

        if (response.response?.data is List) {
          final parsedList = (response.response?.data as List)
              .map((item) => RiderOrdersDetailsModel.fromJson(
            Map<String, dynamic>.from(item),
          ))
              .toList();

          riderOrdersDetailsModel.value = parsedList;

        
          completedOrders.value =
              parsedList.where((e) => e.status?.toLowerCase() == 'completed').toList();

          cancelledOrders.value =
              parsedList.where((e) => e.status?.toLowerCase() == 'cancelled').toList();

          rejectedOrders.value =
              parsedList.where((e) => e.status?.toLowerCase() == 'rejected').toList();
          ordersListResponse.value=ApiResponse.complete();
        }else{
          ordersListResponse.value=ApiResponse.error();

        }

      } else {
        ordersListResponse.value=ApiResponse.error();

        commonSnackBar(
          message: response.message ?? AppStrings.somethingWentWrong,
        );
      }

    } catch (e) {
      ordersListResponse.value=ApiResponse.error();
      commonSnackBar(message: AppStrings.somethingWentWrong);
    }
  }
}
