import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'web_frame.dart';

class AdminBinManagement extends StatefulWidget {
  const AdminBinManagement({super.key});

  @override
  State<AdminBinManagement> createState() => _AdminBinManagementState();
}

class _AdminBinManagementState extends State<AdminBinManagement> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('Baseer/bins');
  final List<String> _areas = ['Riyadh-01', 'Riyadh-02', 'Riyadh-03', 'Riyadh-04'];

  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController(text: "100");
  String _selectedArea = 'Riyadh-01';

  Color _getStatusColor(int fillLevel) {
    if (fillLevel >= 75) return Colors.red;
    if (fillLevel >= 50) return Colors.orange;
    return Colors.green;
  }

  void _showAddBinDialog() {
    _latController.clear();
    _lngController.clear();
    _capacityController.text = "100";
    _selectedArea = 'Riyadh-01';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          
          Future<void> createBin() async {
            final lat = double.tryParse(_latController.text.trim());
            final lng = double.tryParse(_lngController.text.trim());
            final capacity = int.tryParse(_capacityController.text.trim());

            if (lat == null || lng == null || capacity == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields with valid numbers"), backgroundColor: Colors.red));
              return;
            }

            final snapshot = await _dbRef.get();
            int nextNumber = 1;
            
            if (snapshot.exists) {
              nextNumber = snapshot.children.length + 1;
            }
            
            String binId = "BIN-${nextNumber.toString().padLeft(3, '0')}";
            
            DateTime now = DateTime.now();
            String formattedDate = "${now.day}/${now.month}/${now.year} at ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

            // Push to database
            await _dbRef.child(binId).set({
              "Name": binId,
              "AreaId": _selectedArea,
              "Capacity": capacity,
              "FreeSpace": capacity,     
              "FillLevel": 0,
              "IsAssigned": false,
              "IsOverflowing": false,
              "AssignedDriverId": "Unassigned",
              "Status": "OK", 
              "Location": {
                "Latitude": lat,
                "Longitude": lng,
              },
              "lastUpdate": formattedDate,
              "LastEmptied": formattedDate, 
              "Sensor": {
                "Id": "ESP-$binId",
                "Battery": 100
              }
            });

            if (!context.mounted) return;
            Navigator.pop(context);
            
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Success", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                content: const Text("Bin added successfully."),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
                ],
              )
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Register New Bin", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedArea,
                    decoration: const InputDecoration(labelText: "Zone / Area", prefixIcon: Icon(Icons.map)),
                    items: _areas.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (val) => setState(() => _selectedArea = val!),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _latController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Latitude", prefixIcon: Icon(Icons.location_on)))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _lngController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Longitude"))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(controller: _capacityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Capacity (CM)", prefixIcon: Icon(Icons.height))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: createBin,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784)),
                child: const Text("Add Bin", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteBin(String binKey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to remove $binKey from the system?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              _dbRef.child(binKey).remove();
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebFrame(
      activeIndex: 1, 
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Bin & Hardware Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _showAddBinDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Register New Bin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF81C784), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: StreamBuilder(
                  stream: _dbRef.onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: Text("No bins found."));

                    final rawValue = snapshot.data!.snapshot.value;
                    List<DataRow> rows = [];

                    if (rawValue is Map) {
                      rawValue.forEach((key, value) {
                        rows.add(_buildBinRow(key.toString(), value));
                      });
                    } else if (rawValue is List) {
                      for (int i = 0; i < rawValue.length; i++) {
                        if (rawValue[i] != null) {
                          rows.add(_buildBinRow(i.toString(), rawValue[i]));
                        }
                      }
                    }

                    return SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 40,
                        columns: const [
                          DataColumn(label: Text("Bin ID", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Area", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Fill Level", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Sensor Stats", style: TextStyle(fontWeight: FontWeight.bold))), 
                          DataColumn(label: Text("Assignment", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: rows,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildBinRow(String key, dynamic value) {
    int fillLevel = value['FillLevel'] ?? 0;
    // The isOverflowing variable is no longer used in the UI, so we can remove it.
    // bool isOverflowing = value['IsOverflowing'] == true;
    String hwStatus = value['Status'] ?? "OK";
    bool isAssigned = value['IsAssigned'] == true;

    return DataRow(cells: [
      DataCell(Text(value['Name'] ?? key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
      DataCell(Text(value['AreaId'] ?? 'N/A')),
      
      // Fill Level with Color Coding (Warning Icon Removed)
      DataCell(
        Row(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: _getStatusColor(fillLevel), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text("$fillLevel%", style: const TextStyle(fontWeight: FontWeight.bold)),
            // The code for the warning icon has been removed from here.
          ],
        )
      ),

      // Sensor Stats
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hwStatus.toUpperCase() == 'OK' ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(hwStatus, style: TextStyle(color: hwStatus.toUpperCase() == 'OK' ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
        )
      ),

      // Assignment Status
      DataCell(
        isAssigned 
          ? Text(value['AssignedDriverId'] ?? 'Assigned', style: const TextStyle(color: Colors.black87))
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Text("Needs Driver", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
            )
      ),

      // Delete Action
      DataCell(IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _deleteBin(key))),
    ]);
  }
}
