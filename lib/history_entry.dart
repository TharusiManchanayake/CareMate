import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryEntry {
  final String medicineName;
  final String date;
  final String time;
  final String status; // 'taken', 'missed', or 'snoozed'

  HistoryEntry({
    required this.medicineName,
    required this.date,
    required this.time,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'date': date,
      'time': time,
      'status': status,
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      medicineName: map['medicineName'],
      date: map['date'],
      time: map['time'],
      status: map['status'],
    );
  }
}

class HistoryStorage {
  static const _key = 'history_entries';

  static Future<List<HistoryEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    final List<dynamic> decoded = jsonDecode(jsonString);
    final entries = decoded.map((item) => HistoryEntry.fromMap(item)).toList();

    // Show most recent entries first.
    return entries.reversed.toList();
  }

  // Adds ONE new entry on top of whatever's already saved, rather
  // than replacing the whole list — this reads, appends, then
  // writes back, so past history is never lost.
  static Future<void> addEntry(HistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    List<dynamic> existing = jsonString == null ? [] : jsonDecode(jsonString);
    existing.add(entry.toMap());

    await prefs.setString(_key, jsonEncode(existing));
  }
}