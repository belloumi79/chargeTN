class Station {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? name;
  final double latitude;
  final double longitude;
  final String? address;
  final int nbBornes;
  final List<String> puissanceKw;
  final List<String> typePrise;
  final int nbPoints;
  final String statut;
  final String encombrement;
  final bool verified;
  final String? submittedBy;
  final String? approvedBy;
  final String? notes;
  
  // New features for Tunisian market
  final double reliabilityScore; // 0.0 to 5.0 based on crowd reports
  final int recentSuccessfulCharges; // Last 24h
  final List<String> amenities; // ['cafe', 'wifi', 'shop', 'wc']
  final bool supportsOffline;

  Station({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.nbBornes = 1,
    required this.puissanceKw,
    required this.typePrise,
    this.nbPoints = 1,
    this.statut = 'fonctionnelle',
    this.encombrement = 'libre',
    this.verified = false,
    this.submittedBy,
    this.approvedBy,
    this.notes,
    this.reliabilityScore = 4.5,
    this.recentSuccessfulCharges = 0,
    this.amenities = const [],
    this.supportsOffline = true,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      name: json['name'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'],
      nbBornes: json['nb_bornes'] ?? 1,
      puissanceKw: json['puissance_kw'] != null ? List<String>.from(json['puissance_kw']) : [],
      typePrise: json['type_prise'] != null ? List<String>.from(json['type_prise']) : [],
      nbPoints: json['nb_points'] ?? 1,
      statut: json['statut'] ?? 'fonctionnelle',
      encombrement: json['encombrement'] ?? 'libre',
      verified: json['verified'] ?? false,
      submittedBy: json['submitted_by'],
      approvedBy: json['approved_by'],
      notes: json['notes'],
      reliabilityScore: (json['reliability_score'] ?? 4.5).toDouble(),
      recentSuccessfulCharges: json['recent_charges'] ?? 0,
      amenities: json['amenities'] != null ? List<String>.from(json['amenities']) : [],
      supportsOffline: json['supports_offline'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'nb_bornes': nbBornes,
      'puissance_kw': puissanceKw,
      'type_prise': typePrise,
      'nb_points': nbPoints,
      'statut': statut,
      'encombrement': encombrement,
      'verified': verified,
      'submitted_by': submittedBy,
      'approved_by': approvedBy,
      'notes': notes,
      'reliability_score': reliabilityScore,
      'recent_charges': recentSuccessfulCharges,
      'amenities': amenities,
      'supports_offline': supportsOffline,
    };
  }
}
