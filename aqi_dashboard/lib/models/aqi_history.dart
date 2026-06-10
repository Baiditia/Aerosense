class AqiHistoryRecord {
  final String location;
  final int pm25;
  final double lat;
  final double lon;
  final DateTime recordedAt;

  AqiHistoryRecord({
    required this.location,
    required this.pm25,
    required this.lat,
    required this.lon,
    required this.recordedAt,
  });

  String get statusLabel {
    if (pm25 <= 50) return 'Udara Bersih';
    if (pm25 <= 100) return 'Kualitas Sedang';
    if (pm25 <= 150) return 'Tidak Sehat';
    return 'Sangat Berbahaya';
  }

  Map<String, dynamic> toMap() {
    return {
      'location': location,
      'pm25': pm25,
      'lat': lat,
      'lon': lon,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  factory AqiHistoryRecord.fromMap(Map<String, dynamic> map) {
    return AqiHistoryRecord(
      location: map['location'] ?? '',
      pm25: map['pm25'] ?? 0,
      lat: (map['lat'] ?? 0).toDouble(),
      lon: (map['lon'] ?? 0).toDouble(),
      recordedAt: DateTime.parse(map['recordedAt']),
    );
  }
}
