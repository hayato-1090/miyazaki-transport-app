import 'package:flutter/material.dart';

class FareCalculatorScreen extends StatefulWidget {
  @override
  _FareCalculatorScreenState createState() => _FareCalculatorScreenState();
}

class _FareCalculatorScreenState extends State<FareCalculatorScreen> {
  String _transportationMethod = 'Bus';
  double _distance = 0.0;

  final Map<String, double> _fareRates = {
    'Bus': 1.5,
    'Train': 2.0,
    'Taxi': 2.5,
  };

  double _calculatedFare = 0.0;
  String _travelTime = '';

  void _calculateFare() {
    setState(() {
      _calculatedFare = _fareRates[_transportationMethod]! * _distance;
      _travelTime = (_distance / 30).toStringAsFixed(2) + ' hours'; // Assuming an average speed of 30 km/h
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fare Calculator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _transportationMethod,
              onChanged: (String? newValue) {
                setState(() {
                  _transportationMethod = newValue!;
                });
              },
              items: _fareRates.keys.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Distance (km)'),
              onChanged: (value) {
                _distance = double.tryParse(value) ?? 0.0;
              },
            ),
            ElevatedButton(
              onPressed: _calculateFare,
              child: Text('Calculate'),
            ),
            SizedBox(height: 20),
            Text('Calculated Fare: \\$${_calculatedFare.toStringAsFixed(2)}'),
            Text('Estimated Travel Time: $_travelTime'),
          ],
        ),
      ),
    );
  }
}