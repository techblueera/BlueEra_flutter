import 'package:BlueEra/features/personal/personal_profile/view/rental_page/rental_details.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

import '../../../../../widgets/horizontal_tab_selector.dart';
import 'RentalServiceUploadScreen.dart';

class RentalScreen extends StatefulWidget {
  const RentalScreen({Key? key}) : super(key: key);

  @override
  State<RentalScreen> createState() => _RentalScreenState();
}

class _RentalScreenState extends State<RentalScreen>
    with SingleTickerProviderStateMixin {

  final List<String> topTabs = ["Services", "Stores", "Jobs", "Rental", "Events"];
  int selectedTopTab = 3; // Rental active

  final List<String> subTabs = ["Home Stay", "Hotel", "Flat/Room", "Vehicle", "Other"];
  int selectedSubTab = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonBackAppBar(
        isSearch: true,
        controller: TextEditingController(),
        onClearCallback: (){},
        // onProfileTap: widget.onProfileTap,
      ),
      body: Stack(
        children: [
          // MAP BACKGROUND PLACEHOLDER
        Positioned(
          top: 0,
          left: 20,
          child:
      const SizedBox(
        height:100,
        child: DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFFECECEC)),
          child: Center(
            child: Text(""),
          ),
        ),
      ),),
          Positioned(
            top: 10,
            child: HorizontalTabSelector(
            tabs: topTabs,
            selectedIndex: 0,
            onTabSelected: (index, value) {

            },
            labelBuilder: (jobCategory) {
              return jobCategory;
            },
            // isFilterIconShow: true,
          ),
          ),
          // MAIN CONTENT
          Positioned.fill(
            top: 110,
            child: SafeArea(
              child: Container(
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.only(topLeft:Radius.circular(24) ,topRight: Radius.circular(24))
               ),
                padding: EdgeInsets.symmetric(horizontal: 14,vertical: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Container(

                      height: 45,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: subTabs.length,
                        itemBuilder: (context, index) {
                          bool isSelected = selectedSubTab == index;
                          return GestureDetector(
                            onTap: () => setState(() => selectedSubTab = index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                children: [
                                  Text(
                                    subTabs[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color:
                                      isSelected ? Colors.black : Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (isSelected)
                                    Container(
                                      height: 2,
                                      width: 100,
                                      color: Colors.blue,
                                    )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Scrollable list of cards
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return InkWell(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context) => RentalDetailsScreen(),));

                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        topRight: Radius.circular(12)),
                                    child: Image.asset(
                                      "assets/diwali_card/rentalhome.png", // Replace with your image
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Banerjee Inn- City Centre",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: const [
                                            Icon(Icons.star, color: Colors.amber, size: 18),
                                            SizedBox(width: 3),
                                            Text("4.8",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w500, fontSize: 13)),
                                            SizedBox(width: 5),
                                            Text("(48 reviews)",
                                                style: TextStyle(color: Colors.grey, fontSize: 13)),
                                            SizedBox(width: 10),
                                            Icon(Icons.location_on_outlined,
                                                color: Colors.black54, size: 16),
                                            Text("1.2 km",
                                                style: TextStyle(color: Colors.black54, fontSize: 13)),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(child: _actionButton(Icons.navigation_outlined, "Direction")),
                                           const SizedBox(width: 6,),
                                            Expanded(child: _actionButton(Icons.reviews_outlined, "Reviews")),
                                            const SizedBox(width: 6,),
                                            Expanded(child: _bookNowButton()),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$label clicked')));
      },
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.blue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      icon: Icon(icon, size: 18, color: Colors.blue),
      label: Text(label,
          style: const TextStyle(
              color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _bookNowButton() {
    return ElevatedButton.icon(
      onPressed: () {
       Navigator.push(context, MaterialPageRoute(builder: (context) => RentalServiceUploadScreen(),));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      ),
      icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.white),
      label: const Text("Book Now",
          style: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}
