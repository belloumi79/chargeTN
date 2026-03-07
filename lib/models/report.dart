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
    };
  }
}
