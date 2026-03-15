class Report {
  final String id;
  final String? stationId;
  final String userId;
  final String? newStatut;
  final String? newEncombrement;
  final String? notes;
  final String status;
  final String? imageUrl;
  final DateTime createdAt;
  final int upvotes;
  final int downvotes;
  final String? adminNotes;
  // Enriched fields (from reports_detailed view)
  final String? stationName;
  final String? stationAddress;
  final String? currentStatut;
  final String? userEmail;
  final String? myVote; // 'upvote', 'downvote', or null

  Report({
    required this.id,
    this.stationId,
    required this.userId,
    this.newStatut,
    this.newEncombrement,
    this.notes,
    this.status = 'pending',
    this.imageUrl,
    required this.createdAt,
    this.upvotes = 0,
    this.downvotes = 0,
    this.adminNotes,
    this.stationName,
    this.stationAddress,
    this.currentStatut,
    this.userEmail,
    this.myVote,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'],
      stationId: json['station_id'],
      userId: json['user_id'],
      newStatut: json['new_statut'],
      newEncombrement: json['new_encombrement'],
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      adminNotes: json['admin_notes'],
      stationName: json['station_name'],
      stationAddress: json['station_address'],
      currentStatut: json['current_statut'],
      userEmail: json['user_email'],
      myVote: json['my_vote'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'station_id': stationId,
      'user_id': userId,
      'new_statut': newStatut,
      'new_encombrement': newEncombrement,
      'notes': notes,
      'status': status,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'admin_notes': adminNotes,
    };
  }

  /// Status color for UI display
  static String statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'En attente';
    }
  }
}
