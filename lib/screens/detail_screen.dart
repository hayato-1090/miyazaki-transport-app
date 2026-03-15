import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final String transportDetails;

  DetailScreen({required this.transportDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transportation Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          transportDetails,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}