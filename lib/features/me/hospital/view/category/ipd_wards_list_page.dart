import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../../../../core/routes/route_helper.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../widget/no_product_profile.dart';
import '../../controller/hospital_model_controller.dart';
import '../../model/hospital_ward_model.dart';
import '../widget/add_doctors_dialoge.dart';


class IpdWardsListPage extends StatefulWidget {
  const IpdWardsListPage(
      {super.key, required this.categoryId, required this.title, required this.type});
  final String categoryId;
  final String title;
  final String type;

  @override
  State<IpdWardsListPage> createState() => _IpdWardsListPageState();
}

class _IpdWardsListPageState extends State<IpdWardsListPage> {
  final controller = getOrPut(() => HospitalModelController());
  @override
  void initState() {
    // TODO: implement initState
    controller.getHospitalIpdWardsList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        showRightTextButton: true,
        isShowMoreInfoIcon: true,
        title: widget.title,
        isShadowShow: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Obx(() {
            if (controller.getHospitalSubResponse.value.status ==
                Status.COMPLETE) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    if(controller.wardModelList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 30.0),
                        child: NoProfileDetailsFound(
                            content: "No Details Found Under ${widget.title}"),
                      )
                    else
                      ...controller.wardModelList.map((ward) {
                        return InkWell(
                          onTap: () async {
                            Get.toNamed(
                                  RouteHelper.getHospitalWardViewCategory(),
                                  arguments: {
                                    ApiKeys.categoryId:ward.id,
                                    ApiKeys.title:ward.name
                                  }
                              );
                          },
                          child:WardCard(
                            departmentId: widget.categoryId,
                            preModel: ward,
                            name: ward.name,
                            type: ward.type,
                            totalBeds: ward.totalBeds,
                            availableBeds: ward.availableBeds,
                            fee: ward.fees,
                          ),
                        );
                      }).toList(),
                    SizedBox(height: SizeConfig.size20,),
                    InkWell(
                      onTap: () {
                        controller.nameController.clear();
                        HospitalStaffDialog.showAddIPDWardDialog(
                          context: context,
                          departmentId: widget.categoryId,
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 8),
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
                              "Add More ${widget.title}",
                              fontSize: 14,
                              textAlign: TextAlign.center,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: SizeConfig.size50,),
                  ],
                ),
              );
            } else if (controller.getHospitalSubResponse.value.status ==
                Status.INITIAL) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return Center(
                child: CustomText("Please try sometime"),
              );
            }
          }),
        ),
      ),
    );
  }
}

class WardCard extends StatelessWidget {
  final String? name;
  final String? type;
  final String? departmentId;
  final int? totalBeds;
  final int? availableBeds;
  final int? fee;
  final WardModel? preModel;

  const WardCard({
    super.key,
    this.name,
    this.type,
    this.totalBeds,
    this.availableBeds,
    this.fee, this.preModel, this.departmentId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => HospitalModelController());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.whiteE5
        ),

      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Name
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                name ?? 'N/A',
                // style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                // ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                onSelected: (value) async {
                  if(value=='Edit'){
                    HospitalStaffDialog.showAddIPDWardDialog(
                      preDoctorDetails: preModel,
                      context: context,
                      departmentId: departmentId??'',
                    );
                  }else{
                    await controller.deleteWardsDetails( wardId: preModel?.id??'');
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

          const SizedBox(height: 4),

          /// Type
          CustomText(
            type ?? 'N/A',
            // style: const TextStyle(
              fontSize: 13,
              color: AppColors.grayText,
            // ),
          ),

          const Divider(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem('Total Beds', totalBeds?.toString() ?? '0'),
              _infoItem('Available', availableBeds?.toString() ?? '0'),
              _infoItem('Fee', '₹${fee ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
            fontSize: 11,
            color: AppColors.grayText,
        ),
        const SizedBox(height: 4),
        CustomText(
          value,
            fontSize: 14,
            fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}
