import 'package:flutter/material.dart';
import 'settings.dart';

class SettingsScreen extends StatefulWidget {
  final AppSettingsController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _phoneController;
  late final TextEditingController _pinController;
  late String _defaultReminderStyle;
  late AppTextSize _textSize;

  @override
  void initState() {
    super.initState();
    final s = widget.controller.settings;
    _phoneController = TextEditingController(text: s.caregiverPhone);
    _pinController = TextEditingController(text: s.caregiverPin);
    _defaultReminderStyle = s.defaultReminderStyle;
    _textSize = s.textSize;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _save() {
    // The PIN gates the whole "Manage schedule" screen, so a bad
    // value here (empty, non-numeric, wrong length) would either
    // lock the caregiver out or make the PIN meaningless.
    final pin = _pinController.text.trim();
    if (pin.length != 4 || int.tryParse(pin) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be exactly 4 digits')),
      );
      return;
    }

    widget.controller.update(AppSettings(
      caregiverPhone: _phoneController.text.trim(),
      caregiverPin: pin,
      defaultReminderStyle: _defaultReminderStyle,
      textSize: _textSize,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EC),
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Color(0xFF1E4038))),
        iconTheme: const IconThemeData(color: Color(0xFF1E4038)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Text size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'Makes text bigger across the whole app — helpful for Mary to read comfortably.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AppTextSize.values.map((size) {
              final isSelected = _textSize == size;
              return ChoiceChip(
                label: Text(size.label),
                selected: isSelected,
                onSelected: (_) => setState(() => _textSize = size),
                selectedColor: const Color(0xFF7FA98D),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4C6B63),
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          const Text('Caregiver phone number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'Called automatically when the SOS button is pressed.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _fieldDecoration('e.g. +14155551234'),
          ),
          const SizedBox(height: 24),

          const Text('Caregiver PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            'Required to open "Manage schedule" — keep it private.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            decoration: _fieldDecoration('4-digit PIN').copyWith(counterText: ''),
          ),
          const SizedBox(height: 16),

          const Text('Default reminder style for new medicines',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              {'label': 'Alarm', 'value': 'alarm'},
              {'label': 'Notification', 'value': 'notification'},
            ].map((option) {
              final isSelected = _defaultReminderStyle == option['value'];
              return ChoiceChip(
                label: Text(option['label']!),
                selected: isSelected,
                onSelected: (_) => setState(() => _defaultReminderStyle = option['value']!),
                selectedColor: const Color(0xFF1E4038),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF4C6B63),
                  fontWeight: FontWeight.bold,
                ),
                backgroundColor: Colors.white,
              );
            }).toList(),
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4038),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save settings', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE4DDCB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE4DDCB)),
      ),
    );
  }
}
