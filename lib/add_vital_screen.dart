import 'package:flutter/material.dart';
import 'vital_reading.dart';

class AddVitalScreen extends StatefulWidget {
  const AddVitalScreen({super.key});

  @override
  State<AddVitalScreen> createState() => _AddVitalScreenState();
}

class _AddVitalScreenState extends State<AddVitalScreen> {
  final TextEditingController _valueController = TextEditingController();
  String _selectedType = 'Blood Pressure';

  static const _types = ['Blood Pressure', 'Blood Sugar', 'Heart Rate', 'Oxygen', 'Weight'];

  // Different vitals need different input hints/units — a small
  // lookup map keeps this tidy instead of a long if/else chain.
  static const _hints = {
    'Blood Pressure': 'e.g. 128/82',
    'Blood Sugar': 'e.g. 104 mg/dL',
    'Heart Rate': 'e.g. 76 bpm',
    'Oxygen': 'e.g. 97%',
    'Weight': 'e.g. 68 kg',
  };

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _saveReading() {
    if (_valueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a value')),
      );
      return;
    }

    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${now.day} ${months[now.month - 1]}';
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minuteStr = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour12:$minuteStr $period';

    final reading = VitalReading(
      type: _selectedType,
      value: _valueController.text.trim(),
      date: dateStr,
      time: timeStr,
    );

    Navigator.pop(context, reading);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EC),
        elevation: 0,
        title: const Text('Log a reading', style: TextStyle(color: Color(0xFF1E4038))),
        iconTheme: const IconThemeData(color: Color(0xFF1E4038)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedType = type;
                      _valueController.clear(); // avoid leftover text from a different unit
                    });
                  },
                  selectedColor: const Color(0xFF7FA98D),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4C6B63),
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text('Value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                hintText: _hints[_selectedType],
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
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveReading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4038),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save reading', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}