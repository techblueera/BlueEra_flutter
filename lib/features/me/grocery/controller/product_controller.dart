import 'package:BlueEra/core/api/model/category_model.dart';
import 'package:BlueEra/features/me/grocery/model/dummy_category_product_res_model.dart';
import 'package:BlueEra/features/personal/personal_profile/view/inventory/model/product_model.dart';
import 'package:get/get.dart';

class ProductController extends GetxController {
  var selectedCategoryId = '1'.obs;
  var categories = <DummyCategories>[].obs;
  var allProducts = <DummyProducts>[].obs;
@override
  void onInit() {
    // TODO: implement onInit
  loadData(data);
  super.onInit();
  }
  var data={
    "categories": [
      { "id": "1", "name": "South Indian", "image": "https://media.istockphoto.com/id/1300116537/vector/south-indian-breakfast-dish-dosa-and-vada-with-sambar-and-chutney-on-banana-leaf.jpg?s=612x612&w=0&k=20&c=ZPpL_AoaLRF33620ZN-dhHcGwgA1TlnQ-IgM7JUHWNQ=" },
      { "id": "2", "name": "North Indian", "image": "https://media.istockphoto.com/id/2049653341/vector/top-view-indian-food-basmati-rice-with-chicken-tandoori.jpg?s=612x612&w=0&k=20&c=pzWITiRm-S6oMG78rkTyn1LoSAabPkfFv6b2YU1ulv4=" }
    ],
    "products": [
      {
        "id": "101",
        "categoryId": "1",
        "name": "2 Idli + Sambar + Chutney",
        "description": "A popular and healthy South Indian breakfast consisting of savory steamed rice cakes.",
        "imageUrl": "https://static.vecteezy.com/system/resources/previews/042/671/173/non_2x/illustration-logo-delicious-masala-dosa-on-banana-leaf-vector.jpg",
        "isVeg": true,
        "tag": "Boiled",
        "variants": [
          { "name": "Half Plate", "weight": "600 gm", "price": 1500, "mrp": 1999 },
          { "name": "Full Plate", "weight": "1200 gm", "price": 2800, "mrp": 3500 }
        ]
      },
      {
        "id": "101",
        "categoryId": "1",
        "name": "2 Idli + Sambar + Chutney",
        "description": "A popular and healthy South Indian breakfast consisting of savory steamed rice cakes.",
        "imageUrl": "https://i.ytimg.com/vi/hJBwHXC_tlw/hq720.jpg?sqp=-oaymwEhCK4FEIIDSFryq4qpAxMIARUAAAAAGAElAADIQj0AgKJD&rs=AOn4CLDgT_SIDFX6nj-8OiSoRF9Hh9cxqA",
        "isVeg": true,
        "tag": "Boiled",
        "variants": [
          { "name": "Half Plate", "weight": "600 gm", "price": 1500, "mrp": 1999 },
          { "name": "Full Plate", "weight": "1200 gm", "price": 2800, "mrp": 3500 }
        ]
      }, {
        "id": "101",
        "categoryId": "1",
        "name": "2 Idli + Sambar + Chutney",
        "description": "A popular and healthy South Indian breakfast consisting of savory steamed rice cakes.",
        "imageUrl": "https://i.pinimg.com/736x/49/8d/c9/498dc99ef4e35fb0bec50bc3920898d0.jpg",
        "isVeg": true,
        "tag": "Boiled",
        "variants": [
          { "name": "Half Plate", "weight": "600 gm", "price": 1500, "mrp": 1999 },
          { "name": "Full Plate", "weight": "1200 gm", "price": 2800, "mrp": 3500 }
        ]
      },
      {
        "id": "101",
        "categoryId": "2",
        "name": "2 Idli + Sambar + Chutney",
        "description": "A popular and healthy South Indian breakfast consisting of savory steamed rice cakes.",
        "imageUrl": "https://img.freepik.com/free-vector/hand-drawn-indian-cuisine-illustration_23-2149323580.jpg?semt=ais_hybrid&w=740&q=80",
        "isVeg": true,
        "tag": "Boiled",
        "variants": [
          { "name": "Half Plate", "weight": "600 gm", "price": 1500, "mrp": 1999 },
          { "name": "Full Plate", "weight": "1200 gm", "price": 2800, "mrp": 3500 }
        ]
      },
    ]
  };

  // Computed list for the right side
  List<DummyProducts> get filteredProducts =>
      allProducts.where((p) => p.categoryId == selectedCategoryId.value).toList();

  void changeCategory(String id) {
    selectedCategoryId.value = id;
  }
  // Function to load data from your JSON
  void loadData(Map<String, dynamic> jsonResponse) {
    var data = DummyCategoryProductResModel.fromJson(jsonResponse);
    categories.value = data.categories ?? [];
    allProducts.value = data.products ?? [];
  }
}