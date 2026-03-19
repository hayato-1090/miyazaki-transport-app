import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/coin.dart';
import 'coin_service.dart';

/// バックグラウンドGPS監視とコイン自動取得を担当するサービス
class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  final CoinService _coinService = CoinService();
  StreamSubscription<Position>? _positionSubscription;

  /// コイン取得時のコールバック（UI更新用）
  void Function(List<Coin> collected)? onCoinsCollected;

  bool get isTracking => _positionSubscription != null;

  /// GPS追跡を開始する
  Future<void> startTracking() async {
    if (_positionSubscription != null) return;

    // 権限確認
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // 20m移動したら更新（コイン取得半径50mを考慮）
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings)
            .listen((position) async {
      final collected = await _coinService.checkAndCollectCoins(
        position.latitude,
        position.longitude,
      );
      if (collected.isNotEmpty) {
        onCoinsCollected?.call(collected);
      }
    });
  }

  /// GPS追跡を停止する
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
