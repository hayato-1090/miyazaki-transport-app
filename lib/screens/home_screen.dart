import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/directions_service.dart';
import '../services/bus_stop_service.dart';
import '../services/coin_service.dart';
import '../models/bus_stop.dart';
import 'detail_screen.dart';
import 'fare_calculator_screen.dart';
import 'route_screen.dart';
import 'map_screen.dart';
import 'quest_screen.dart';
import 'shop_screen.dart';
import 'profile_screen.dart';

/// ホーム画面
/// 5タブのボトムナビゲーション付きメイン画面
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
          const QuestScreen(),
          const ShopScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'マップ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'クエスト',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'ショップ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフィール',
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
  final CoinService _coinService = CoinService();
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
    final stops = await _busStopService.loadBusStops();
    setState(() {
      _nearbyStops = stops.take(3).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('宮崎の交通手段'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // コイン枚数表示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '${_coinService.totalCoins}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- 広告バナー or グラデーションバナー ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1565C0), Color(0xFF29B6F6)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '宮崎市の交通案内',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _coinService.adUnlocked && _coinService.customAdMessage.isNotEmpty
                      ? _coinService.customAdMessage
                      : '目的地に合わせて最適な交通手段を選ぼう',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // --- コンパクト操作ボタン行 ---
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _CompactButton(
                    icon: Icons.directions_bus,
                    label: 'バス検索',
                    color: const Color(0xFFE65100),
                    onTap: () {
                      _coinService.recordBusSearch();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteScreen(
                            directionsService: widget.directionsService,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompactButton(
                    icon: Icons.pedal_bike,
                    label: '自転車検索',
                    color: const Color(0xFF2E7D32),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailScreen(
                            transportDetails: transportDetails['自転車']!,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CompactButton(
                    icon: Icons.calculate,
                    label: '料金計算',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FareCalculatorScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // --- 近くのバス停横スクロールリスト ---
          if (_nearbyStops.isNotEmpty)
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '近くのバス停',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
              padding: const EdgeInsets.all(16),
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
                  color: const Color(0xFFE65100),
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
                  color: const Color(0xFF1565C0),
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
                  color: const Color(0xFFF9A825),
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
                  color: const Color(0xFF2E7D32),
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

/// コンパクト操作ボタン
class _CompactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CompactButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
      margin: const EdgeInsets.symmetric(horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 130,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bus,
                      color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      stop.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priceHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey[500]),
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

