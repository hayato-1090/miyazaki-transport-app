import 'package:flutter/material.dart';
import 'route_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.directions),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RouteScreen(directionsService: yourDirectionsService), // replace with actual parameter
                ),
              );
            },
          ),
        ],
      ),
      body: Center(child: Text('Welcome to Home Screen!')), 
    );
  }
}