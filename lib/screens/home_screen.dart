import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/directions_service.dart';
import 'detail_screen.dart';
import 'fare_calculator_screen.dart';
import 'route_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DirectionsService directionsService;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    directionsService = DirectionsService(apiKey: apiKey);
  }

  final Map<String, String> transportDetails = {
    'バス': '宮崎市内を走る主要なバス路線\n・運行本数：1時間に複数本\n・料金：100円～300円\n・営業時間：5:00～23:00',
    '電車': '宮崎交通線で運行\n・駅数：20駅以上\n・料金：150円～500円\n・営業時間：6:00～22:00',
    'タクシー': '宮崎市内のタクシー\n・初乗り：600円\n・24時間営業\n・予約可能',
    '自転車': 'レンタル自転車サービス\n・1日利用：500円\n・ステーション：市内20箇所以上\n・営業時間：7:00～20:00',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('宮崎の交通手段'),
        backgroundColor: Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            tooltip: '現在地マップ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.route),
            tooltip: 'ルート検索',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RouteScreen(directionsService: directionsService),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.calculate),
            tooltip: '料金計算',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FareCalculatorScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '宮崎市の交通案内',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '目的地に合わせて最適な交通手段を選ぼう',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(16),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
              children: <Widget>[
                TransportCard(
                  label: 'バス',
                  description: '市内全域をカバー',
                  priceHint: '¥100〜',
                  icon: Icons.directions_bus,
                  color: Colors.orange,
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
                TransportCard(
                  label: '電車',
                  description: '駅間を素早く移動',
                  priceHint: '¥150〜',
                  icon: Icons.directions_railway,
                  color: Colors.blue,
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
                TransportCard(
                  label: 'タクシー',
                  description: 'ドアツードアで便利',
                  priceHint: '¥600〜',
                  icon: Icons.local_taxi,
                  color: Colors.amber,
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
                TransportCard(
                  label: '自転車',
                  description: 'エコで健康的な移動',
                  priceHint: '¥500/日',
                  icon: Icons.pedal_bike,
                  color: Colors.green,
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

class TransportCard extends StatelessWidget {
  final String label;
  final String description;
  final String priceHint;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  TransportCard({
    Key? key,
    required this.label,
    required this.description,
    required this.priceHint,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6),
              Text(
                priceHint,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
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
