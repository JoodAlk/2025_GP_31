import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'bin_model.dart'; // 1. Importing the shared Bin model
import 'app_frame.dart';

class DriverMapPage extends StatelessWidget {
  const DriverMapPage({super.key});

  // --- 2. REUSED POPUP LOGIC (Same as Home Page) ---
  void _showBinDetails(BuildContext context, Bin bin) {
    final String capacityText = '${bin.capacity} CM';

    String formatTimestamp(String timestamp) {
      try {
        final dateTime = DateTime.parse(timestamp);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return timestamp;
      }
    }

    final String lastEmptiedFormatted = formatTimestamp(bin.lastEmptied);
    final String lastUpdateFormatted = formatTimestamp(bin.lastUpdate);
    
    // Label width for alignment
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
              // Fill Level Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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

              // Details
              _buildDetailRow(Icons.inventory_2_outlined, 'Capacity:', capacityText, context, labelWidth),
              const SizedBox(height: 10),

              // Sensor
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Row(
                      children: [
                        Icon(Icons.sensors, color: Theme.of(context).primaryColor, size: 20),
                        const SizedBox(width: 8),
                        const Text('Sensor:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text('${bin.sensorId} (${bin.status})', style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              const Divider(),
              _buildDetailRow(Icons.history, 'Last Emptied:', lastEmptiedFormatted, context, labelWidth),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.update, 'Last Update:', lastUpdateFormatted, context, labelWidth),
              const SizedBox(height: 10),
              const Divider(),
              _buildDetailRow(Icons.location_on, 'Location:', 'Lat ${bin.latitude.toStringAsFixed(4)}, Lng ${bin.longitude.toStringAsFixed(4)}', context, labelWidth),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.person, 'Assigned Driver:', bin.assignedDriverId, context, labelWidth),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Helper for rows
  Widget _buildDetailRow(IconData icon, String title, String value, BuildContext context, double labelWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Flexible(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFrame(
      currentIndex: 3,
      child: StreamBuilder<DatabaseEvent>(
        // Use the exact same path as the Home Page
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

          // --- 3. PARSE DATA USING BIN MODEL ---
          final Map<dynamic, dynamic> raw = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Bin> bins = [];
          
          raw.forEach((key, value) {
            if (value is Map) {
              // Using the factory from bin_model.dart
              bins.add(Bin.fromRTDB(Map.from(value), key.toString()));
            }
          });

          if (bins.isEmpty) {
            return const Center(child: Text('No bins to display.'));
          }

          // Center map on the first bin
          final first = bins.first;

          final List<Marker> markers = bins.map<Marker>((bin) {
            return Marker(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              point: LatLng(bin.latitude, bin.longitude),
              child: GestureDetector(
                onTap: () {
                  // Call the detailed popup function
                  _showBinDetails(context, bin);
                },
                child: Icon(
                  Icons.delete, // Trash bin icon
                  color: bin.statusColor, // Uses the model's logic (Red/Orange/Green)
                  size: 35,
                ),
              ),
            );
          }).toList();

          return FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(first.latitude, first.longitude),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.baseer',
              ),
              MarkerLayer(
                markers: markers,
              ),
            ],
          );
        },
      ),
    );
  }
}