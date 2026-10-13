class ComplaintComment {
  final int id;
  final int complaintId;

  final String comment;

  final int userId;
  final String userName;

  final int likeCount;
  final int dislikeCount;

  final String? myReaction;

  final DateTime? createdAt;

  ComplaintComment({
    required this.id,
    required this.complaintId,
    required this.comment,
    required this.userId,
    required this.userName,
    required this.likeCount,
    required this.dislikeCount,
    required this.myReaction,
    required this.createdAt,
  });

  factory ComplaintComment.fromJson(
    Map<String, dynamic> json,
  ) {
    final user =
        json['user'] as Map<String, dynamic>? ?? {};

    return ComplaintComment(
      id: json['id'] ?? 0,
      complaintId: json['complaint_id'] ?? 0,
      comment: json['comment'] ?? '',
      userId: user['id'] ?? 0,
      userName: user['name'] ?? 'Kullanıcı',
      likeCount: json['like_count'] ?? 0,
      dislikeCount: json['dislike_count'] ?? 0,
      myReaction: json['my_reaction'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(
              json['created_at'].toString(),
            )
          : null,
    );
  }
}