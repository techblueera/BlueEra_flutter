class CollapsibleGridModel {
  final String name;
  final String slugId;
  final String? icon;
  final String? image;


  const CollapsibleGridModel({
     required this.name,
     required this.slugId,
     this.icon,
     this.image,
  });
}