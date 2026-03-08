class BannerModel {
  final String id;
  final String imageUrl;
  final String? listingId;
  final String? listingTitle;
  final int displayOrder;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.listingId,
    this.listingTitle,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      listingId: json['listingId']?.toString(),
      listingTitle: json['listingTitle']?.toString(),
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}
