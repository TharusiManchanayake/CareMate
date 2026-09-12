import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// One logged health reading — could be blood pressure, sugar,
// heart rate, oxygen, or weight, distinguished by 'type'.
class VitalReading {
  final String type; // 'Blood Pressure', 'Blood Sugar', 'Heart Rate', 'Oxygen', 'Weight'
  final String value; // the actual reading, e.g. "128/82", "104 mg/dL"
  final String date;
  final String time;

  VitalReading({
    required this.type,
    required this.value,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
      'date': date,
      'time': time,
    };
  }

  factory VitalReading.fromMap(Map<String, dynamic> map) {
    return VitalReading(
      type: map['type'],
      value: map['value'],
      date: map['date'],
      time: map['time'],
    );
  }
}

class VitalStorage {
  static const _key = 'vital_readings';

  static Future<List<VitalReading>> loadReadings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    final List<dynamic> decoded = jsonDecode(jsonString);
    final readings = decoded.map((item) => VitalReading.fromMap(item)).toList();

    return readings.reversed.toList(); // most recent first
  }

  static Future<void> addReading(VitalReading reading) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    List<dynamic> existing = jsonString == null ? [] : jsonDecode(jsonString);
    existing.add(reading.toMap());

    await prefs.setString(_key, jsonEncode(existing));
  }

  // Returns the most recent reading for a specific type, or null
  // if none exist yet — used to show "latest BP" on the Health
  // screen without needing to scan the whole history each time.
  static Future<VitalReading?> latestOfType(String type) async {
    final all = await loadReadings(); // already newest-first
    for (final reading in all) {
      if (reading.type == type) return reading;
    }
    return null;
  }
}