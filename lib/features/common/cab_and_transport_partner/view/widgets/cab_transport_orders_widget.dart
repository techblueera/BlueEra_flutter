
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_orders_controller.dart';
import 'package:BlueEra/features/common/delivery_partner/view/delivery_partner_orders/pickup_order_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class CabsAndTransportPartnerOrders extends StatefulWidget {
  /// When true, this widget is being embedded inside a parent
  /// [CustomScrollView] (e.g. the cab/transport partner tab body) and
  /// should NOT introduce its own [Scaffold]/[Expanded] chrome — the
  /// inner [PickupOrderScreen] will run in shrink-wrap mode so the
  /// parent owns the scroll. Defaults to `false` for standalone use.
  final bool isInParentScroll;

  const CabsAndTransportPartnerOrders({super.key, this.isInParentScroll = false});

  @override
  State<CabsAndTransportPartnerOrders> createState() => _CabsAndTransportPartnerOrdersState();
}

class _CabsAndTransportPartnerOrdersState extends State<CabsAndTransportPartnerOrders> {
  final controller = getOrPut(() => DeliverPartnerOrdersController());
  final deliveryPartnerController = getOrPut(() => DeliveryPartnerController());

  @override
  void initState() {
    controller.fetchStream();
    super.initState();
  }

  @override
  void dispose() {
    controller.subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The legacy L3 category filter (Pickup / Grocery / Parcel /
    // Income) was retired — Grocery/Parcel/Income screens never
    // shipped, so the wrapper always resolved to PickupOrderScreen.
    // We now render it directly; pickup's own per-status filter
    // (orders/new/ongoing/completed/cancel/rejected) lives inside
    // that screen as a bottom-sheet picker.
    return PickupOrderScreen(
      isInParentScroll: widget.isInParentScroll,
    );
  }

  void showStatusDialog(BuildContext context, String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: CustomText(title),
          content: CustomText(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: CustomText(AppStrings.ok),
            ),
          ],
        ),
      );
    });
  }
}
