import 'package:flutter/material.dart';

class HospitalHomePage extends StatefulWidget {
  const HospitalHomePage({super.key});

  @override
  State<HospitalHomePage> createState() => _HospitalHomePageState();
}

class _HospitalHomePageState extends State<HospitalHomePage> {
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hospitalHeader(),
          _quickActions(),
          _sectionTitle("Doctors"),
          _doctorList(),
          _sectionTitle("IPD"),
          _ipdList(),
          _sectionTitle("Emergency & Critical Care"),
          _emergencyList(),
          _sectionTitle("Other Services"),
          _ambulanceCard(),
          _sectionTitle("About Us"),
          _infoCard("Vision & Mission"),
          _infoCard("History"),
          _sectionTitle("Management"),
          _managementList(),
          _sectionTitle("Gallery"),
          _galleryGrid(),
          _sectionTitle("Testimonials"),
          _testimonialCard(),
          _sectionTitle("Contact Us"),
          _contactCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _hospitalHeader() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "The Mission Hospital",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            "Near xyz road, Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _actionButton(Icons.call, "Call"),
          _actionButton(Icons.share, "Share"),
          _actionButton(Icons.calendar_today, "Book"),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(height: 6),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _doctorList() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (_, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: const [
                Expanded(
                  child: Icon(Icons.person, size: 60),
                ),
                Text(
                  "Dr. Soumya",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  "General Surgeon",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _ipdList() {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (_, index) {
          return Container(
            width: 180,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "General Bed",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _emergencyList() {
    final items = [
      "Emergency / Casualty",
      "Trauma Care",
      "ICU",
      "CCU",
      "NICU",
      "PICU",
    ];
    return Column(
      children: items.map((e) {
        return ListTile(
          leading: const Icon(Icons.local_hospital, color: Colors.red),
          title: Text(e),
          subtitle: const Text("24x7 available"),
        );
      }).toList(),
    );
  }

  Widget _ambulanceCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        leading: const Icon(Icons.local_shipping, color: Colors.red),
        title: const Text("Ambulance"),
        subtitle: const Text("24x7 Emergency Service"),
      ),
    );
  }

  Widget _infoCard(String title) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(title),
        subtitle: const Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
      ),
    );
  }

  Widget _managementList() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, index) {
          return Container(
            width: 140,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircleAvatar(radius: 30),
                SizedBox(height: 8),
                Text("Dr. James Gupta"),
                Text("Managing Director",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _galleryGrid() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (_, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }

  Widget _testimonialCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Text(
              "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 8),
            Text("- Dr. Ramesh Gupta"),
          ],
        ),
      ),
    );
  }

  Widget _contactCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: const [
          ListTile(
            leading: Icon(Icons.phone),
            title: Text("+91 9876543210"),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text("support@missionhospital.com"),
          ),
          ListTile(
            leading: Icon(Icons.location_on),
            title: Text("Near XYZ Road, City"),
          ),
        ],
      ),
    );
  }
}
