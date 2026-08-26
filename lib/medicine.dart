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
}

// A helper class dedicated to saving/loading which medicines are
// taken. Keeping this separate from the Medicine class itself keeps
// responsibilities clean: Medicine = data shape, MedicineStorage =
// how that data is persisted.
class MedicineStorage {
  static const _key = 'taken_medicines';

  // Saves the names of all currently-taken medicines as a list of
  // strings — shared_preferences can only store simple types, so
  // we can't save Medicine objects directly, just their names.
  static Future<void> saveTakenMedicines(List<Medicine> medicines) async {
    final prefs = await SharedPreferences.getInstance();
    final takenNames = medicines
        .where((m) => m.isTaken)
        .map((m) => m.name)
        .toList();
    await prefs.setStringList(_key, takenNames);
  }

  // Reads back the saved list of taken medicine names. Returns an
  // empty list if nothing was ever saved (first app launch).
  static Future<List<String>> loadTakenMedicineNames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }
}