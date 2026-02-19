import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminDriverManagement extends StatelessWidget {
  const AdminDriverManagement({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Driver Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  FloatingActionButton.small(
                    heroTag: "btn1",
                    backgroundColor: Colors.redAccent,
                    onPressed: () {},
                    child: const Icon(Icons.remove, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton.small(
                    heroTag: "btn2",
                    backgroundColor: const Color(0xFF66BB6A),
                    onPressed: () {},
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref('drivers').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No Drivers Found"));
                }

                Map<dynamic, dynamic> driversMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<MapEntry> driverList = driversMap.entries.toList();

                return SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('Driver ID')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Assigned Area')),
                        DataColumn(label: Text('Phone')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: driverList.map((entry) {
                        final driver = entry.value;
                        final id = driver['DriverID'] ?? entry.key;

                        return DataRow(cells: [
                          DataCell(Text(id.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(driver['Name'] ?? 'N/A')),
                          DataCell(Text(driver['AssignedArea'] ?? 'N/A')),
                          DataCell(Text(driver['Phone'] ?? 'N/A')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: driver['IsWorking'] == true ? Colors.green.shade100 : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: Text(
                                driver['IsWorking'] == true ? 'Active' : 'Offline',
                                style: TextStyle(color: driver['IsWorking'] == true ? Colors.green.shade800 : Colors.grey.shade800),
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}