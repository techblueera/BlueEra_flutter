import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/business_service/model/get_service_model.dart';
import 'package:BlueEra/features/common/business_service/view/service_details_view_screen.dart';
import 'package:BlueEra/features/common/food/view/widget/km_away_text_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ServiceCardBusiness extends StatefulWidget {
  final GetServiceModel serviceData;
  final bool isGridView;
  final bool isShowChat;
  final bool isFromChatCard;

  final bool isShowKM;
  final bool isShowBusinessInfo;
  final BusinessProfileDetails? businessData;

  const ServiceCardBusiness({
    Key? key,
    required this.serviceData,
    this.isGridView = false,
    this.isShowChat = true,
    this.isFromChatCard= false,
    this.isShowKM = false,
    this.isShowBusinessInfo = false,
    this.businessData,
  }) : super(key: key);

  @override
  State<ServiceCardBusiness> createState() => _ServiceCardBusinessState();
}

class _ServiceCardBusinessState extends State<ServiceCardBusiness> {
  final chatViewController = Get.find<ChatViewController>();

  GetServiceModel? serviceData;

  // var kmAway;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    serviceData = widget.serviceData;
  }

  @override
  Widget build(BuildContext context) {
    // Find max discount
    Discounts? maxDiscount;
    if ((serviceData?.discounts?.length ?? 0) > 0)
      maxDiscount = serviceData?.discounts
          ?.reduce((a, b) => (a.amountOff ?? 0) > (b.amountOff ?? 0) ? a : b);

    return InkWell(
      onTap: () {
        if(widget.isFromChatCard==false){
          Get.to(ServiceDetailsScreen(
            service: serviceData ?? GetServiceModel(),
          ));
        }

      },
      child: Container(
        margin: EdgeInsets.only(right: 20),
        width: MediaQuery.of(context).size.width * 0.45,
        // responsive width
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: CustomImageSlideshow(
                isLoading: false,
                width: double.infinity,
                height: 170,
                imagePaths: serviceData?.photos ?? [],
                borderRadius: BorderRadius.zero,
              ),
            ),

            SizedBox(height: SizeConfig.size5),

            // Title & price
            Container(
              height: SizeConfig.size20,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                serviceData?.title ?? "N/A",
                fontSize: SizeConfig.small,
                fontWeight: FontWeight.w500,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            SizedBox(height: SizeConfig.size5),
            Container(
              // height: SizeConfig.size20,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                serviceData?.business?.categoryOfBusiness?.name ?? "N/A",
                fontSize: SizeConfig.small,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),

            SizedBox(height: SizeConfig.size5),
            Container(
              // height: SizeConfig.size20,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                serviceData?.business?.businessName ?? "N/A",
                fontSize: SizeConfig.small,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            SizedBox(height: SizeConfig.size5),
            Container(
              // alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.green, borderRadius: BorderRadius.circular(30)),
              child: CustomText(
                (maxDiscount?.amountOff != null)
                    ? "${maxDiscount?.amountOff.toString()}% Off"
                    : "0% Off",
                fontSize: SizeConfig.size10,
                color: Colors.white,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: SizeConfig.size5),
            KmAwayTextWidget(
                lat: serviceData?.business?.businessLocation?.lat.toString() ??
                    "",
                long:
                    serviceData?.business?.businessLocation?.lon?.toString() ??
                        ""),

            SizedBox(height: SizeConfig.size5),
          ],
        ),
      ),
    );
  }
}
