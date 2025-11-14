import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/controller/rental_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/rental/view/rental_card.dart';
import 'package:BlueEra/widgets/horizontal_tab_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({super.key});

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen> {
  final controller = Get.put(RentalController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     body: Obx(()=> Column(
       children: [
         Padding(
           padding: EdgeInsets.all(SizeConfig.size15),
           child: HorizontalTabSelector(
             tabs: controller.rentalTabs,
             selectedIndex: controller.selectedRentalIndex.value,
             onTabSelected: (index, value) {
               if (mounted) {
                 controller.selectedRentalIndex.value = index;
               }
             },
             labelBuilder: (value) => value.label,
           ),
         ),

         Expanded(
           child: Builder(
             builder: (context) {
               switch (controller.selectedRentalIndex.value) {
                 case 0:
                   return RentalCard();
                 case 1:
                   return RentalCard();
                   case 2:
                 return RentalCard();
                 default:
                   return SizedBox.shrink(); // fallback
               }
             },
           ),
         ),
       ],
     )),
    );
  }
}
