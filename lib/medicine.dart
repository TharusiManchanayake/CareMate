import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Medicine {
  final String name;
  final String dosage;
  final String condition;
  final String timing;
  final String time;
  bool isTaken;
  int stockCount; // how many tablets/doses remain

  Medicine({
    required this.name,
    required this.dosage,
    required this.condition,
    required this.timing,
    required this.time,
    this.isTaken = false,
    this.stockCount = 20, // sensible default for newly added medicines
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'condition': condition,
      'timing': timing,
      'time': time,
      'isTaken': isTaken,
      'stockCount': stockCount,
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
      // Fallback to 20 if old saved data doesn't have this field yet
      // (e.g. medicines saved before we added stockCount).
      stockCount: map['stockCount'] ?? 20,
    );
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