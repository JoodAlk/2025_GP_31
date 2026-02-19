import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';

import '../bin_model.dart'; 
import 'app_frame.dart';
import 'routing/osrm_service.dart';

class DriverMapPage extends StatefulWidget {
  final List<Bin>? routeBins;
  final String? selectedArea;

  const DriverMapPage({super.key, this.routeBins, this.selectedArea});

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage> {
  final _osrm = OsrmService();

  List<LatLng>? _roadPolyline; // road-following points
  String? _routeError;

  @override
  void initState() {
    super.initState();
    _buildRoadPolylineIfNeeded();
  }

  @override
  void didUpdateWidget(covariant DriverMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeBins != widget.routeBins) {
      _buildRoadPolylineIfNeeded();
    }
  }

  Future<void> _buildRoadPolylineIfNeeded() async {
    // Only build road polyline when we are in "route mode"
    final bins = widget.routeBins;
    if (bins == null || bins.length < 2) {
      setState(() {
        _roadPolyline = null;
        _routeError = null;
      });
      return;
    }

    setState(() {
      _roadPolyline = null;
      _routeError = null;
    });

    try {
      final stops = bins.map((b) => LatLng(b.latitude, b.longitude)).toList();
      final poly = await _osrm.routeForStops(stops);

      if (!mounted) return;
      setState(() => _roadPolyline = poly);
    } catch (e) {
      if (!mounted) return;
      setState(() => _routeError = 'Road routing failed: $e');
    }
  }

  void _showBinDetails(BuildContext context, Bin bin) {
    final String capacityText = '${bin.capacity} CM';

    String formatTimestamp(String timestamp) {
      try {
        final dateTime = DateTime.parse(timestamp);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return timestamp;
      }
    }

    final String lastEmptiedFormatted = formatTimestamp(bin.lastEmptied);
    final String lastUpdateFormatted = formatTimestamp(bin.lastUpdate);

    const double labelWidth = 160.0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Bin Details: ${bin.id}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: labelWidth,
                      child: Text(
                        'Fill Level:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${bin.fillLevel}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: bin.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _buildDetailRow(Icons.inventory_2_outlined, 'Capacity:', capacityText, context, labelWidth),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.history, 'Last Emptied:', lastEmptiedFormatted, context, labelWidth),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.update, 'Last Update:', lastUpdateFormatted, context, labelWidth),
              const SizedBox(height: 10),
              _buildDetailRow(
                Icons.location_on,
                'Location:',
                'Lat ${bin.latitude.toStringAsFixed(4)}, Lng ${bin.longitude.toStringAsFixed(4)}',
                context,
                labelWidth,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.person, 'Assigned Driver:', bin.assignedDriverId, context, labelWidth),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String title,
    String value,
    BuildContext context,
    double labelWidth,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      currentIndex: 3,
      child: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('Baseer/bins').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No bin locations found.'));
          }

          // Parse all bins
          final raw = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Bin> allBins = [];
          raw.forEach((key, value) {
            if (value is Map) {
              allBins.add(Bin.fromRTDB(Map.from(value), key.toString()));
            }
          });

          // If routeBins passed, show those. Otherwise show all bins.
          final List<Bin> binsToShow = widget.routeBins ?? allBins;

          if (binsToShow.isEmpty) {
            return const Center(child: Text('No bins to display.'));
          }

          final first = binsToShow.first;

          // Markers (numbered in route mode)
          final List<Marker> markers = [];
          for (int i = 0; i < binsToShow.length; i++) {
            final bin = binsToShow[i];

            markers.add(
              Marker(
                width: 60,
                height: 60,
                point: LatLng(bin.latitude, bin.longitude),
                child: GestureDetector(
                  onTap: () => _showBinDetails(context, bin),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.delete, color: bin.statusColor, size: 38),
                      if (widget.routeBins != null)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              if (widget.routeBins != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Route for area: ${widget.selectedArea ?? ''} (${binsToShow.length} stops)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_roadPolyline == null && _routeError == null)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              if (_routeError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.red.shade50,
                  child: Text(_routeError!, style: TextStyle(color: Colors.red.shade800)),
                ),
              Expanded(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(first.latitude, first.longitude),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.baseer',
                    ),

                    // ✅ Road-following polyline if available
                    if (widget.routeBins != null && _roadPolyline != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(points: _roadPolyline!, strokeWidth: 4),
                        ],
                      ),

                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
