// lib/driver_route_loader_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../bin_model.dart'; 
import 'driver_map.dart';
import 'driver_route_planner.dart';
import 'driver_user_session.dart';

class DriverRouteLoaderPage extends StatefulWidget {
  const DriverRouteLoaderPage({super.key});

  @override
  State<DriverRouteLoaderPage> createState() => _DriverRouteLoaderPageState();
}

class _DriverRouteLoaderPageState extends State<DriverRouteLoaderPage> {
  @override
  void initState() {
    super.initState();
    _buildAndGo();
  }

  Future<void> _buildAndGo() async {
    final selectedArea = UserSession.selectedAreaFilter;

    if (selectedArea == 'All') {
      _showError('Please select an Area first from the filter on Home.');
      return;
    }

    try {
      final snap = await FirebaseDatabase.instance.ref('Baseer/bins').get();

      if (!snap.exists || snap.value == null) {
        _showError('No bins found in the database.');
        return;
      }

      final raw = snap.value as Map<dynamic, dynamic>;
      final bins = <Bin>[];

      raw.forEach((key, value) {
        if (value is Map) {
          final b = Bin.fromRTDB(Map.from(value), key.toString());

          // Filter by selected area
          if (b.areaId == selectedArea) {
            bins.add(b);
          }
        }
      });

      if (bins.isEmpty) {
        _showError('No bins found in: $selectedArea');
        return;
      }

      final planner = RoutePlanner();

      // 1) Sort by priority: FillLevel desc, LastEmptied asc
      final prioritySorted = planner.sortByPriority(List.of(bins));

      // 2) Start route from the FIRST priority bin, then order the rest
      final route = planner.buildRouteStartingFromFirstPriority(prioritySorted);

      if (!mounted) return;

      // 3) Navigate to Map and pass the ordered route
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DriverMapPage(
            routeBins: route,
            selectedArea: selectedArea,
          ),
        ),
      );
    } catch (e) {
      _showError('Failed to build route: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

    // Return to previous screen (Home)
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Building your route...'),
          ],
        ),
      ),
    );
  }
}
