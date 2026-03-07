class StationProof {
  final String id;
  final String? stationId;
  final String imageUrl;
  final String? uploadedBy;
  final DateTime uploadedAt;

  StationProof({
    required this.id,
    this.stationId,
    required this.imageUrl,
    this.uploadedBy,
    required this.uploadedAt,
  });

  factory StationProof.fromJson(Map<String, dynamic> json) {
    return StationProof(
      id: json['id'],
      stationId: json['station_id'],
      imageUrl: json['image_url'],
      uploadedBy: json['uploaded_by'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'station_id': stationId,
      'image_url': imageUrl,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
