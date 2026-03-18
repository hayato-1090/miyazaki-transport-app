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
}
