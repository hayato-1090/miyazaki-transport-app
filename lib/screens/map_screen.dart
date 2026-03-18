import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/bus_stop.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  String _currentAddress = '住所を取得中...';
  bool _isLoading = true;
  Set<Marker> _markers = {};
  Set<Marker> _busStopMarkers = {};

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
      final jsonString = await rootBundle.loadString('assets/bus_stops/miyazaki_bus_stops.json');
      final geoJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final features = geoJson['features'] as List<dynamic>;

      final markers = <Marker>{};
      for (int i = 0; i < features.length; i++) {
        final stop = BusStop.fromGeoJson(features[i] as Map<String, dynamic>);
        markers.add(
          Marker(
            markerId: MarkerId('bus_stop_$i'),
            position: LatLng(stop.latitude, stop.longitude),
            infoWindow: InfoWindow(
              title: stop.name,
              snippet: stop.operator,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
      String address = await _getAddressFromLatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        _isLoading = false;
        _markers = {
          Marker(
            markerId: MarkerId('current_location'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: InfoWindow(
              title: '現在地',
              snippet: address,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        };
      });

      // 地図を現在地に移動
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
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
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('現在地マップ'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _defaultPosition,
              zoom: 14.0,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      zoom: 15.0,
                    ),
                  ),
                );
              }
            },
            markers: {..._markers, ..._busStopMarkers},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),
          // 住所表示カード
          Positioned(
            bottom: 80,
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
