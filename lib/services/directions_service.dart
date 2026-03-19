import 'dart:convert';
import 'package:http/http.dart' as http;

class DirectionsService {
  // apiKey is kept for API compatibility but is no longer used.
  // Routing is handled by OSRM and geocoding by Nominatim (both CORS-safe).
  final String apiKey;

  DirectionsService({required this.apiKey});

  static const _userAgent = 'miyazaki-transport-app';

  /// Geocode a place name / address using Nominatim.
  Future<Map<String, double>?> _geocode(String query) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1&accept-language=ja',
      );
      final response =
          await http.get(uri, headers: {'User-Agent': _userAgent});
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final lat = double.parse(list[0]['lat'] as String);
          final lon = double.parse(list[0]['lon'] as String);
          return {'lat': lat, 'lon': lon};
        }
      }
    } catch (e) {
      print('[DirectionsService] Geocode error for "$query": $e');
    }
    return null;
  }

  /// Convert Flutter transport mode string to an OSRM profile.
  /// Note: 'transit' is mapped to 'driving' because OSRM does not support
  /// public-transit routing. Results for transit queries will reflect
  /// driving distances/durations.
  String _osrmProfile(String mode) {
    switch (mode) {
      case 'walking':
        return 'foot';
      case 'bicycling':
        return 'bike';
      case 'transit':
      case 'driving':
      default:
        return 'driving';
    }
  }

  Future<Map<String, dynamic>?> getDirections({
    required String origin,
    required String destination,
    String mode = 'driving',
  }) async {
    try {
      // 1. Geocode origin and destination via Nominatim
      final originCoords = await _geocode(origin);
      if (originCoords == null) {
        print('[DirectionsService] Failed to geocode origin: $origin');
        return {'status': 'ERROR', 'error': '出発地の座標が取得できませんでした: $origin'};
      }

      final destCoords = await _geocode(destination);
      if (destCoords == null) {
        print('[DirectionsService] Failed to geocode destination: $destination');
        return {'status': 'ERROR', 'error': '目的地の座標が取得できませんでした: $destination'};
      }

      // 2. Call OSRM routing API
      final profile = _osrmProfile(mode);
      final url =
          'https://router.project-osrm.org/route/v1/$profile/${originCoords['lon']},${originCoords['lat']};${destCoords['lon']},${destCoords['lat']}?overview=full&geometries=polyline&steps=true';

      print('[DirectionsService] OSRM URL: $url');

      final response =
          await http.get(Uri.parse(url), headers: {'User-Agent': _userAgent});

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['code'] == 'Ok' &&
            (json['routes'] as List).isNotEmpty) {
          final route = json['routes'][0];
          final distanceMeters = (route['distance'] as num).toDouble();
          final durationSeconds = (route['duration'] as num).toDouble();

          final distanceKm = distanceMeters / 1000.0;
          final durationMin = (durationSeconds / 60.0).round();

          final distanceText = '${distanceKm.toStringAsFixed(1)} km';
          final durationText = durationMin >= 60
              ? '${durationMin ~/ 60}時間${durationMin % 60}分'
              : '$durationMin分';

          print(
              '[DirectionsService] Success: distance=$distanceText, duration=$durationText');
          return {
            'status': 'OK',
            'distance': distanceText,
            'duration': durationText,
            'polyline': route['geometry'] as String,
          };
        } else {
          print('[DirectionsService] OSRM Error: ${json['code']}');
          return {'status': 'ERROR', 'error': json['code']};
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
