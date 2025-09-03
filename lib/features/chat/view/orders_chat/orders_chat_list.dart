import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'order_chat_screen.dart';
class OrdersTabView extends StatefulWidget {
  @override
  State<OrdersTabView> createState() => _OrdersTabViewState();
}

class _OrdersTabViewState extends State<OrdersTabView> {
  final List<Map<String, dynamic>> orders = [
    {
      'title': "McDonald’s",
      'subtitle': "Pizza, Burger, French Fries, 1 L bottle of Cold Drink...",
      'time': "9:52 PM",
      'status': "Active",
      'statusColor': Colors.green,
      'logo': 'assets/mcd.png',
    },
    {
      'title': "Pizza Hut",
      'subtitle': "Pizza, Burger, French Fries, 1 L bottle of Cold Drink...",
      'time': "9:52 PM",
      'status': "Cancelled",
      'statusColor': Colors.red,
      'logo': 'assets/pizza.png',
    },
    {
      'title': "Dominos",
      'subtitle': "Pizza, Burger, French Fries, 1 L bottle of Cold Drink...",
      'time': "9:52 PM",
      'status': "Completed",
      'statusColor': Colors.grey,
      'logo': 'assets/dominos.png',
    },
  ];

  final List<String> filters = ['filter','All', 'Selling', 'Buying', 'Bookings', 'Meetings'];

  String seletecValue="All";

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Buttons
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center,
            children: filters.map((filter) {
              final isSelected = filter == seletecValue;
              return (filter=="filter")?Padding(
                padding: const EdgeInsets.only(top: 18.0,left: 8,right: 10),
                child: SvgPicture.asset(AppIconAssets.mage_filter),
              ):Padding(
                padding:  EdgeInsets.only(right: 8,top: 18),
                child: InkWell(
                  onTap: (){
                    setState(() {
                      seletecValue=filter;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.buttonLiteBlue : Colors.white,
                      border: isSelected?null:Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    padding: EdgeInsets.symmetric(horizontal:filter=="All"?13: 8,vertical: 5),
                    child: CustomText(
                      filter,
                        color: isSelected ? Colors.black : AppColors.optionShowGray,
                        fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 14),

        // Orders List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return InkWell(
                onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderChatScreen()));
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 22),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 22,
                        child: CustomText(
                            'BE',
                            color: Colors.white, fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              order['title'],
                                  fontSize: 16,
                                fontWeight: FontWeight.bold

                            ),
                            SizedBox(height: 4),
                            CustomText(
                              order['subtitle'],
                                  color: Colors.grey.shade600, fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CustomText(
                            order['time'],
                                fontSize: 11,
                              color: Colors.grey
                          ),
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(color: order['statusColor']),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: CustomText(
                              order['status'],
                                color: order['statusColor'],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}