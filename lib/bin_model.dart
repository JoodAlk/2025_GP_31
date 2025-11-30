import 'package:flutter/material.dart';

class Bin {
  final String id;
  final String name;
  final String areaId;
  final int capacity;
  final int fillLevel;
  final double latitude;
  final double longitude;
  final String assignedDriverId; 
  
  // --- NEW KEYS ---
  final bool isOverflowing;
  final bool isAssigned; // <--- ADDED: Reads strict boolean from DB
  final String lastEmptied;
  final String status;
  final String sensorId;
  final String lastUpdate;

  Bin({
    required this.id,
    required this.name,
    required this.areaId,
    required this.fillLevel,
    required this.latitude,
    required this.longitude,
    required this.assignedDriverId,
    required this.capacity,
    required this.isOverflowing,
    required this.isAssigned, // <--- ADDED
    required this.lastEmptied,
    required this.status,
    required this.sensorId,
    required this.lastUpdate,
  });

  // Helper to safely parse ints from RTDB (int/double/String)
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper to safely parse doubles
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
  
  // Helper to safely parse booleans (defaults to false)
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    return false;
  }

  factory Bin.fromRTDB(Map data, String key) {
    final location = data['Location'] as Map?;
    final sensor = data['Sensor'] as Map?;
    
    // Safety checks for nested data
    final lat = _parseDouble(location?['Latitude']);
    final lng = _parseDouble(location?['Longitude']);
    final driverId = data['AssignedDriverId']?.toString() ?? 'N/A';

    return Bin(
      id: key, 
      name: data['Name'] ?? 'N/A',
      areaId: data['AreaId'] ?? 'Unknown Area',
      fillLevel: _parseInt(data['FillLevel']),
      latitude: lat == 0.0 ? 24.7136 : lat,
      longitude: lng == 0.0 ? 46.6753 : lng,
      assignedDriverId: driverId, 
      capacity: _parseInt(data['Capacity']),
      isOverflowing: _parseBool(data['IsOverflowing']),
      
      // <--- ADDED: Mapping the specific database key
      isAssigned: _parseBool(data['IsAssigned']), 
      
      lastEmptied: data['LastEmptied']?.toString() ?? 'N/A',
      sensorId: sensor?['Id']?.toString() ?? 'N/A',
      lastUpdate: data['LastEmptied']?.toString() ?? 'N/A', // Using LastEmptied as fallback if LastUpdate is missing
      status: data['Status']?.toString() ?? 'N/A',
    );
  }

  String get statusText {
    if (fillLevel >= 100) return 'FULL';
    if (fillLevel >= 50) return 'HALF';
    return 'EMPTY';
  }

  Color get statusColor {
    if (fillLevel >= 100) return Colors.red.shade700;
    if (fillLevel >= 50) return Colors.orange.shade700;
    return Colors.green.shade700;
  }
}