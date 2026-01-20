import 'package:get/get.dart';

class BusinessDetailsController extends GetxController {
  // Profile Information
  final RxString businessName = 'Lorem Ipsum Dolor'.obs;
  final RxString profileImage = 'https://i.pravatar.cc/150?img=1'.obs;
  final RxDouble rating = 4.5.obs;
  final RxInt reviewCount = 450.obs;
  final RxString distance = '1.2 km'.obs;
  final RxString timings = 'Monday - Friday: 9:00 AM - 6:00 PM'.obs;
  final RxString description = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet scelerisque. ...Read More'.obs;

  // Staffs
  final RxList<Map<String, String>> staffs = <Map<String, String>>[
    {
      'name': 'Priya Dasgupta',
      'role': 'Senior Beautician',
      'image': 'https://i.pravatar.cc/150?img=5'
    },
    {
      'name': 'Sonali Sharma',
      'role': 'Nail Technician',
      'image': 'https://i.pravatar.cc/150?img=9'
    },
    {
      'name': 'Divya Singh',
      'role': 'Makeup Artist',
      'image': 'https://i.pravatar.cc/150?img=10'
    },
  ].obs;

  // Services
  final RxList<Map<String, String>> services = <Map<String, String>>[
    {
      'title': 'Lorem ipsum',
      'description': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.',
      'image': 'https://picsum.photos/400/300?random=1'
    },
    {
      'title': 'Dolor Sit',
      'description': 'Sed do eiusmod tempor incididunt ut labore.',
      'image': 'https://picsum.photos/400/300?random=2'
    },
  ].obs;

  // Products
  final RxList<Map<String, dynamic>> products = <Map<String, dynamic>>[
    {
      'name': 'Pharma Franchise For OTC Product',
      'image': 'https://picsum.photos/200/200?random=3',
      'price': '₹45,400',
      'originalPrice': '₹58,000',
      'discount': '30% OFF'
    },
    {
      'name': 'Pharma Franchise For OTC Product',
      'image': 'https://picsum.photos/200/200?random=4',
      'price': '₹45,400',
      'originalPrice': '₹58,000',
      'discount': '30% OFF'
    },
  ].obs;

  // Jobs
  final RxList<Map<String, dynamic>> jobs = <Map<String, dynamic>>[
    {
      'title': 'Senior Beautician',
      'postedDate': 'Posted On : 26 Jan 2025',
      'type': 'Full Time',
      'locationType': 'On Site',
      'experience': '3 yrs',
      'salary': '15,000 to 20,000',
      'location': 'Gomti Nagar, Lucknow'
    }
  ].obs;

  // Gallery
  final RxList<String> galleryImages = <String>[
    'https://picsum.photos/300/300?random=5',
    'https://picsum.photos/300/300?random=6',
    'https://picsum.photos/300/300?random=7',
    'https://picsum.photos/300/300?random=8',
  ].obs;

  // Latest Post
  final RxMap<String, dynamic> latestPost = <String, dynamic>{
    'author': 'Narendra Modi',
    'handle': '@narendramodi',
    'avatar': 'https://i.pravatar.cc/150?img=11',
    'content': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet...',
    'link': 'https://blueera.ai',
    'images': [
      'https://picsum.photos/200/200?random=9',
      'https://picsum.photos/200/200?random=10',
      'https://picsum.photos/200/200?random=11',
    ],
    'stats': {
      'days': '5 days ago',
      'views': '20k',
      'comments': '88',
      'likes': '30',
      'shares': '12'
    }
  }.obs;

  // Testimonials
  final RxMap<String, String> testimonial = <String, String>{
    'text': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet scelerisque. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.',
    'author': 'Dr. Ramesh Gupta',
    'designation': 'Managing Director'
  }.obs;

  // Contact Us
  final RxMap<String, String> contactInfo = <String, String>{
    'website': 'https://blueera.ai',
    'address': 'Dehradun Dell',
    'email': 'dpdehradun@gmail.com',
    'phone': '+91 1234567890'
  }.obs;

  @override
  void onInit() {
    super.onInit();
    // Fetch data from API if needed
  }
}
