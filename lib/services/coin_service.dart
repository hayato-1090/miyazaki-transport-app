import 'dart:convert';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coin.dart';
import '../models/quest.dart';
import '../data/quests_data.dart';

/// コインの配置計算・保存・取得と、ゲーム状態全体を管理するサービス
class CoinService {
  static final CoinService _instance = CoinService._internal();
  factory CoinService() => _instance;
  CoinService._internal();

  // コイン間隔（メートル）
  static const double _coinIntervalMeters = 300.0;
  // コイン獲得距離（メートル）
  static const double _collectRadiusMeters = 50.0;
  // 1コイン配置ポイントあたりの報酬
  static const int _coinsPerPoint = 2;

  List<Coin> _routeCoins = [];
  List<Quest> _quests = [];
  int _totalCoins = 0;
  double _totalDistanceKm = 0.0;
  int _routeCount = 0;
  int _busSearchCount = 0;
  String _selectedSkin = 'red';
  String _customAdMessage = '';
  bool _adUnlocked = false;

  List<Coin> get routeCoins => List.unmodifiable(_routeCoins);
  List<Quest> get quests => List.unmodifiable(_quests);
  int get totalCoins => _totalCoins;
  double get totalDistanceKm => _totalDistanceKm;
  int get routeCount => _routeCount;
  int get busSearchCount => _busSearchCount;
  String get selectedSkin => _selectedSkin;
  String get customAdMessage => _customAdMessage;
  bool get adUnlocked => _adUnlocked;

  // --- 初期化 ---

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _totalCoins = prefs.getInt('total_coins') ?? 0;
    _totalDistanceKm = prefs.getDouble('total_distance_km') ?? 0.0;
    _routeCount = prefs.getInt('route_count') ?? 0;
    _busSearchCount = prefs.getInt('bus_search_count') ?? 0;
    _selectedSkin = prefs.getString('selected_skin') ?? 'red';
    _customAdMessage = prefs.getString('custom_ad_message') ?? '';
    _adUnlocked = prefs.getBool('ad_unlocked') ?? false;
    _quests = _loadQuests(prefs);
  }

  List<Quest> _loadQuests(SharedPreferences prefs) {
    final quests = initialQuests();
    for (final q in quests) {
      q.currentCount = prefs.getInt('quest_count_${q.id}') ?? 0;
      q.isCompleted = prefs.getBool('quest_done_${q.id}') ?? false;
    }
    return quests;
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_coins', _totalCoins);
    await prefs.setDouble('total_distance_km', _totalDistanceKm);
    await prefs.setInt('route_count', _routeCount);
    await prefs.setInt('bus_search_count', _busSearchCount);
    await prefs.setString('selected_skin', _selectedSkin);
    await prefs.setString('custom_ad_message', _customAdMessage);
    await prefs.setBool('ad_unlocked', _adUnlocked);
    for (final q in _quests) {
      await prefs.setInt('quest_count_${q.id}', q.currentCount);
      await prefs.setBool('quest_done_${q.id}', q.isCompleted);
    }
  }

  // --- Polylineデコード（純正Dart実装） ---

  /// Google Directions APIのencoded polylineをデコードしてLatLngリストを返す
  List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  /// ポリライン上に等間隔（300m）でコインを配置する
  List<Coin> generateCoinsFromPolyline(String encodedPolyline) {
    final polylinePoints = decodePolyline(encodedPolyline);
    if (polylinePoints.isEmpty) return [];

    final coins = <Coin>[];
    double accumulated = 0.0;
    int coinIndex = 0;

    for (int i = 1; i < polylinePoints.length; i++) {
      final prev = polylinePoints[i - 1];
      final curr = polylinePoints[i];
      final segmentDist =
          _haversineMeters(prev.latitude, prev.longitude, curr.latitude, curr.longitude);

      double remaining = segmentDist;
      double fraction = 0.0;

      while (accumulated + remaining >= _coinIntervalMeters) {
        final needed = _coinIntervalMeters - accumulated;
        fraction += needed / segmentDist;
        fraction = fraction.clamp(0.0, 1.0);

        final coinLat = prev.latitude + (curr.latitude - prev.latitude) * fraction;
        final coinLng =
            prev.longitude + (curr.longitude - prev.longitude) * fraction;

        coins.add(Coin(
          id: 'coin_${coinIndex++}',
          position: LatLng(coinLat, coinLng),
        ));

        remaining -= needed;
        accumulated = 0.0;
      }
      accumulated += remaining;
    }

    return coins;
  }

  // --- ルートセット ---

  Future<void> setRouteCoins(String encodedPolyline) async {
    _routeCoins = generateCoinsFromPolyline(encodedPolyline);
    _routeCount++;
    await _incrementQuest('first_step', amount: 1);
    await _incrementQuest('walker', amount: 1);
    await _incrementQuest('explorer', amount: 1);
    await _saveState();
  }

  // --- コイン取得判定 ---

  /// GPS位置からコイン自動取得。取得したコインリストを返す
  Future<List<Coin>> checkAndCollectCoins(double lat, double lng) async {
    final collected = <Coin>[];
    bool changed = false;

    for (final coin in _routeCoins) {
      if (coin.isCollected) continue;
      final dist = _haversineMeters(
          lat, lng, coin.position.latitude, coin.position.longitude);
      if (dist <= _collectRadiusMeters) {
        coin.isCollected = true;
        _totalCoins += _coinsPerPoint;
        changed = true;
        collected.add(coin);
      }
    }

    if (changed) {
      // コインハンタークエスト更新（取得済みコインマーカー数でカウント）
      final coinHunterIdx = _quests.indexWhere((q) => q.id == 'coin_hunter');
      if (coinHunterIdx != -1 && !_quests[coinHunterIdx].isCompleted) {
        final collectedCount =
            _routeCoins.where((c) => c.isCollected).length;
        _quests[coinHunterIdx].currentCount =
            math.min(collectedCount, _quests[coinHunterIdx].targetCount);
        if (_quests[coinHunterIdx].currentCount >=
            _quests[coinHunterIdx].targetCount) {
          _quests[coinHunterIdx].isCompleted = true;
          _totalCoins += _quests[coinHunterIdx].rewardCoins;
        }
      }
      await _saveState();
    }
    return collected;
  }

  // --- バス検索カウント ---

  Future<void> recordBusSearch() async {
    _busSearchCount++;
    await _incrementQuest('bus_lover', amount: 1);
    await _saveState();
  }

  // --- ショップ: スキン購入・選択 ---

  Future<bool> purchaseSkin(String skinId, int price) async {
    if (_totalCoins < price) return false;
    final prefs = await SharedPreferences.getInstance();
    final owned = prefs.getStringList('owned_skins') ?? ['red'];
    if (!owned.contains(skinId)) {
      _totalCoins -= price;
      owned.add(skinId);
      await prefs.setStringList('owned_skins', owned);
    }
    _selectedSkin = skinId;
    await _saveState();
    return true;
  }

  Future<List<String>> getOwnedSkins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('owned_skins') ?? ['red'];
  }

  Future<bool> selectSkin(String skinId) async {
    final owned = await getOwnedSkins();
    if (!owned.contains(skinId)) return false;
    _selectedSkin = skinId;
    await _saveState();
    return true;
  }

  // --- ショップ: 広告枠購入 ---

  Future<bool> purchaseAd(String message) async {
    if (_adUnlocked) {
      _customAdMessage = message;
      await _saveState();
      return true;
    }
    if (_totalCoins < 500) return false;
    _totalCoins -= 500;
    _adUnlocked = true;
    _customAdMessage = message;
    await _saveState();
    return true;
  }

  // --- クエスト更新ヘルパー ---

  Future<void> _incrementQuest(String questId, {int amount = 1}) async {
    final idx = _quests.indexWhere((q) => q.id == questId);
    if (idx == -1 || _quests[idx].isCompleted) return;
    _quests[idx].currentCount = math.min(
        _quests[idx].currentCount + amount, _quests[idx].targetCount);
    if (_quests[idx].currentCount >= _quests[idx].targetCount) {
      _quests[idx].isCompleted = true;
      _totalCoins += _quests[idx].rewardCoins;
    }
  }

  // --- Haversine距離計算（メートル） ---

  double _haversineMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadiusM = 6371000.0;
    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lng2 - lng1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusM * c;
  }

  double _toRad(double deg) => deg * math.pi / 180.0;
}
