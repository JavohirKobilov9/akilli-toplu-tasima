class AppNotification {
  final int id;
  final int? complaintId;
  final String title;
  final String message;
  final String status;
  final DateTime? createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.complaintId,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        complaintId: json['complaint_id'] as int?,
        title: json['title'] as String,
        message: json['message'] as String,
        status: json['status'] as String,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')
            ?.toLocal(),
        isRead: json['read_at'] != null,
      );
}
