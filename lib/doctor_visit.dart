import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DoctorVisit {
  final String doctorName;
  final String date;
  final String note;
  final bool hasPrescription;

  DoctorVisit({
    required this.doctorName,
    required this.date,
    required this.note,
    this.hasPrescription = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'doctorName': doctorName,
      'date': date,
      'note': note,
      'hasPrescription': hasPrescription,
    };
  }

  factory DoctorVisit.fromMap(Map<String, dynamic> map) {
    return DoctorVisit(
      doctorName: map['doctorName'],
      date: map['date'],
      note: map['note'],
      hasPrescription: map['hasPrescription'] ?? false,
    );
  }
}

class DoctorVisitStorage {
  static const _key = 'doctor_visits';

  static Future<List<DoctorVisit>> loadVisits() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return [];

    final List<dynamic> decoded = jsonDecode(jsonString);
    final visits = decoded.map((item) => DoctorVisit.fromMap(item)).toList();

    return visits.reversed.toList(); // most recent first
  }

  static Future<void> addVisit(DoctorVisit visit) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    List<dynamic> existing = jsonString == null ? [] : jsonDecode(jsonString);
    existing.add(visit.toMap());

    await prefs.setString(_key, jsonEncode(existing));
  }
}