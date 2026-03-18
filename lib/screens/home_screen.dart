import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/directions_service.dart';
import '../services/bus_stop_service.dart';
import '../models/bus_stop.dart';
import 'detail_screen.dart';
import 'fare_calculator_screen.dart';
import 'route_screen.dart';
import 'map_screen.dart';

/// ホーム画面
/// ボトムナビゲーション付きのメイン画面
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late DirectionsService directionsService;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    directionsService = DirectionsService(apiKey: apiKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(directionsService: directionsService),
          MapScreen(),
          FareCalculatorScreen(),
          RouteScreen(directionsService: directionsService),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '地図',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: '料金計算',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'ルート',
          ),
        ],
      ),
    );
  }
}

/// ホームタブの中身
class _HomeTab extends StatefulWidget {
  final DirectionsService directionsService;
  const _HomeTab({required this.directionsService});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final BusStopService _busStopService = BusStopService();
  List<BusStop> _nearbyStops = [];

  final Map<String, String> transportDetails = {
    'バス': '宮崎市内を走る主要なバス路線\n・運行本数：1時間に複数本\n・料金：170円～\n・営業時間：5:00～23:00',
    '電車': '宮崎交通線で運行\n・駅数：20駅以上\n・料金：150円～\n・営業時間：6:00～22:00',
    'タクシー': '宮崎市内のタクシー\n・初乗り：500円（1.5kmまで）\n・24時間営業\n・予約可能',
    '自転車': 'レンタル自転車サービス\n・1日利用：500円\n・ステーション：市内20箇所以上\n・営業時間：7:00～20:00',
  };

  @override
  void initState() {
    super.initState();
    _loadNearbyStops();
  }

  Future<void> _loadNearbyStops() async {
    // 現在地が取得できない場合はデフォルトの最初の3件を表示
    final stops = await _busStopService.loadBusStops();
    setState(() {
      _nearbyStops = stops.take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('宮崎の交通手段'),
        backgroundColor: Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- グラデーションバナー ---
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF29B6F6)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '宮崎市の交通案内',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '目的地に合わせて最適な交通手段を選ぼう',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // --- 近くのバス停横スクロールリスト ---
          if (_nearbyStops.isNotEmpty)
            Container(
              color: Colors.grey.shade100,
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '近くのバス停',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _nearbyStops.length,
                      itemBuilder: (_, i) {
                        final stop = _nearbyStops[i];
                        return _NearbyBusStopChip(
                          stop: stop,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FareCalculatorScreen(
                                  initialOrigin: stop.name,
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

          // --- 交通手段グリッド ---
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(16),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: <Widget>[
                _TransportCard(
                  label: 'バス',
                  description: '市内全域をカバー',
                  priceHint: '¥170〜',
                  detail: '営業時間 5:00〜23:00',
                  icon: Icons.directions_bus,
                  color: Color(0xFFE65100),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          transportDetails: transportDetails['バス']!,
                        ),
                      ),
                    );
                  },
                ),
                _TransportCard(
                  label: '電車',
                  description: '駅間を素早く移動',
                  priceHint: '¥150〜',
                  detail: '営業時間 6:00〜22:00',
                  icon: Icons.directions_railway,
                  color: Color(0xFF1565C0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          transportDetails: transportDetails['電車']!,
                        ),
                      ),
                    );
                  },
                ),
                _TransportCard(
                  label: 'タクシー',
                  description: 'ドアツードアで便利',
                  priceHint: '¥500〜',
                  detail: '24時間営業',
                  icon: Icons.local_taxi,
                  color: Color(0xFFF9A825),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          transportDetails: transportDetails['タクシー']!,
                        ),
                      ),
                    );
                  },
                ),
                _TransportCard(
                  label: '自転車',
                  description: 'エコで健康的な移動',
                  priceHint: '¥500/日',
                  detail: '営業時間 7:00〜20:00',
                  icon: Icons.pedal_bike,
                  color: Color(0xFF2E7D32),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          transportDetails: transportDetails['自転車']!,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 近くのバス停チップ
class _NearbyBusStopChip extends StatelessWidget {
  final BusStop stop;
  final VoidCallback onTap;

  const _NearbyBusStopChip({required this.stop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 130,
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_bus, color: Colors.green, size: 14),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      stop.name,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                '料金計算 →',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 交通手段カード（ホーム画面専用）
class _TransportCard extends StatelessWidget {
  final String label;
  final String description;
  final String priceHint;
  final String detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TransportCard({
    Key? key,
    required this.label,
    required this.description,
    required this.priceHint,
    required this.detail,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // トップカラーバー
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 34, color: color),
                    ),
                    SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 3),
                    Text(
                      description,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      priceHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      detail,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
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
}
