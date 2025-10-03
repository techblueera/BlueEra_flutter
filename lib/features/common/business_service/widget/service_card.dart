import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/common/business_service/model/get_service_model.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class ServiceCardBusiness extends StatefulWidget {
  final GetServiceModel serviceData;
  final bool isGridView;
  final bool isShowChat;
  final bool isShowKM;
  final bool isShowBusinessInfo;
  final BusinessProfileDetails? businessData;

  const ServiceCardBusiness({
    Key? key,
    required this.serviceData,
    this.isGridView = false,
    this.isShowChat = true,
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    serviceData = widget.serviceData;
  }

  @override
  Widget build(BuildContext context) {
    //
    // if (widget.serviceData) {
    //   return const SizedBox();
    // }

    return InkWell(
      onTap: () {},
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
            AspectRatio(
              aspectRatio: 1.1, // square-ish image (adjust if needed)
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                    child: CustomImageSlideshow(
                      isLoading: false,
                      width: double.infinity,
                      height: double.infinity,
                      imagePaths: serviceData?.photos ?? [],
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  // if ((product.details?.media.length ?? 0) > 1)
                ],
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
              height: SizeConfig.size40,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: CustomText(
                serviceData?.description ?? "N/A",
                fontSize: SizeConfig.small,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            SizedBox(height: SizeConfig.size5),
            Container(
              // height: SizeConfig.size20,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: Row(
                children: [
                  CustomText(
                    "Start Time : ",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.bold,
                    maxLines: 1,
                  ),
                  Flexible(
                    child: CustomText(
                      serviceData?.timings?.firstOrNull?.start ?? "N/A",
                      fontSize: SizeConfig.small,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              // height: SizeConfig.size20,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size10),
              child: Row(
                children: [
                  CustomText(
                    "End Time : ",
                    fontSize: SizeConfig.small,
                    fontWeight: FontWeight.bold,
                    maxLines: 1,
                  ),
                  Flexible(
                    child: CustomText(
                      serviceData?.timings?.firstOrNull?.end ?? "N/A",
                      fontSize: SizeConfig.small,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

