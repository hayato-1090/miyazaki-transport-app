import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('宮崎の交通手段'), // Miyazaki Transportation Options
      ),
      body: GridView.count(
        crossAxisCount: 2,
        children: <Widget>[
          TransportCard(label: 'バス', icon: Icons.directions_bus), // Bus
          TransportCard(label: '電車', icon: Icons.directions_railway), // Train
          TransportCard(label: 'タクシー', icon: Icons.local_taxi), // Taxi
          TransportCard(label: '自転車', icon: Icons.pedal_bike), // Bicycle
        ],
      ),
    );
  }
}

class TransportCard extends StatelessWidget {
  final String label;
  final IconData icon;

  TransportCard({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 40),
          SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}