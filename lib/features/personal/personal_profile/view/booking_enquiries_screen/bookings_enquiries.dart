import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/received_booking_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/received_enquiries_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/booking_enquiries_screen/set_availability_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/shared_preference_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  final List<String> options = const [
    "My Bookings",
    "Received Bookings",
    "Sent Enquiries",
    "Received Enquiries",
    "Set & Edit Availability",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: 'Bookings and Enquiries',
        isLeading: true,
      ),
      body: Padding(
        padding:  EdgeInsets.all( SizeConfig.size18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(options.length, (index) {
              return Column(
                children: [
                  SizedBox(height: SizeConfig.size8),
                  InkWell(
                    onTap: () {
                      if (options[index] == "My Bookings") {
                        Get.toNamed(RouteHelper.getMyBookingScreenRoute());
                      }else if(options[index] == "Received Bookings"){
                        Get.to(()=>ReceivedBookingsScreen(channelId: channelId,));
                      }
                      else if(options[index] == "Received Enquiries"){
                        Get.to(Get.to(()=>ReceivedEnquiriesScreen(channelId: channelId,)));
                      }
                      else if(options[index] == "Sent Enquiries"){
                        Get.toNamed(RouteHelper.getMyEnquiresRoute());
                      }
                      else if(options[index] == "Set & Edit Availability"){
                        print("channelId:$channelId");
                        Get.to(
                          ()=> 
                          SetAvailabilityScreen(id: channelId,),
                         

                        );

                      }
                    },
                    child: Padding(
                      padding:  EdgeInsets.symmetric(
                          horizontal: SizeConfig.size16, vertical: SizeConfig.size16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child:CustomText(
                          options[index],
                          fontSize: SizeConfig.large,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),

                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size8),
                  if (index != options.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Color(0xFFE0E0E0),
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
