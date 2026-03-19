import 'package:latlong2/latlong.dart';

/// ルート上のコインモデル
class Coin {
  final String id;
  final LatLng position;
  bool isCollected;

  Coin({
    required this.id,
    required this.position,
    this.isCollected = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'lat': position.latitude,
        'lng': position.longitude,
        'isCollected': isCollected,
      };

  factory Coin.fromJson(Map<String, dynamic> json) => Coin(
        id: json['id'] as String,
        position: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lng'] as num).toDouble(),
        ),
        isCollected: json['isCollected'] as bool? ?? false,
      );
}
