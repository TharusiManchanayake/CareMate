import 'package:flutter/material.dart';
import 'medicine.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  // One controller per text field, so we can read what's typed.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();

  String _selectedTiming = 'After meals'; // default selection for the chips

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  void _saveMedicine() {
    if (_nameController.text.trim().isEmpty) {
      // A SnackBar is a small message that pops up briefly at the
      // bottom of the screen — good for quick feedback like errors.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medicine name')),
      );
      return;
    }

    final newMedicine = Medicine(
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim().isEmpty
          ? '1 tablet'
          : _dosageController.text.trim(),
      condition: 'General',
      timing: _selectedTiming.toLowerCase(),
      time: '8:00 AM',
    );

    // Navigator.pop can optionally carry a RESULT back to whoever
    // pushed this screen — here, we send the new Medicine object
    // back so HomeScreen can add it to the list.
    Navigator.pop(context, newMedicine);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EC),
        elevation: 0,
        title: const Text(
          'Add a medicine',
          style: TextStyle(color: Color(0xFF1E4038)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E4038)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medicine name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: _fieldDecoration('e.g. Warfarin'),
            ),
            const SizedBox(height: 16),

            const Text('Dosage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _dosageController,
              decoration: _fieldDecoration('e.g. 2mg, 1 tablet'),
            ),
            const SizedBox(height: 16),

            const Text('Timing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['After meals', 'Before meals', 'Anytime'].map((option) {
                final isSelected = _selectedTiming == option;
                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedTiming = option;
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
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMedicine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4038),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save medicine', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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