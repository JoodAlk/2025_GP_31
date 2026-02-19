import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminBinManagement extends StatelessWidget {
  const AdminBinManagement({super.key});

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
              const Text("Bin Management", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              FloatingActionButton.small(
                backgroundColor: const Color(0xFF66BB6A),
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () { /* Add Bin Logic */ },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseDatabase.instance.ref('bins').onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text("No Bins Found"));
                }

                Map<dynamic, dynamic> binsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<MapEntry> binsList = binsMap.entries.toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text('Bin ID')),
                        DataColumn(label: Text('Fill Level')),
                        DataColumn(label: Text('Area')),
                        DataColumn(label: Text('Last Update')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: binsList.map((entry) {
                        final bin = entry.value;
                        final id = entry.key;
                        int fill = bin['FillLevel'] ?? 0;
                        
                        return DataRow(cells: [
                          DataCell(Text(id.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(
                            Row(children: [
                              Icon(Icons.circle, size: 12, 
                                color: fill > 90 ? Colors.red : (fill > 50 ? Colors.orange : Colors.green)),
                              const SizedBox(width: 8),
                              Text("$fill%"),
                            ]),
                          ),
                          DataCell(Text(bin['AreaId'] ?? 'N/A')),
                          DataCell(Text(bin['LastUpdate'] ?? 'N/A')),
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blue), onPressed: () {}),
                              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () {}),
                            ],
                          )),
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