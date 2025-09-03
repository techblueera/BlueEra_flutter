class ServiceCategoryBusinessModel {
  final String name;       // Display Name
  final String slug;       // CAPITAL SLUG
  final List<ServiceSubCategoryBusinessModel> subCategories;

  ServiceCategoryBusinessModel({
    required this.name,
    required this.slug,
    required this.subCategories,
  });
}

class ServiceSubCategoryBusinessModel {
  final String name; // Display Name
  final String slug; // CAPITAL SLUG

  ServiceSubCategoryBusinessModel({required this.name, required this.slug});
}
