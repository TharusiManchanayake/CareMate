import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Text size choices exposed to the caregiver. Stored as a plain
/// scale factor and applied globally via MediaQuery's textScaler in
/// main.dart, so every existing screen benefits automatically —
/// no per-screen changes needed.
enum AppTextSize {
  normal(1.0, 'Normal'),
  large(1.25, 'Large'),
  extraLarge(1.5, 'Extra large');

  final double scale;
  final String label;
  const AppTextSize(this.scale, this.label);
}

class AppSettings {
  String patientName;
  String caregiverPhone;
  String caregiverPin;
  String defaultReminderStyle; // 'alarm' or 'notification'
  AppTextSize textSize;

  AppSettings({
    this.patientName = 'Mary',
    this.caregiverPhone = '',
    this.caregiverPin = '1234',
    this.defaultReminderStyle = 'alarm',
    this.textSize = AppTextSize.normal,
  });

  Map<String, dynamic> toMap() => {
        'patientName': patientName,
        'caregiverPhone': caregiverPhone,
        'caregiverPin': caregiverPin,
        'defaultReminderStyle': defaultReminderStyle,
        'textSize': textSize.name,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      patientName: map['patientName'] ?? 'Mary',
      caregiverPhone: map['caregiverPhone'] ?? '',
      caregiverPin: map['caregiverPin'] ?? '1234',
      defaultReminderStyle: map['defaultReminderStyle'] ?? 'alarm',
      textSize: AppTextSize.values.firstWhere(
        (t) => t.name == map['textSize'],
        orElse: () => AppTextSize.normal,
      ),
    );
  }
}

/// Loads/saves AppSettings to SharedPreferences and, importantly,
/// is itself a ChangeNotifier — so changing text size (or anything
/// else) updates every screen currently open immediately, with no
/// app restart required.
class AppSettingsController extends ChangeNotifier {
  static const _key = 'app_settings';

  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString != null) {
      _settings = AppSettings.fromMap(jsonDecode(jsonString));
      notifyListeners();
    }
  }

  Future<void> update(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(newSettings.toMap()));
  }
}
