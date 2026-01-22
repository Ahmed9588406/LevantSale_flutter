class PropertyModel {
  final String title;
  final String location;
  final String image;
  final bool isFeatured;

  PropertyModel({
    required this.title,
    required this.location,
    required this.image,
    this.isFeatured = false,
  });
}
