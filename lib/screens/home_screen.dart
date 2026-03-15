import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/directions_service.dart';
import 'detail_screen.dart';
import 'fare_calculator_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DirectionsService directionsService;
  
  @override
  void initState() {
    super.initState();
    // API キーを .env から読み込む
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
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.calculate),
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
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(8),
        children: <Widget>[
          TransportCard(
            label: 'バス',
            icon: Icons.directions_bus,
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
            icon: Icons.directions_railway,
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
            icon: Icons.local_taxi,
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
            icon: Icons.pedal_bike,
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
    );
  }
}

class TransportCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  TransportCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50, color: Colors.blue),
            SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
