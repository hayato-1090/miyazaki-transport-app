import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/bus_stop.dart';

/// バス停データの読み込みと検索ロジックを一元管理するサービスクラス
class BusStopService {
  // シングルトンインスタンス
  static final BusStopService _instance = BusStopService._internal();
  factory BusStopService() => _instance;
  BusStopService._internal();

  // キャッシュ済みバス停リスト
  List<BusStop>? _cachedStops;

  /// JSONファイルからBusStopリストをロード（キャッシュ対応）
  Future<List<BusStop>> loadBusStops() async {
    if (_cachedStops != null) return _cachedStops!;

    try {
      final jsonString =
          await rootBundle.loadString('assets/bus_stops/miyazaki_bus_stops.json');
      final geoJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final features = geoJson['features'] as List<dynamic>;

      _cachedStops = features
          .map((f) => BusStop.fromGeoJson(f as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // JSONの読み込みまたはパースに失敗した場合は空リストを返す
      debugPrint('[BusStopService] バス停データの読み込みに失敗しました: $e');
      _cachedStops = [];
    }

    return _cachedStops!;
  }

  /// キャッシュをクリアする（テスト用）
  void clearCache() {
    _cachedStops = null;
  }

  /// 名前でのバス停検索（部分一致）
  Future<List<BusStop>> searchByName(String query) async {
    if (query.isEmpty) return [];
    final stops = await loadBusStops();
    final lower = query.toLowerCase();
    return stops
        .where((s) => s.name.toLowerCase().contains(lower))
        .toList();
  }

  /// 現在地から最近接バス停を距離計算で返す（上位limit件）
  Future<List<BusStopWithDistance>> findNearest(
    double lat,
    double lng, {
    int limit = 3,
  }) async {
    final stops = await loadBusStops();

    final withDist = stops.map((s) {
      final dist = _haversine(lat, lng, s.latitude, s.longitude);
      return BusStopWithDistance(busStop: s, distanceKm: dist);
    }).toList();

    withDist.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return withDist.take(limit).toList();
  }

  /// 2バス停間の直線距離をkm単位で返す（Haversine公式）
  double distanceBetween(BusStop a, BusStop b) {
    return _haversine(a.latitude, a.longitude, b.latitude, b.longitude);
  }

  /// バス運賃の推定計算（宮崎交通の運賃体系に近い参考値）
  /// 初乗り170円（2kmまで）、以降1kmごと約40円加算
  int estimateBusFare(double distanceKm) {
    if (distanceKm <= 2.0) return 170;
    return 170 + ((distanceKm - 2.0).ceil() * 40);
  }

  /// Haversine公式による距離計算（km）
  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371.0;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * math.pi / 180.0;
}

/// バス停と距離情報をまとめたデータクラス
class BusStopWithDistance {
  final BusStop busStop;
  final double distanceKm;

  BusStopWithDistance({required this.busStop, required this.distanceKm});

  /// 距離を人間が読みやすい形式に変換
  String get distanceText {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()}m';
    }
    return '${distanceKm.toStringAsFixed(1)}km';
  }
}
