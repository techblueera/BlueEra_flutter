import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:get/get.dart';

class DeliverPartnerOrdersController extends GetxController{
  final List<DeliveryPartnerOrdersTab> deliveryPartnerOrdersTabs = DeliveryPartnerOrdersTab.values;
  RxInt selectedDeliveryPartnerOrderIndex = 0.obs;

  final List<PickUpTab> pickUpTabs = PickUpTab.values;
  Rx<PickUpTab> selectedPickUp = PickUpTab.newOrder.obs;

}