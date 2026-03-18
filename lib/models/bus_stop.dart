import 'dart:math' as math;

class BusStop {
  final String name;
  final String operator;
  final double latitude;
  final double longitude;

  BusStop({
    required this.name,
    required this.operator,
    required this.latitude,
    required this.longitude,
  });

  factory BusStop.fromGeoJson(Map<String, dynamic> feature) {
    final coords = feature['geometry']['coordinates'] as List;
    final props = feature['properties'] as Map<String, dynamic>;
    return BusStop(
      name: props['n'] ?? '',
      operator: props['o'] ?? '',
      longitude: (coords[0] as num).toDouble(),
      latitude: (coords[1] as num).toDouble(),
    );
  }

  /// Haversine公式で2バス停間の直線距離をkm単位で返す
  double distanceTo(BusStop other) {
    const double earthRadius = 6371.0; // 地球半径 (km)
    final double dLat = _toRadians(other.latitude - latitude);
    final double dLng = _toRadians(other.longitude - longitude);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180.0;

  /// copyWithメソッド：一部フィールドを変更した新しいインスタンスを返す
  BusStop copyWith({
    String? name,
    String? operator,
    double? latitude,
    double? longitude,
  }) {
    return BusStop(
      name: name ?? this.name,
      operator: operator ?? this.operator,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
