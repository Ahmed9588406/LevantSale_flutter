class AdModel {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final int daysRemaining;
  final int views;
  final int potentialCustomers;
  final AdStatus status;
  final String? statusLabel;

  AdModel({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.daysRemaining,
    required this.views,
    required this.potentialCustomers,
    required this.status,
    this.statusLabel,
  });
}

enum AdStatus {
  active,
  pending,
  waitingForApproval,
}
