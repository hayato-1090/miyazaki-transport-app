import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/bus_stop.dart';
import '../services/bus_stop_service.dart';
import 'fare_calculator_screen.dart';

/// 地図画面
/// バス停マーカー・現在地・最近接バス停パネルを表示する
class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  String _currentAddress = '住所を取得中...';
  bool _isLoading = true;
  List<Marker> _markers = [];
  List<Marker> _busStopMarkers = [];

  // バス停の表示/非表示トグル
  bool _showBusStops = true;

  // 最近接バス停リスト
  List<BusStopWithDistance> _nearestStops = [];

  final BusStopService _busStopService = BusStopService();

  // 宮崎市役所をデフォルト位置に設定
  static const LatLng _defaultPosition = LatLng(31.9077, 131.4202);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadBusStops();
  }

  Future<void> _loadBusStops() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/bus_stops/miyazaki_bus_stops.json');
      final geoJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final features = geoJson['features'] as List<dynamic>;

      final markers = <Marker>[];
      for (int i = 0; i < features.length; i++) {
        final stop = BusStop.fromGeoJson(features[i] as Map<String, dynamic>);
        markers.add(
          Marker(
            point: LatLng(stop.latitude, stop.longitude),
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FareCalculatorScreen(initialOrigin: stop.name),
                  ),
                );
              },
              child: Tooltip(
                message: '${stop.name}　ここから料金計算 →',
                child: Icon(Icons.directions_bus, color: Colors.green, size: 24),
              ),
            ),
          ),
        );
      }

      setState(() {
        _busStopMarkers = markers;
      });
    } catch (e) {
      // 読み込み失敗時はマーカーなしで続行
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      // 位置情報の権限チェック
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoading = false;
            _currentAddress = '位置情報の権限が拒否されました';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _currentAddress = '位置情報の権限が永久に拒否されています。設定から変更してください。';
        });
        return;
      }

      // 現在地を取得
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 逆ジオコーディングで住所を取得
      String address =
          await _getAddressFromLatLng(position.latitude, position.longitude);

      // 最近接バス停を検索
      final nearest = await _busStopService.findNearest(
        position.latitude,
        position.longitude,
        limit: 3,
      );

      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        _isLoading = false;
        _nearestStops = nearest;
        _markers = [
          Marker(
            point: LatLng(position.latitude, position.longitude),
            width: 40,
            height: 40,
            child: Tooltip(
              message: '現在地: $address',
              child: Icon(Icons.location_pin, color: Colors.blue, size: 36),
            ),
          ),
        ];
      });

      // 地図を現在地に移動
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentAddress = '位置情報の取得に失敗しました: $e';
      });
    }
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
      if (apiKey.isEmpty) return '($lat, $lng)';

      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey&language=ja';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK' && json['results'].isNotEmpty) {
          return json['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      // エラー時は座標を返す
    }
    return '緯度: $lat, 経度: $lng';
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _defaultPosition;

    return Scaffold(
      appBar: AppBar(
        title: Text('現在地マップ'),
        backgroundColor: Colors.blue,
        actions: [
          // バス停表示トグルボタン
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Material(
              color: _showBusStops
                  ? Colors.white.withOpacity(0.25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _showBusStops = !_showBusStops),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_bus,
                        color: Colors.white,
                        size: 20,
                      ),
                      Text(
                        _showBusStops ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLatLng,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.miyazaki_transport_app',
              ),
              MarkerLayer(
                markers: [
                  ..._markers,
                  ...(_showBusStops ? _busStopMarkers : []),
                ],
              ),
            ],
          ),

          // 住所表示カード（最近接バス停がある場合は上に位置）
          Positioned(
            bottom: _nearestStops.isNotEmpty ? 200 : 80,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: _isLoading
                          ? Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('現在地を取得中...'),
                              ],
                            )
                          : Text(
                              _currentAddress,
                              style: TextStyle(fontSize: 13),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 最近接バス停カード
          if (_nearestStops.isNotEmpty)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      '近くのバス停',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _nearestStops.length,
                      itemBuilder: (_, i) {
                        final item = _nearestStops[i];
                        return _NearestStopCard(
                          stop: item.busStop,
                          distance: item.distanceText,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FareCalculatorScreen(
                                  initialOrigin: item.busStop.name,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: Semantics(
        label: _isLoading ? '現在地を取得中...' : '現在地を取得',
        button: true,
        child: FloatingActionButton(
          onPressed: _isLoading ? null : _getCurrentLocation,
          backgroundColor: Colors.blue,
          child: _isLoading
              ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Icon(Icons.my_location),
          tooltip: '現在地を取得',
        ),
      ),
    );
  }
}

/// 最近接バス停ミニカード
class _NearestStopCard extends StatelessWidget {
  final BusStop stop;
  final String distance;
  final VoidCallback onTap;

  const _NearestStopCard({
    Key? key,
    required this.stop,
    required this.distance,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140,
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_bus, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      stop.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                distance,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
              SizedBox(height: 4),
              Text(
                '料金計算 →',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
