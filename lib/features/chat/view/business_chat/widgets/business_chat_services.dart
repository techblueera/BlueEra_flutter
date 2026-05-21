
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../business/auth/controller/view_business_details_controller.dart';
import '../../../../common/service/widget/service_card.dart';

class BusinessChatServices extends StatefulWidget {
  const BusinessChatServices({super.key, required this.businessId});

  final String businessId;

  @override
  State<BusinessChatServices> createState() => _BusinessChatServicesState();
}

class _BusinessChatServicesState extends State<BusinessChatServices> {
  final controller = getOrPut(() => ViewBusinessDetailsController(), permanent: true);

  @override
  void initState() {
    controller.fetchServices(visitBusinessId: widget.businessId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.businessServiceResponse.value.status == Status.COMPLETE) {
        return _buildGridView(controller);
      }
      return Center(child: CircularProgressIndicator());
    });
  }

  Widget _buildGridView(ViewBusinessDetailsController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 2;
        const crossSpacing = 6.0;
        const mainSpacing = 6.0;

        final itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * crossSpacing)) /
                crossAxisCount;

        return (controller.services.isEmpty)
            ? Center(
                child: CustomText(AppStrings.noServicesFound),
              )
            : MasonryGridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossSpacing,
                mainAxisSpacing: mainSpacing,
                itemCount: controller.services.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (context, index) {
                  final service = controller.services[index];
                  return ServiceCardBusiness(
                    serviceData: service,
                    isGridView: true,
                    businessData: null,
                    width: itemWidth,
                  );
                },
              );
      },
    );
  }
}
