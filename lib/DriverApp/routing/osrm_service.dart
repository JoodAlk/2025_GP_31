import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmService {
  static const _base = 'https://router.project-osrm.org';

  Future<List<LatLng>> routeBetween(LatLng a, LatLng b) async {
    final url = Uri.parse(
      '$_base/route/v1/driving/'
      '${a.longitude},${a.latitude};${b.longitude},${b.latitude}'
      '?overview=full&geometries=geojson',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('OSRM failed: ${res.statusCode}');
    }

    final json = jsonDecode(res.body);
    final coords = (json['routes'][0]['geometry']['coordinates'] as List);

    // GeoJSON coords are [lng, lat]
    return coords
        .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
        .toList();
  }

  Future<List<LatLng>> routeForStops(List<LatLng> stops) async {
    if (stops.length < 2) return stops;

    final all = <LatLng>[];
    for (int i = 0; i < stops.length - 1; i++) {
      final seg = await routeBetween(stops[i], stops[i + 1]);
      if (i == 0) {
        all.addAll(seg);
      } else {
        all.addAll(seg.skip(1));
      }
    }
    return all;
  }
}
