import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String name;
  final String dosage;
  final String condition;
  final String timing;
  String time;
  bool isTaken;
  int stockCount;
  String? lastTakenDate;

  String frequency; // 'Daily' or 'Specific days'
  List<String> activeDays; // e.g. ['Mon', 'Wed', 'Fri'] — only used if frequency is 'Specific days'
  String startDate; // "YYYY-MM-DD" — when this medicine becomes active
  String? endDate; // "YYYY-MM-DD" or null — null means no end date (ongoing)

  Medicine({
    required this.name,
    required this.dosage,
    required this.condition,
    required this.timing,
    required this.time,
    this.isTaken = false,
    this.stockCount = 20,
    this.lastTakenDate,
    this.frequency = 'Daily',
    List<String>? activeDays,
    String? startDate,
    this.endDate,
  })  : activeDays = activeDays ?? [],
        startDate = startDate ?? todayString();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'condition': condition,
      'timing': timing,
      'time': time,
      'isTaken': isTaken,
      'stockCount': stockCount,
      'lastTakenDate': lastTakenDate,
      'frequency': frequency,
      'activeDays': activeDays,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      name: map['name'],
      dosage: map['dosage'],
      condition: map['condition'],
      timing: map['timing'],
      time: map['time'],
      isTaken: map['isTaken'] ?? false,
      stockCount: map['stockCount'] ?? 20,
      lastTakenDate: map['lastTakenDate'],
      frequency: map['frequency'] ?? 'Daily',
      activeDays: map['activeDays'] != null
          ? List<String>.from(map['activeDays'])
          : [],
      startDate: map['startDate'] ?? todayString(),
      endDate: map['endDate'],
    );
  }

  String get docId => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  static String todayString() => dateToString(DateTime.now());

  static String dateToString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void resetIfNewDay() {
    if (isTaken && lastTakenDate != todayString()) {
      isTaken = false;
    }
  }

  // The core scheduling check: should this medicine appear on
  // today's list at all?
  bool isDueToday() {
    final today = todayString();

    // Hasn't started yet — startDate is later than today.
    if (startDate.compareTo(today) > 0) return false;

    // Already ended — endDate exists and is earlier than today.
    if (endDate != null && endDate!.compareTo(today) < 0) return false;

    // If it's a specific-days medicine, check today's weekday name
    // is in the chosen list. DateTime.now().weekday is 1 (Monday)
    // through 7 (Sunday), so we subtract 1 to index into our list.
    if (frequency == 'Specific days') {
      final todayName = _weekdayNames[DateTime.now().weekday - 1];
      return activeDays.contains(todayName);
    }

    return true; // 'Daily' — always due, as long as within date range
  }
}

class MedicineStorage {
  static const _key = 'medicines_list';

  static Future<void> saveMedicines(List<Medicine> medicines) async {
    final prefs = await SharedPreferences.getInstance();
    final mapList = medicines.map((m) => m.toMap()).toList();
    final jsonString = jsonEncode(mapList);
    await prefs.setString(_key, jsonString);
  }

  static Future<List<Medicine>?> loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return null;

    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((item) => Medicine.fromMap(item)).toList();
  }
}

class MedicineCloudSync {
  static Future<void> syncMedicine(Medicine medicine) async {
    await FirebaseFirestore.instance
        .collection('medicines')
        .doc(medicine.docId)
        .set(medicine.toMap());
  }

  static Future<void> syncAllMedicines(List<Medicine> medicines) async {
    for (final med in medicines) {
      await syncMedicine(med);
    }
  }
}