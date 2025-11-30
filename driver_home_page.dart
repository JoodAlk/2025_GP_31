import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'bin_model.dart';
import 'app_frame.dart';

// --- 1. The Dashboard Screen ---
class BinDashboardScreen extends StatefulWidget {
  const BinDashboardScreen({super.key});

  @override
  State<BinDashboardScreen> createState() => _BinDashboardScreenState();
}

class _BinDashboardScreenState extends State<BinDashboardScreen> {
  // === STATE VARIABLE FOR FILTERING ===
  String _selectedAreaFilter = 'All';

  // --- PRIORITY SORTER HELPER ---
  int _prioritySorter(Bin a, Bin b) {
    bool aIsAssigned = a.isAssigned;
    bool bIsAssigned = b.isAssigned;

    if (aIsAssigned != bIsAssigned) {
      return aIsAssigned ? 1 : -1;
    }
    return b.fillLevel.compareTo(a.fillLevel);
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference binsRef =
        FirebaseDatabase.instance.ref('Baseer/bins');

    return AppFrame(
      currentIndex: 1,
      child: StreamBuilder(
        stream: binsRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          }

          List<Bin> allBins = [];
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final Map<dynamic, dynamic> data =
                snapshot.data!.snapshot.value as Map;
            data.forEach((key, value) {
              if (value is Map) {
                allBins.add(Bin.fromRTDB(Map.from(value), key.toString()));
              }
            });
          }

          final Set<String> uniqueAreas = allBins
              .map((b) => b.areaId)
              .where((id) => id.isNotEmpty && id != 'Unknown Area')
              .toSet();

          final List<String> dynamicAreaOptions = [
            'All',
            ...uniqueAreas.toList()..sort()
          ];

          if (!dynamicAreaOptions.contains(_selectedAreaFilter)) {
            _selectedAreaFilter = 'All';
          }

          List<Bin> displayBins = List.from(allBins);

          if (_selectedAreaFilter != 'All') {
            displayBins =
                displayBins.where((bin) => bin.areaId == _selectedAreaFilter).toList();
          }

          displayBins.sort(_prioritySorter);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.grey.shade100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter (${displayBins.length} bins)',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    _buildDropdown(
                      context,
                      'Select Area',
                      dynamicAreaOptions,
                      _selectedAreaFilter,
                      (newValue) =>
                          setState(() => _selectedAreaFilter = newValue!),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: displayBins.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_off,
                                size: 40, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(allBins.isEmpty
                                ? 'No bins in database.'
                                : 'No bins found in: $_selectedAreaFilter'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        itemCount: displayBins.length,
                        itemBuilder: (context, index) {
                          return BinListItem(bin: displayBins[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, String hint, List<String> items,
      String selectedValue, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(selectedValue) ? selectedValue : items.first,
          hint: Text(hint),
          style: TextStyle(
              color: Colors.teal.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600),
          icon: Icon(Icons.location_on, color: Theme.of(context).primaryColor),
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// --- 2. The Bin Card Widget ---
class BinListItem extends StatelessWidget {
  final Bin bin;
  const BinListItem({super.key, required this.bin});

  void _showBinDetails(BuildContext context) {
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
    
    // --- LAYOUT CONSTANT UPDATED ---
    // Increased from 140.0 to 160.0 to fit "Assigned Driver:" in one line
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: labelWidth,
                      child: Text('Fill Level:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: Text(
                        '${bin.fillLevel}%',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: bin.statusColor),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              _buildDetailRow(Icons.inventory_2_outlined, 'Capacity:', capacityText, context, labelWidth),
              const SizedBox(height: 10),
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
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

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
    bool isAssigned = bin.isAssigned;
    Color assignColor = isAssigned ? Colors.green : Colors.red;
    String assignText = isAssigned ? "Assigned" : "Not Assigned";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(color: bin.statusColor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Icon(
                bin.isOverflowing ? Icons.delete_forever : Icons.delete_outline,
                color: bin.statusColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bin.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF008080),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Area: ${bin.areaId}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: assignColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(color: assignColor, width: 1),
                            ),
                            child: Text(
                              assignText.toUpperCase(),
                              style: TextStyle(color: assignColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: bin.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(color: bin.statusColor, width: 1),
                            ),
                            child: Text(
                              bin.statusText.toUpperCase(),
                              style: TextStyle(color: bin.statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert, color: Colors.grey),
                              onPressed: () => _showBinDetails(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12), 
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: bin.fillLevel / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: bin.statusColor,
                      minHeight: 8, 
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}