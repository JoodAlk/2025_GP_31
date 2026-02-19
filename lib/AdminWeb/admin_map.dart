import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';

import 'web_frame.dart'; 
import '../bin_model.dart'; 

class AdminMapPage extends StatefulWidget {
  const AdminMapPage({super.key});

  @override
  State<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends State<AdminMapPage> {
  final MapController _mapController = MapController();

  // Matches Driver App color logic
  Color _getStatusColor(int fillLevel) {
    if (fillLevel >= 75) return Colors.red;
    if (fillLevel >= 50) return Colors.orange;
    return Colors.green;
  }

  // Matches the exact "Bin Details" popup from your screenshot
  void _showBinDetails(BuildContext context, Map<dynamic, dynamic> data, String id) {
    final int fill = data['FillLevel'] ?? 0;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.all(20),
        title: Text('Bin Details: $id', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large Fill Level Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fill Level:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                Text('$fill%', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _getStatusColor(fill))),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailItem(Icons.inventory_2_outlined, 'Capacity:', '${data['Capacity'] ?? 0} CM'),
            _buildDetailItem(Icons.sensors, 'Sensor:', '${data['Sensor']?['Id'] ?? "N/A"} (${data['Status'] ?? "OK"})'),
            const Divider(height: 30),
            _buildDetailItem(Icons.history, 'Last Emptied:', data['LastEmptied'] ?? 'N/A'),
            _buildDetailItem(Icons.update, 'Last Update:', data['lastUpdate'] ?? 'N/A'),
            _buildDetailItem(Icons.location_on_outlined, 'Location:', 'Lat ${data['Location']?['Latitude']}, Lng ${data['Location']?['Longitude']}'),
            _buildDetailItem(Icons.person_outline, 'Assigned Driver:', data['AssignedDriverId'] ?? 'Unassigned'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF81C784)), // Using your signature green
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebFrame(
      activeIndex: 2, 
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('Baseer/bins').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No bins found in database."));
          }

          final rawBins = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Marker> markers = [];
          
          rawBins.forEach((id, data) {
            if (data['Location'] != null) {
              final lat = data['Location']['Latitude'];
              final lng = data['Location']['Longitude'];
              final fill = data['FillLevel'] ?? 0;

              markers.add(
                Marker(
                  point: LatLng(lat, lng),
                  width: 60,
                  height: 60,
                  child: GestureDetector(
                    onTap: () => _showBinDetails(context, data, id),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Icon(
                        Icons.delete, // Matches Driver App trash can icon
                        color: _getStatusColor(fill),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              );
            }
          });

          return FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(24.7136, 46.6753),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.baseer',
              ),
              MarkerLayer(markers: markers),
            ],
          );
        },
      ),
    );
  }
}
