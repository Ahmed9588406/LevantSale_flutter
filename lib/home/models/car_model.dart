class CarModel {
  final String title;
  final String subtitle;
  final String price;
  final String time;
  final String image;
  final bool isFeatured;

  CarModel({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.time,
    required this.image,
    this.isFeatured = false,
  });
}
