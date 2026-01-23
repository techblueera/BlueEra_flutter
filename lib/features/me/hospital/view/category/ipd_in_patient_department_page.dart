import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/custom_carousel_slider.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:intl/intl.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_constant.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/constants/size_config.dart';
import '../../controller/hospital_model_controller.dart';
import '../../model/docters_details_model.dart';
import '../../model/get_beds_details_model.dart';
import '../widget/add_doctors_dialoge.dart';


class IpdInPatientWardViewPage extends StatefulWidget {
  IpdInPatientWardViewPage({super.key, required this.documentId, required this.title});
  final String documentId;
  final String title;

  @override
  State<IpdInPatientWardViewPage> createState() => _IpdInPatientWardViewPageState();
}

class _IpdInPatientWardViewPageState extends State<IpdInPatientWardViewPage> {

  final controller = getOrPut(() => HospitalModelController());

  @override
  void initState() {
    // TODO: implement initState
    controller.getAllBeds(widget.documentId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "${widget.title}",
      ),
      body: SingleChildScrollView(
        child: Obx(() {
          if(controller.getBedsResponse.value.status==Status.COMPLETE){
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  if(controller.bedsList.isEmpty)
                    Center(
                      child: CustomText(textAlign: TextAlign.center,"No Wards Added Yet in ${widget.title} Department"),
                    )
                  else
                    ...controller.bedsList.map((e) =>
                        WardListCard(
                          item: e,
                          onMenuTap: (){

                          },
                          onManageLeave: () {},
                        )).toList(),
                  SizedBox(height: SizeConfig.size20,),
                  InkWell(
                    onTap: () {
                      HospitalStaffDialog.showAddBedsDialog(
                        context: context,
                        departmentId: widget.documentId,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryColor),
                        color: AppColors.primaryColor.withOpacity(0.1),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                            color: AppColors.primaryColor,),
                          SizedBox(width: SizeConfig.size6,),
                          CustomText(
                            "Add More",
                            fontSize: 14,
                            textAlign: TextAlign.center,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeConfig.size20,)
                ],
              ),
            );
          }else{
            return Center(
              child: CircularProgressIndicator(),
            );
          }

        }),
      ),
    );
  }
  void showMenuItems(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Edit"),
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text("Delete"),
              ),
            ],
          ),
        );
      },);
  }
}


class WardListCard extends StatelessWidget {
  final BedDetailsModel item;
  final VoidCallback? onMenuTap;
  final VoidCallback? onManageLeave;

  const WardListCard({
    super.key,
    required this.item,
    this.onMenuTap,
    this.onManageLeave,
  });

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => HospitalModelController());

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Doctor Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomImageSlideshow(
                height: 120,
                width: 120,
                isLoading: false, imagePaths: [item.image??''],
              ),
            ),

            const SizedBox(width: 12),

            /// Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Name + Menu
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                            item.name,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainTextColor

                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        onSelected: (value) async {
                          if(value=='Edit'){
                            HospitalStaffDialog.showAddBedsDialog(
                                context: context,
                                departmentId: '',
                                preDoctorDetails: item
                            );
                          }else{
                            await controller.deleteBedsDetails(model: item);
                          }

                        },
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: "Edit",
                            child: CustomText(
                              AppStrings.edit,
                            ),
                          ),
                          PopupMenuItem(
                            value: "Delete",
                            child: CustomText(
                              AppStrings.delete,
                            ),
                          ),

                        ],
                        child:  const Icon(Icons.more_vert, size: 20,
                            color: AppColors.mainTextColor
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.greyE5, width: 1)
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        CustomText(
                          item.bedNumber,
                          fontSize: 10,
                          color: Colors.grey.shade600,

                        ),

                        const SizedBox(height: 4),

                        /// Availability
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                "${item.description}",
                                fontSize: 10,
                              ),
                            ),

                          ],
                        ),

                        const SizedBox(height: 6),

                        /// Fees
                        Row(
                          children: [
                            Expanded(
                              child: CustomText(
                                  "Fees: ${item.fees}",
                                  fontSize: 10
                              ),
                            ),

                          ],
                        ),

                      ],
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
