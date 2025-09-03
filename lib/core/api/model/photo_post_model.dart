class PhotoPost {
  List<String> photoUrls;
  String description;
  List<String> taggedPeople;
  String natureOfPost;

  PhotoPost({
    required this.photoUrls,
    this.description = '',
    this.taggedPeople = const [],
    this.natureOfPost = '',
  });
}