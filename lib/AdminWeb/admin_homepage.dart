import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'web_frame.dart'; 

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('Baseer');

  // -- Data Processing Helpers --

  int _calculateActiveDrivers(dynamic driversData) {
    if (driversData == null) return 0;
    int count = 0;
    if (driversData is List) {
      for (var driver in driversData) {
        if (driver != null && driver is Map && driver['IsWorking'] == true) count++;
      }
    }
    return count;
  }

  int _calculateUrgentBins(Map<dynamic, dynamic> bins) {
    int count = 0;
    bins.forEach((k, v) {
      bool isUnassigned = v['IsAssigned'] == false;
      // UPDATED: Critical threshold is now 75%
      bool isFull = v['IsOverflowing'] == true || (v['FillLevel'] ?? 0) >= 75;
      if (isUnassigned && isFull) count++;
    });
    return count;
  }

  int _calculateOfflineSensors(Map<dynamic, dynamic> bins) {
    int count = 0;
    bins.forEach((k, v) {
      if (v['Status'] != null && v['Status'].toString().toUpperCase() != 'OK') {
        count++;
      }
    });
    return count;
  }

  Map<String, double> _getBinStatusStats(Map<dynamic, dynamic> bins) {
    double empty = 0, half = 0, full = 0;
    bins.forEach((k, v) {
      int fill = v['FillLevel'] ?? 0;
      // UPDATED: Critical threshold is now 75%
      if (fill < 50) empty++; else if (fill < 75) half++; else full++;
    });
    return {'Safe': empty, 'Warning': half, 'Critical': full};
  }

  Map<String, Map<String, int>> _getBinsStatusPerArea(Map<dynamic, dynamic> bins) {
    Map<String, Map<String, int>> areas = {};
    bins.forEach((k, v) {
      String area = v['AreaId'] ?? 'Unknown';
      int fill = (v['FillLevel'] ?? 0).toInt();
      areas.putIfAbsent(area, () => {'Safe': 0, 'Warning': 0, 'Critical': 0});

      // UPDATED: Critical threshold is now 75%
      if (fill >= 75) {
        areas[area]!['Critical'] = areas[area]!['Critical']! + 1;
      } else if (fill >= 50) {
        areas[area]!['Warning'] = areas[area]!['Warning']! + 1;
      } else {
        areas[area]!['Safe'] = areas[area]!['Safe']! + 1;
      }
    });
    return areas;
  }

  List<Map<String, dynamic>> _generateAlerts(Map<dynamic, dynamic> bins) {
    List<Map<String, dynamic>> alerts = [];
    bins.forEach((k, v) {
      // UPDATED: Critical threshold is now 75%
      bool isCritical = (v['FillLevel'] ?? 0) >= 75;
      bool isOffline = v['Status'] != null && v['Status'].toString().toUpperCase() != 'OK';
      bool isOverflowing = v['IsOverflowing'] == true;
      bool isUnassigned = v['IsAssigned'] == false;

      if (isCritical || isOffline || isOverflowing) {
        String reason = "";
        Color color = Colors.redAccent;
        IconData icon = Icons.warning_amber_rounded;

        if (isOffline) {
          reason = "Sensor Offline / Error";
          color = Colors.blueGrey;
          icon = Icons.wifi_off_rounded;
        } else if (isOverflowing) {
          // UPDATED: Name changed to just "Overflow Detected"
          reason = "Overflow Detected";
          color = Colors.red;
          icon = Icons.delete_forever;
        } else {
          reason = "Critical Fill Level (${v['FillLevel']}%)";
          color = Colors.orange.shade800;
          icon = Icons.priority_high;
        }

        alerts.add({
          'id': k,
          'name': v['Name'] ?? 'Unknown Bin',
          'area': v['AreaId'] ?? 'Unknown Area',
          'reason': reason,
          'color': color,
          'icon': icon,
          'time': v['lastUpdate'] ?? 'Just now',
          'unassigned': isUnassigned,
        });
      }
    });
    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    return WebFrame(
      activeIndex: 0, 
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("Loading Database...")); 
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final bins = data['bins'] as Map<dynamic, dynamic>? ?? {};
          final drivers = data['drivers'];

          final activeDrivers = _calculateActiveDrivers(drivers);
          final totalBins = bins.length;
          final urgentCount = _calculateUrgentBins(bins); 
          final offlineCount = _calculateOfflineSensors(bins); 
          
          final statusStats = _getBinStatusStats(bins);
          final areaStatusData = _getBinsStatusPerArea(bins);
          final alertsList = _generateAlerts(bins); 

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 400, 
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildChartCard(
                                title: "Overall Bin Capacity", 
                                child: _buildStatusOverview(statusStats, totalBins),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2, 
                              child: _buildChartCard(
                                title: "Live Status by Zone",
                                child: _buildBarChart(areaStatusData),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          _buildSummaryCard("Active Drivers", "$activeDrivers", Colors.blue, Icons.person),
                          const SizedBox(height: 16),
                          _buildSummaryCard("Unassigned & Full", "$urgentCount", Colors.redAccent, Icons.warning_amber_rounded),
                          const SizedBox(height: 16),
                          _buildSummaryCard("Offline Sensors", "$offlineCount", Colors.blueGrey, Icons.wifi_off_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32), 
                _buildAlertsSection(alertsList),
              ],
            ),
          );
        },
      ),
    );
  }

  // -- UI Helper Widgets --

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(List<Map<String, dynamic>> alerts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Action Required", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              if (alerts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Text("${alerts.length} Alerts", style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                )
            ],
          ),
          const SizedBox(height: 20),
          
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green.shade300, size: 48),
                    const SizedBox(height: 12),
                    Text("All systems nominal. No urgent actions required.", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: alerts.map((alert) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(
                      left: BorderSide(color: alert['color'], width: 4), 
                      top: BorderSide(color: Colors.grey.shade200), 
                      bottom: BorderSide(color: Colors.grey.shade200), 
                      right: BorderSide(color: Colors.grey.shade200)
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(backgroundColor: alert['color'].withOpacity(0.1), child: Icon(alert['icon'], color: alert['color'], size: 20)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alert['reason'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text("${alert['name']} • ${alert['area']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                      ),
                      if (alert['unassigned'])
                         Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text("Needs Driver", style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      Text(alert['time'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // --- Charts Logic ---

  Widget _buildStatusOverview(Map<String, double> stats, int total) {
    if (total == 0) return const Center(child: Text("No Bins Available"));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300)
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Colors.grey.shade700, size: 20),
              const SizedBox(width: 8),
              Text("Total Bins: $total", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildStatusRow("Safe (Empty - 49%)", stats['Safe']!, total, const Color(0xFF4CAF50)),
        const SizedBox(height: 20),
        // UPDATED: Label changed to 74%
        _buildStatusRow("Warning (50% - 74%)", stats['Warning']!, total, const Color(0xFFFF9800)),
        const SizedBox(height: 20),
        // UPDATED: Label changed to 75%+
        _buildStatusRow("Critical (75%+)", stats['Critical']!, total, const Color(0xFFF44336)),
      ],
    );
  }

  Widget _buildStatusRow(String label, double count, int total, Color color) {
    double percentage = total == 0 ? 0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
            Text("${count.toInt()} Bins", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 12,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildBarChart(Map<String, Map<String, int>> areaStats) {
    if (areaStats.isEmpty) return const Center(child: Text("No bin data yet"));
    
    int idx = 0;
    double maxTotalBins = 0;
    List<BarChartGroupData> barGroups = [];

    areaStats.forEach((area, stats) {
      double safe = stats['Safe']!.toDouble();
      double warning = stats['Warning']!.toDouble();
      double critical = stats['Critical']!.toDouble();
      double total = safe + warning + critical;

      if (total > maxTotalBins) maxTotalBins = total;

      List<BarChartRodStackItem> stackItems = [];
      double currentY = 0;

      if (safe > 0) {
        stackItems.add(BarChartRodStackItem(currentY, currentY + safe, Colors.green));
        currentY += safe;
      }
      if (warning > 0) {
        stackItems.add(BarChartRodStackItem(currentY, currentY + warning, Colors.orange));
        currentY += warning;
      }
      if (critical > 0) {
        stackItems.add(BarChartRodStackItem(currentY, currentY + critical, Colors.red));
      }

      barGroups.add(
        BarChartGroupData(
          x: idx++, 
          barRods: [
            BarChartRodData(
              toY: total, 
              width: 30, 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              rodStackItems: stackItems, 
              color: Colors.transparent, 
            )
          ]
        )
      );
    });

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxTotalBins + 2, 
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.shade800, 
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                "Total: ${rod.toY.toInt()}", 
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) {
             if (val.toInt() >= areaStats.length) return const Text("");
             return Padding(
               padding: const EdgeInsets.only(top: 10), 
               child: Text(areaStats.keys.elementAt(val.toInt()), style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold))
              );
          })),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true, 
              reservedSize: 30,
              interval: 1, 
              getTitlesWidget: (value, meta) {
                if (value == 0 || value % 1 != 0) return const SizedBox(); 
                return Text("${value.toInt()}", style: const TextStyle(fontSize: 12, color: Colors.black54));
              }
            )
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1, 
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: true, border: Border(bottom: BorderSide(color: Colors.grey.shade400), left: BorderSide(color: Colors.grey.shade400))),
        barGroups: barGroups,
      ),
    );
  }
}
