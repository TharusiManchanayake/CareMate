import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Medicine {
  final String name;
  final String dosage;
  final String condition;
  final String timing;
  final String time;
  bool isTaken;

  Medicine({
    required this.name,
    required this.dosage,
    required this.condition,
    required this.timing,
    required this.time,
    this.isTaken = false,
  });

  // Converts this Medicine into a plain Map (key-value pairs) —
  // an intermediate format that's easy to turn into JSON text.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'condition': condition,
      'timing': timing,
      'time': time,
      'isTaken': isTaken,
    };
  }

  // A "factory constructor" — instead of building a Medicine the
  // normal way, this one takes a Map (e.g. read back from storage)
  // and reconstructs a Medicine object from it.
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      name: map['name'],
      dosage: map['dosage'],
      condition: map['condition'],
      timing: map['timing'],
      time: map['time'],
      isTaken: map['isTaken'] ?? false,
    );
  }
}

class MedicineStorage {
  static const _key = 'medicines_list';

  // Converts the whole list of Medicines to Maps, then to one JSON
  // string, then saves that single string.
  static Future<void> saveMedicines(List<Medicine> medicines) async {
    final prefs = await SharedPreferences.getInstance();
    final mapList = medicines.map((m) => m.toMap()).toList();
    final jsonString = jsonEncode(mapList);
    await prefs.setString(_key, jsonString);
  }

  // Reads the saved JSON string back, decodes it into a List of
  // Maps, then rebuilds real Medicine objects from each Map.
  // Returns null if nothing has ever been saved (first launch).
  static Future<List<Medicine>?> loadMedicines() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return null;

    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map((item) => Medicine.fromMap(item)).toList();
  }
}