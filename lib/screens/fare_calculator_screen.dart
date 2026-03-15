import 'package:flutter/material.dart';

class FareCalculatorScreen extends StatefulWidget {
  @override
  _FareCalculatorScreenState createState() => _FareCalculatorScreenState();
}

class _FareCalculatorScreenState extends State<FareCalculatorScreen> {
  String? selectedTransport;
  String? selectedDistance;
  int fare = 0;
  int time = 0;

  final Map<String, Map<String, dynamic>> transportData = {
    'バス': {
      'baseFare': 100,
      'perKm': 50,
      'speed': 30,
    },
    '電車': {
      'baseFare': 150,
      'perKm': 40,
      'speed': 60,
    },
    'タクシー': {
      'baseFare': 600,
      'perKm': 80,
      'speed': 40,
    },
    '自転車': {
      'baseFare': 0,
      'perKm': 0,
      'speed': 15,
    },
  };

  final List<String> distances = ['1km', '5km', '10km', '20km', '50km'];

  void calculateFare() {
    if (selectedTransport == null || selectedDistance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('交通手段と距離を選択してください')),
      );
      return;
    }

    int km = int.parse(selectedDistance!.replaceAll('km', ''));
    var data = transportData[selectedTransport]!;

    setState(() {
      if (selectedTransport == '自転車') {
        fare = 0;
      } else {
        fare = (data['baseFare'] + (km * data['perKm'])).toInt();
      }
      time = ((km / data['speed']) * 60).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('料金計算機'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            SizedBox(height: 20),
            Text('交通手段を選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            DropdownButton<String>(
              isExpanded: true,
              hint: Text('交通手段を選択'),
              value: selectedTransport,
              onChanged: (String? newValue) {
                setState(() {
                  selectedTransport = newValue;
                });
              },
              items: transportData.keys.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 30),
            Text('距離を選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            DropdownButton<String>(
              isExpanded: true,
              hint: Text('距離を選択'),
              value: selectedDistance,
              onChanged: (String? newValue) {
                setState(() {
                  selectedDistance = newValue;
                });
              },
              items: distances.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: calculateFare,
              child: Text('料金を計算', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Colors.green,
              ),
            ),
            SizedBox(height: 40),
            if (fare > 0 || selectedTransport == '自転車' && selectedDistance != null)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '料金: ¥$fare',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    SizedBox(height: 15),
                    Text(
                      '所要時間: ${time}分',
                      style: TextStyle(fontSize: 20, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
