import 'package:flutter/material.dart';
import '../models/bus_stop.dart';
import '../services/bus_stop_service.dart';
import 'route_screen.dart';
import '../services/directions_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 料金計算画面
/// バス停を出発・到着で選択し、距離を自動計算して料金・所要時間を表示する
class FareCalculatorScreen extends StatefulWidget {
  /// 初期出発バス停名（他画面からの遷移時に使用）
  final String? initialOrigin;

  const FareCalculatorScreen({Key? key, this.initialOrigin}) : super(key: key);

  @override
  _FareCalculatorScreenState createState() => _FareCalculatorScreenState();
}

class _FareCalculatorScreenState extends State<FareCalculatorScreen> {
  final BusStopService _busStopService = BusStopService();

  List<BusStop> _busStops = [];
  bool _isLoading = true;

  BusStop? _originStop;
  BusStop? _destinationStop;

  // 選択中の交通手段（複数選択可）
  final Set<String> _selectedModes = {'バス'};

  // 計算結果
  Map<String, _FareResult>? _results;

  @override
  void initState() {
    super.initState();
    _loadBusStops();
  }

  Future<void> _loadBusStops() async {
    final stops = await _busStopService.loadBusStops();
    setState(() {
      _busStops = stops;
      _isLoading = false;
      // 初期出発バス停の設定
      if (widget.initialOrigin != null) {
        try {
          _originStop = _busStops.firstWhere(
            (s) => s.name == widget.initialOrigin,
          );
        } catch (_) {}
      }
    });
  }

  /// 宮崎交通の運賃体系に近い料金計算
  Map<String, _FareResult> _calculateFares(double distanceKm) {
    final results = <String, _FareResult>{};

    // --- バス: BusStopServiceの共通メソッドで計算 ---
    if (_selectedModes.contains('バス')) {
      final fare = _busStopService.estimateBusFare(distanceKm);
      final timeMin = (distanceKm / 25.0 * 60).round(); // 平均時速25km
      results['バス'] = _FareResult(fare: fare, timeMin: timeMin, distance: distanceKm);
    }

    // --- 電車: 初乗り150円、区間制（参考値） ---
    if (_selectedModes.contains('電車')) {
      int fare;
      if (distanceKm <= 3.0) {
        fare = 150;
      } else if (distanceKm <= 10.0) {
        fare = 230;
      } else if (distanceKm <= 20.0) {
        fare = 420;
      } else if (distanceKm <= 50.0) {
        fare = 770;
      } else {
        fare = 1100;
      }
      final timeMin = (distanceKm / 50.0 * 60).round(); // 平均時速50km
      results['電車'] = _FareResult(fare: fare, timeMin: timeMin, distance: distanceKm);
    }

    // --- タクシー: 初乗り500円（1.5kmまで）、以降237mごと90円（宮崎市内目安） ---
    // 237mは宮崎市内タクシーの加算距離の目安
    if (_selectedModes.contains('タクシー')) {
      int fare;
      if (distanceKm <= 1.5) {
        fare = 500;
      } else {
        final extraMeters = (distanceKm - 1.5) * 1000;
        fare = 500 + (extraMeters / 237).ceil() * 90;
      }
      final timeMin = (distanceKm / 35.0 * 60).round(); // 平均時速35km
      results['タクシー'] = _FareResult(fare: fare, timeMin: timeMin, distance: distanceKm);
    }

    // --- 自転車: 無料（所要時間のみ） ---
    if (_selectedModes.contains('自転車')) {
      final timeMin = (distanceKm / 15.0 * 60).round(); // 平均時速15km
      results['自転車'] = _FareResult(fare: 0, timeMin: timeMin, distance: distanceKm);
    }

    return results;
  }

  void _onCalculate() {
    if (_originStop == null || _destinationStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('出発バス停と到着バス停を選択してください')),
      );
      return;
    }
    if (_selectedModes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('交通手段を1つ以上選択してください')),
      );
      return;
    }
    final dist = _busStopService.distanceBetween(_originStop!, _destinationStop!);
    setState(() {
      _results = _calculateFares(dist);
    });
  }

  /// バス停選択ダイアログ
  Future<BusStop?> _showBusStopPicker(String title) async {
    final TextEditingController searchCtrl = TextEditingController();
    List<BusStop> filtered = List.from(_busStops);

    return showDialog<BusStop>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setInner) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'バス停名を検索',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (q) {
                      setInner(() {
                        final lower = q.toLowerCase();
                        filtered = _busStops
                            .where((s) => s.name.toLowerCase().contains(lower))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final stop = filtered[i];
                        return ListTile(
                          leading: const Icon(Icons.directions_bus, color: Colors.green),
                          title: Text(stop.name),
                          subtitle: Text(stop.operator),
                          onTap: () => Navigator.pop(ctx, stop),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('キャンセル'),
              ),
            ],
          );
        });
      },
    );
  }

  // 交通手段の設定
  static const _modeIcons = {
    'バス': Icons.directions_bus,
    '電車': Icons.directions_railway,
    'タクシー': Icons.local_taxi,
    '自転車': Icons.pedal_bike,
  };

  static const _modeColors = {
    'バス': Color(0xFFE65100),
    '電車': Color(0xFF1565C0),
    'タクシー': Color(0xFFF9A825),
    '自転車': Color(0xFF2E7D32),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('料金計算機'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- バス停選択セクション ---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'バス停を選択',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 出発バス停
                        InkWell(
                          onTap: () async {
                            final stop = await _showBusStopPicker('出発バス停を選択');
                            if (stop != null) setState(() => _originStop = stop);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.trip_origin,
                                    color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _originStop?.name ?? '出発バス停を選択',
                                    style: TextStyle(
                                      color: _originStop != null
                                          ? Colors.black87
                                          : Colors.grey,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down,
                                    color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 交換ボタン
                        Center(
                          child: IconButton(
                            icon: const Icon(Icons.swap_vert,
                                color: Color(0xFF1565C0)),
                            tooltip: '出発・到着を入れ替え',
                            onPressed: () {
                              setState(() {
                                final tmp = _originStop;
                                _originStop = _destinationStop;
                                _destinationStop = tmp;
                                _results = null;
                              });
                            },
                          ),
                        ),
                        // 到着バス停
                        InkWell(
                          onTap: () async {
                            final stop = await _showBusStopPicker('到着バス停を選択');
                            if (stop != null) {
                              setState(() => _destinationStop = stop);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.place,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _destinationStop?.name ?? '到着バス停を選択',
                                    style: TextStyle(
                                      color: _destinationStop != null
                                          ? Colors.black87
                                          : Colors.grey,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down,
                                    color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        // 距離表示
                        if (_originStop != null && _destinationStop != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.straighten,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '直線距離: ${_busStopService.distanceBetween(_originStop!, _destinationStop!).toStringAsFixed(1)}km',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- 交通手段選択（Chipグループ）---
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '交通手段を選択',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: _modeIcons.entries.map((entry) {
                            final selected = _selectedModes.contains(entry.key);
                            final color = _modeColors[entry.key]!;
                            return FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(entry.value,
                                      size: 16,
                                      color: selected ? Colors.white : color),
                                  const SizedBox(width: 4),
                                  Text(entry.key),
                                ],
                              ),
                              selected: selected,
                              selectedColor: color,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                              ),
                              onSelected: (val) {
                                setState(() {
                                  if (val) {
                                    _selectedModes.add(entry.key);
                                  } else {
                                    _selectedModes.remove(entry.key);
                                  }
                                  _results = null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- 計算ボタン ---
                ElevatedButton.icon(
                  onPressed: _onCalculate,
                  icon: const Icon(Icons.calculate),
                  label: const Text(
                    '料金を計算',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // --- 計算結果 ---
                if (_results != null) ...[
                  const Text(
                    '計算結果',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._results!.entries.map((e) => _buildResultCard(e.key, e.value)),
                  const SizedBox(height: 16),

                  // --- ルート検索へのボタン ---
                  OutlinedButton.icon(
                    onPressed: () {
                      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteScreen(
                            directionsService: DirectionsService(apiKey: apiKey),
                            initialOrigin: _originStop?.name,
                            initialDestination: _destinationStop?.name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.route),
                    label: const Text('ルート検索へ'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildResultCard(String mode, _FareResult result) {
    final color = _modeColors[mode]!;
    final icon = _modeIcons[mode]!;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // 左カラーバー
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: color, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          mode,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _resultItem(
                          Icons.attach_money,
                          Colors.green,
                          '料金',
                          mode == '自転車' ? '無料' : '¥${result.fare}',
                        ),
                        _resultItem(
                          Icons.straighten,
                          Colors.blue,
                          '距離',
                          '${result.distance.toStringAsFixed(1)}km',
                        ),
                        _resultItem(
                          Icons.access_time,
                          Colors.orange,
                          '所要時間',
                          '約${result.timeMin}分',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultItem(
      IconData icon, Color color, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// 料金計算結果データクラス
class _FareResult {
  final int fare;
  final int timeMin;
  final double distance;

  _FareResult({
    required this.fare,
    required this.timeMin,
    required this.distance,
  });
}
