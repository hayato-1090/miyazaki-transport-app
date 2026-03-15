import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectionsService {
  final String apiKey;

  DirectionsService({required this.apiKey});

  Future<Map<String, dynamic>?> getDirections({
    required String origin,
    required String destination,
    String mode = 'driving',
  }) async {
    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=$mode&key=$apiKey&language=ja';

      print('[DirectionsService] Directions API URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
          print('[DirectionsService] Success: distance=${json['routes'][0]['legs'][0]['distance']['text']}');
          return {
            'status': 'OK',
            'routes': json['routes'],
            'distance': json['routes'][0]['legs'][0]['distance']['text'],
            'duration': json['routes'][0]['legs'][0]['duration']['text'],
            'polyline': json['routes'][0]['overview_polyline']['points'],
          };
        } else {
          print('[DirectionsService] API Error: ${json['status']} - ${json['error_message'] ?? 'No error message'}');
          return {'status': json['status'], 'error': json['error_message']};
        }
      } else {
        print('[DirectionsService] HTTP Error: ${response.statusCode}');
        return {'status': 'ERROR', 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      print('[DirectionsService] Exception: $e');
      return {'status': 'ERROR', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> compareTransportModes({
    required String origin,
    required String destination,
  }) async {
    final modes = ['driving', 'transit', 'walking', 'bicycling'];
    final results = <String, Map<String, dynamic>>{};

    for (String mode in modes) {
      final result = await getDirections(
        origin: origin,
        destination: destination,
        mode: mode,
      );
      results[mode] = result ?? {'status': 'ERROR'};
    }

    return results;
  }
}
