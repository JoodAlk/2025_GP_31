import 'dart:math';
import '../bin_model.dart'; 

class RoutePlanner {
  DateTime _parseDate(String s) {
    return DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Priority sort: FillLevel desc, then LastEmptied asc (older first)
  List<Bin> sortByPriority(List<Bin> bins) {
    bins.sort((a, b) {
      final fill = b.fillLevel.compareTo(a.fillLevel);
      if (fill != 0) return fill;

      final aD = _parseDate(a.lastEmptied);
      final bD = _parseDate(b.lastEmptied);
      return aD.compareTo(bD);
    });
    return bins;
  }

  /// Route starts from the FIRST priority bin, then orders the rest
  /// using a priority-aware nearest-neighbor.
  List<Bin> buildRouteStartingFromFirstPriority(List<Bin> bins) {
    if (bins.isEmpty) return [];

    // Make sure bins are already priority-sorted before calling
    final route = <Bin>[];
    final remaining = List<Bin>.from(bins);

    // 1) First stop = highest priority
    final first = remaining.removeAt(0);
    route.add(first);

    var curLat = first.latitude;
    var curLng = first.longitude;

    double priorityScore(Bin b) {
      final hours = DateTime.now().difference(_parseDate(b.lastEmptied)).inHours;
      return (b.fillLevel * 10.0) + min(hours.toDouble(), 240.0);
    }

    // 2) Choose next stops balancing distance + priority
    while (remaining.isNotEmpty) {
      Bin best = remaining.first;
      double bestValue = double.infinity;

      for (final b in remaining) {
        final d = _haversineKm(curLat, curLng, b.latitude, b.longitude);
        final p = priorityScore(b);

        // Lower is better
        final value = d - (p * 0.002); // tweak if needed
        if (value < bestValue) {
          bestValue = value;
          best = b;
        }
      }

      route.add(best);
      remaining.remove(best);
      curLat = best.latitude;
      curLng = best.longitude;
    }

    return route;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);
}
