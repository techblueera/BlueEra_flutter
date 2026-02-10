import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import '../../../../../core/constants/getx_utils.dart';
import '../../controller/help_and_support_controller.dart';


class ComplaintMainPage extends StatefulWidget {


  const ComplaintMainPage({super.key,});

  @override
  State<ComplaintMainPage> createState() => _ComplaintMainPageState();
}

class _ComplaintMainPageState extends State<ComplaintMainPage>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController tabController;
  final controller = getOrPut(() => HelpAndSupportController());




  @override
  void initState() {

 tabController = TabController(length: 3, vsync: this);
    super.initState();
  }
  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Complaints",
        isShadowShow: false,
      ),
        body:SafeArea(
          child: Column(
            children: [
              Container(
                color: AppColors.white,
                child: TabBar(
                  onTap: (index) {

                  },
                  controller:tabController ,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: Colors.lightBlue,
                  tabs: const [
                    Tab(text: "Product"),
                    Tab(text: "Food"),
                    Tab(text: "Grocery"),
                    Tab(text: "Service"),
                  ],
                ),
              ),
              Expanded(child: TabBarView(
                controller: tabController,
                children: [
                  ComplaintCardList(),
                  ComplaintCardList(),
                  ComplaintCardList(),
                  ComplaintCardList(),
                ],
              ))
            ],
          ),
        )

    );
  }
Widget ComplaintCardList(){
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 8,vertical: 8),
        itemCount: 10,
        itemBuilder: (BuildContext context,index){
      return Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                "", // 👉 your API image URL
                height: 60,
                width: 60,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 60,
                    width: 60,
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 64,
                    width: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            // Text Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Nike Fashion Shoe Lorem Ipsum Ip....",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                  ),

                  const SizedBox(height: 4),

                  CustomText(
                    "Delivered On Jan 10",

                      fontSize: 12,
                      color: AppColors.coloGreyText,

                  ),

                  const SizedBox(height: 6),

                  GestureDetector(
                    onTap: () {
                      // handle write review action
                    },
                    child: const CustomText(
                      "Write A Review",
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,

                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
}

}
