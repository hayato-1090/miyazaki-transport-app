import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteScreen extends StatelessWidget {
  final String origin;
  final String destination;

  RouteScreen({required this.origin, required this.destination});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route Display'),
      ),
      body: Center(
        child: Text('Display routes from $origin to $destination using DirectionsService.'),
      ),
    );
  }

  // Add your DirectionsService integration and routing logic here
}