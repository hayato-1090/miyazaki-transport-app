import 'package:flutter/material.dart';
import '../services/directions_service.dart';

class RouteScreen extends StatefulWidget {
  final DirectionsService directionsService;

  RouteScreen({required this.directionsService});

  @override
  _RouteScreenState createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final TextEditingController originController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();
  String selectedMode = 'driving';
  Map<String, dynamic>? routeResult;
  bool isLoading = false;

  @override
  void dispose() {
    originController.dispose();
    destinationController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ルート検索')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          TextField(
            controller: originController,
            decoration: InputDecoration(
              labelText: '出発地',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: destinationController,
            decoration: InputDecoration(
              labelText: '目的地',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16),
          DropdownButton<String>(
            value: selectedMode,
            items: ['driving', 'transit', 'walking', 'bicycling']
                .map((mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(mode),
                    ))
                .toList(),
            onChanged: (value) => setState(() => selectedMode = value ?? 'driving'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: isLoading ? null : searchRoute,
            child: isLoading ? CircularProgressIndicator() : Text('ルートを検索'),
          ),
          SizedBox(height: 16),
          if (routeResult != null)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('距離: ${routeResult!['distance'] ?? 'N/A'}'),
                    Text('所要時間: ${routeResult!['duration'] ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
