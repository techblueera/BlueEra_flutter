import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/self_employed/view/self_employee_order_card.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

class SelfEmployeeNewOrders extends StatefulWidget {
  const SelfEmployeeNewOrders({super.key});

  @override
  State<SelfEmployeeNewOrders> createState() => _SelfEmployeeNewOrdersState();
}

class _SelfEmployeeNewOrdersState extends State<SelfEmployeeNewOrders> {
  // final controller = getOrPut(() => DeliverPartnerOrdersController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildOrderList(),
    );
  }

  Widget _buildOrderList() {
    final mockOrder = [
      // 🔹 NEW ORDER
      OrderModel(
        id: '1',
        orderNo: 'ORD123456',
        createdAt: DateTime.now().toIso8601String(),
        fare: '120',
        pickupOTP: '4321',
        deliveryOTP: '9876',
        status: 'new', // New
        user: UserModel(
          name: 'Rahul Sharma',
          profileImage: 'https://picsum.photos/200',
          contactNo: '9876543210',
        ),
      ),

      // 🔸 ONGOING ORDER
      OrderModel(
        id: '2',
        orderNo: 'ORD123457',
        createdAt: DateTime.now().toIso8601String(),
        fare: '150',
        pickupOTP: '1234',
        deliveryOTP: '5678',
        status: 'ongoing', // Ongoing
        user: UserModel(
          name: 'Amit Verma',
          profileImage: 'https://picsum.photos/300',
          contactNo: '9654236556',
        ),
      ),

      // 🔸 ONGOING ORDER
      OrderModel(
        id: '3',
        orderNo: 'ORD123458',
        createdAt: DateTime.now().toIso8601String(),
        fare: '200',
        pickupOTP: '6789',
        deliveryOTP: '4321',
        status: 'ongoing', // Ongoing
        user: UserModel(
          name: 'Neha Singh',
          profileImage: 'https://picsum.photos/400',
          contactNo: '9123456789',
        ),
      ),
    ];

    final newOrders =
    mockOrder.where((o) => o.status.toLowerCase() == 'new').toList();

    final ongoingOrders =
    mockOrder.where((o) => o.status.toLowerCase() == 'ongoing').toList();

    return
      mockOrder.isEmpty
          ? Center(
        child: CustomText(AppStrings.noOrdersFound),
      )
          : ListView.builder(
        padding: EdgeInsets.only(
          bottom: 2 * kBottomNavigationBarHeight + SizeConfig.size40,
          left: SizeConfig.size15,
          right: SizeConfig.size15,
        ),
        itemCount: ongoingOrders.length +
            (newOrders.isNotEmpty ? newOrders.length + 1 : 0),
        itemBuilder: (context, index) {

          /// 1️⃣ OnGoing Orders
          if (index < ongoingOrders.length) {
            return SelfEmployeeOrderCard(
              selectedOrdersStatus: EarnServiceOrdersStatus.newAndOnGoingOrder,
              order: ongoingOrders[index],
            );
          }

          /// 2️⃣ Upcoming Header
          if (newOrders.isNotEmpty && index == ongoingOrders.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: CustomText(
                'Next Up-Coming ',
                fontSize: SizeConfig.large,
                fontWeight: FontWeight.w600,
                color: AppColors.mainTextColor,
              ),
            );
          }

          /// 3️⃣ New Orders list
          final newIndex =
              index - ongoingOrders.length - 1;

          return SelfEmployeeOrderCard(
            selectedOrdersStatus: EarnServiceOrdersStatus.newAndOnGoingOrder,
            order: newOrders[newIndex],
          );
        },
      );
  }

}
