/// Social-feed post.
class PostItem {
  final String id;
  final String userId;
  final String content;
  final String? imageUrl;
  final String? stationId;
  final String? stationName;
  final int likesCount;
  final int commentsCount;
  final DateTime createdAt;
  final String? authorEmail;
  final String? authorName;
  bool likedByMe;

  PostItem({
    required this.id,
    required this.userId,
    required this.content,
    this.imageUrl,
    this.stationId,
    this.stationName,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    this.authorEmail,
    this.authorName,
    this.likedByMe = false,
  });

  factory PostItem.fromJson(Map<String, dynamic> j) => PostItem(
        id: j['id'],
        userId: j['user_id'],
        content: j['content'],
        imageUrl: j['image_url'],
        stationId: j['station_id'],
        stationName: j['station_name'],
        likesCount: j['likes_count'] ?? 0,
        commentsCount: j['comments_count'] ?? 0,
        createdAt: DateTime.parse(j['created_at']),
        authorEmail: j['author_email'],
        authorName: j['author_name'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'content': content,
        'image_url': imageUrl,
        'station_id': stationId,
        'station_name': stationName,
        'likes_count': likesCount,
        'comments_count': commentsCount,
        'created_at': createdAt.toIso8601String(),
        'author_email': authorEmail,
        'author_name': authorName,
      };
}

/// Social-feed comment.
class CommentItem {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String? userEmail;

  CommentItem({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.userEmail,
  });

  factory CommentItem.fromJson(Map<String, dynamic> j) => CommentItem(
        id: j['id'],
        userId: j['user_id'],
        content: j['content'],
        createdAt: DateTime.parse(j['created_at']),
        userEmail: j['user_email'],
      );
}
