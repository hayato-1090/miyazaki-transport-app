import 'package:flutter/material.dart';
import '../services/directions_service.dart';
import '../models/bus_stop.dart';
import '../services/bus_stop_service.dart';
import 'fare_calculator_screen.dart';

/// ルート検索画面
/// 出発地・目的地にバス停名のサジェストを表示し、推定料金も表示する
class RouteScreen extends StatefulWidget {
  final DirectionsService directionsService;
  final String? initialOrigin;
  final String? initialDestination;

  RouteScreen({
    required this.directionsService,
    this.initialOrigin,
    this.initialDestination,
  });

  @override
  _RouteScreenState createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  late TextEditingController originController;
  late TextEditingController destinationController;
  String selectedMode = 'driving';
  Map<String, dynamic>? routeResult;
  bool isLoading = false;

  final BusStopService _busStopService = BusStopService();
  List<BusStop> _allStops = [];

  // サジェスト表示用
  List<BusStop> _originSuggestions = [];
  List<BusStop> _destinationSuggestions = [];
  bool _showOriginSuggestions = false;
  bool _showDestinationSuggestions = false;

  @override
  void initState() {
    super.initState();
    originController = TextEditingController(text: widget.initialOrigin ?? '');
    destinationController = TextEditingController(text: widget.initialDestination ?? '');
    _loadBusStops();
  }

  Future<void> _loadBusStops() async {
    final stops = await _busStopService.loadBusStops();
    setState(() => _allStops = stops);
  }

  @override
  void dispose() {
    originController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  void _updateOriginSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _originSuggestions = [];
        _showOriginSuggestions = false;
      });
      return;
    }
    final lower = query.toLowerCase();
    final matched = _allStops
        .where((s) => s.name.toLowerCase().contains(lower))
        .take(5)
        .toList();
    setState(() {
      _originSuggestions = matched;
      _showOriginSuggestions = matched.isNotEmpty;
    });
  }

  void _updateDestinationSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _destinationSuggestions = [];
        _showDestinationSuggestions = false;
      });
      return;
    }
    final lower = query.toLowerCase();
    final matched = _allStops
        .where((s) => s.name.toLowerCase().contains(lower))
        .take(5)
        .toList();
    setState(() {
      _destinationSuggestions = matched;
      _showDestinationSuggestions = matched.isNotEmpty;
    });
  }

  void searchRoute() async {
    if (originController.text.isEmpty || destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('出発地と目的地を入力してください')),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await widget.directionsService.getDirections(
      origin: originController.text,
      destination: destinationController.text,
      mode: selectedMode,
    );

    setState(() {
      routeResult = result;
      isLoading = false;
    });
  }

  /// バス停間の推定料金を計算する（BusStopServiceの共通メソッドを使用）
  String? _estimateFare() {
    try {
      final origin = _allStops.firstWhere(
        (s) => s.name == originController.text,
      );
      final dest = _allStops.firstWhere(
        (s) => s.name == destinationController.text,
      );
      final dist = _busStopService.distanceBetween(origin, dest);
      final fare = _busStopService.estimateBusFare(dist);
      return '¥$fare（バス推定・直線${dist.toStringAsFixed(1)}km）';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ルート検索')),
      body: GestureDetector(
        onTap: () {
          // サジェストを閉じる
          setState(() {
            _showOriginSuggestions = false;
            _showDestinationSuggestions = false;
          });
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // --- 出発地 ---
            TextField(
              controller: originController,
              decoration: InputDecoration(
                labelText: '出発地',
                hintText: 'バス停名または住所を入力',
                prefixIcon: Icon(Icons.trip_origin, color: Colors.blue),
                border: OutlineInputBorder(),
              ),
              onChanged: (q) {
                _updateOriginSuggestions(q);
                setState(() => _showDestinationSuggestions = false);
              },
              onTap: () {
                if (originController.text.isNotEmpty) {
                  _updateOriginSuggestions(originController.text);
                }
              },
            ),
            // 出発地サジェスト
            if (_showOriginSuggestions)
              _buildSuggestionList(
                _originSuggestions,
                onSelect: (stop) {
                  setState(() {
                    originController.text = stop.name;
                    _showOriginSuggestions = false;
                    _originSuggestions = [];
                  });
                },
              ),
            SizedBox(height: 16),

            // --- 目的地 ---
            TextField(
              controller: destinationController,
              decoration: InputDecoration(
                labelText: '目的地',
                hintText: 'バス停名または住所を入力',
                prefixIcon: Icon(Icons.place, color: Colors.red),
                border: OutlineInputBorder(),
              ),
              onChanged: (q) {
                _updateDestinationSuggestions(q);
                setState(() => _showOriginSuggestions = false);
              },
              onTap: () {
                if (destinationController.text.isNotEmpty) {
                  _updateDestinationSuggestions(destinationController.text);
                }
              },
            ),
            // 目的地サジェスト
            if (_showDestinationSuggestions)
              _buildSuggestionList(
                _destinationSuggestions,
                onSelect: (stop) {
                  setState(() {
                    destinationController.text = stop.name;
                    _showDestinationSuggestions = false;
                    _destinationSuggestions = [];
                  });
                },
              ),
            SizedBox(height: 16),

            // --- 交通手段選択 ---
            DropdownButton<String>(
              value: selectedMode,
              isExpanded: true,
              items: const {
                'driving': '車',
                'transit': '電車・バス',
                'walking': '徒歩',
                'bicycling': '自転車',
              }.entries.map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  )).toList(),
              onChanged: (value) =>
                  setState(() => selectedMode = value ?? 'driving'),
            ),
            SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: isLoading ? null : searchRoute,
              icon: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.search),
              label: Text('ルートを検索'),
            ),
            SizedBox(height: 16),

            // --- 検索結果 ---
            if (routeResult != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '検索結果',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(),
                      if (routeResult!['status'] == 'OK') ...[
                        _resultRow(Icons.straighten, Colors.blue,
                            '距離', routeResult!['distance'] ?? 'N/A'),
                        SizedBox(height: 8),
                        _resultRow(Icons.access_time, Colors.orange,
                            '所要時間', routeResult!['duration'] ?? 'N/A'),
                        // バス停間の推定料金
                        Builder(builder: (_) {
                          final fare = _estimateFare();
                          if (fare == null) return SizedBox.shrink();
                          return Column(
                            children: [
                              SizedBox(height: 8),
                              _resultRow(Icons.attach_money, Colors.green,
                                  '推定料金', fare),
                            ],
                          );
                        }),
                        SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FareCalculatorScreen(
                                  initialOrigin: originController.text,
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.calculate),
                          label: Text('料金計算機で詳しく計算'),
                        ),
                      ] else ...[
                        Text(
                          'ルートが見つかりませんでした（${routeResult!['status']}）',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionList(
    List<BusStop> suggestions, {
    required void Function(BusStop) onSelect,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black12)],
      ),
      child: Column(
        children: suggestions.map((stop) {
          return ListTile(
            dense: true,
            leading: Icon(Icons.directions_bus, size: 18, color: Colors.green),
            title: Text(stop.name, style: TextStyle(fontSize: 14)),
            subtitle: Text(stop.operator, style: TextStyle(fontSize: 11)),
            onTap: () => onSelect(stop),
          );
        }).toList(),
      ),
    );
  }

  Widget _resultRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: Colors.grey[600])),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
