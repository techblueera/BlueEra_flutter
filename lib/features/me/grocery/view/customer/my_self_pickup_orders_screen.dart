import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/theme/order_design_tokens.dart';
import 'package:BlueEra/features/chat/view/order_track/order_steps_screen.dart';
import 'package:BlueEra/features/me/grocery/service/grocery_order_local_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// **The order list the backend does not have** (§7).
///
/// Placing a grocery self-pickup order creates no chat thread, no order card,
/// and no server-side list for either party. The one thing that works is
/// `GET /track` — and only with an id. So this screen lists the ids this
/// device wrote down at checkout ([GroceryOrderLocalStore]) and opens each
/// one's real, server-driven detail screen.
///
/// It shows **no order state of its own**. Every row is a pointer plus the
/// text the checkout knew; the status, the steps and the money all come from
/// `/track` on the screen this opens. A list that cached statuses would be
/// wrong the moment the shop touched the order, and nothing would tell it.
class MySelfPickupOrdersScreen extends StatefulWidget {
  const MySelfPickupOrdersScreen({super.key});

  @override
  State<MySelfPickupOrdersScreen> createState() =>
      _MySelfPickupOrdersScreenState();
}

class _MySelfPickupOrdersScreenState extends State<MySelfPickupOrdersScreen> {
  List<LocalOrderRef> _refs = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final refs = await GroceryOrderLocalStore.all();
    if (!mounted) return;
    setState(() {
      _refs = refs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.mainTextColor),
        title: Text(
          'My orders',
          style: OrderType.title.copyWith(color: AppColors.mainTextColor),
        ),
      ),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(OrderSpace.l),
              child: OrderCardSkeleton(lines: 6),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: _refs.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25),
                        _empty(),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(OrderSpace.l),
                      itemCount: _refs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: OrderSpace.m),
                      itemBuilder: (_, i) => _row(_refs[i]),
                    ),
            ),
    );
  }

  Widget _empty() => Column(
        children: [
          const Icon(Icons.receipt_long_outlined,
              size: 40, color: AppColors.grayText),
          const SizedBox(height: OrderSpace.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OrderSpace.xl),
            child: Text(
              'Orders you place from this device show up here.',
              textAlign: TextAlign.center,
              style: OrderType.body.copyWith(color: AppColors.grayText),
            ),
          ),
        ],
      );

  Widget _row(LocalOrderRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(OrderRadius.card),
      onTap: () => _open(ref),
      child: Container(
        padding: const EdgeInsets.all(OrderSpace.l),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(OrderRadius.card),
          border: Border.all(color: AppColors.greyE5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (ref.businessName ?? '').isNotEmpty
                        ? ref.businessName!
                        : AppStrings.orderCardNewOrder.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OrderType.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.mainTextColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if ((ref.orderNumber ?? '').isNotEmpty) ref.orderNumber!,
                      DateFormat('d MMM, h:mm a').format(ref.placedAt),
                      if (ref.itemCount != null) '${ref.itemCount} items',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OrderType.label.copyWith(color: AppColors.grayText),
                  ),
                ],
              ),
            ),
            if (ref.grandTotal != null)
              Padding(
                padding: const EdgeInsets.only(right: OrderSpace.s),
                child: Text(
                  '₹${OrderMoneyRow.money(ref.grandTotal!)}',
                  style: OrderType.mono(size: 14, weight: FontWeight.w700)
                      .copyWith(color: AppColors.mainTextColor),
                ),
              ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.grayText),
          ],
        ),
      ),
    );
  }

  Future<void> _open(LocalOrderRef ref) async {
    final result = await Get.to(() => OrderStepsScreen(
          args: OrderStepsArgs(
            orderId: ref.orderId,
            service: ref.service,
            isOwner: ref.isOwner,
          ),
        ));
    // S14 — `/track` 404'd: the order is gone, so the pointer to it goes too.
    // Keeping a row that can only ever open an error is worse than one fewer
    // row.
    if (result == OrderStepsResult.gone) {
      await GroceryOrderLocalStore.forget(ref.orderId);
    }
    await _load();
  }
}
