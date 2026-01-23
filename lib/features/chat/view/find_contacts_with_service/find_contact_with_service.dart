import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/features/chat/view/find_contacts_with_service/professionals/professionals_main.dart';
import 'package:BlueEra/features/chat/view/find_contacts_with_service/services/service_main.dart';
import 'package:BlueEra/features/chat/view/find_contacts_with_service/shopping/shopping_main.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';
class FindContactWithService extends StatefulWidget {
  const FindContactWithService({super.key});

  @override
  State<FindContactWithService> createState() => _FindContactWithServiceState();
}

class _FindContactWithServiceState extends State<FindContactWithService> with SingleTickerProviderStateMixin{
  TabController? tabController;
  @override
  void initState() {
    // TODO: implement initState
    tabController = TabController(length: 4, vsync: this,initialIndex: 0);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isShadowShow: false,
        title: "Find In Your Contact",
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppColors.white,
            child: TabBar(
              tabAlignment: TabAlignment.start,
              indicatorPadding:EdgeInsets.zero,
              padding: EdgeInsets.zero,
              isScrollable: true,
              onTap: (index) {
              },
              indicatorSize: TabBarIndicatorSize.tab,
              controller: tabController,
              dividerColor: AppColors.primaryColor.withOpacity(0.10),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              indicatorColor: AppColors.primaryColor,
              labelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500
              ),
              tabs: const [
                Tab(text: "Professionals",),
                Tab(text: "Shopping"),
                Tab(text: "Services"),
                Tab(text: "Others"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                ProfessionalsMain(),
                ShoppingMain(),
                ServiceMain(),
                Container(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
