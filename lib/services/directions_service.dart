import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class DirectionsService {
  // API キーは .env から読み込む
  final String apiKey;

  DirectionsService({required this.apiKey});

  /// 出発地から目的地までのルート情報を取得
  /// [origin]: 出発地 (緯度,経度 または 住所)
  /// [destination]: 目的地 (緯度,経度 または 住所)
  /// [mode]: 移動手段 (driving, transit, walking, bicycling)
  Future<Map<String, dynamic>?> getDirections({
    required String origin,
    required String destination,
    String mode = 'driving',
  }) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=
$origin'
          '&destination=$destination'
          '&mode=$mode'
          '&key=
$apiKey'
          '&language=ja';

      developer.log('Directions API URL: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == 'OK' && json['routes'].isNotEmpty) {
          return {
            'status': 'OK',
            'routes': json['routes'],
            'distance': json['routes'][0]['legs'][0]['distance']['text'],
            'duration': json['routes'][0]['legs'][0]['duration']['text'],
            'polyline': json['routes'][0]['overview_polyline']['points'],
          };
        } else {
          developer.log('API Error: ${json['status']}');
          return {'status': json['status'], 'error': json['error_message']};
        }
      } else {
        developer.log('HTTP Error: ${response.statusCode}');
        return {'status': 'ERROR', 'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      developer.log('Exception: $e');
      return {'status': 'ERROR', 'error': e.toString()};
    }
  }

  /// 複数の移動手段を比較
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