import 'package:flutter/material.dart';
import 'doctor_visit.dart';

class AddVisitScreen extends StatefulWidget {
  const AddVisitScreen({super.key});

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _hasPrescription = false;

  @override
  void dispose() {
    _doctorController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveVisit() {
    if (_doctorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a doctor name')),
      );
      return;
    }

    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';

    final visit = DoctorVisit(
      doctorName: _doctorController.text.trim(),
      date: dateStr,
      note: _noteController.text.trim().isEmpty
          ? 'No additional notes'
          : _noteController.text.trim(),
      hasPrescription: _hasPrescription,
    );

    Navigator.pop(context, visit);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EC),
        elevation: 0,
        title: const Text('Log a visit', style: TextStyle(color: Color(0xFF1E4038))),
        iconTheme: const IconThemeData(color: Color(0xFF1E4038)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Doctor name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _doctorController,
              decoration: _fieldDecoration('e.g. Dr. Reyes'),
            ),
            const SizedBox(height: 16),

            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              maxLines: 4,
              decoration: _fieldDecoration('What did the doctor say?'),
            ),
            const SizedBox(height: 12),

            // CheckboxListTile bundles a checkbox with a label in one
            // tappable row — simpler than manually combining a
            // Checkbox widget and a Text widget yourself.
            CheckboxListTile(
              value: _hasPrescription,
              onChanged: (value) {
                setState(() {
                  _hasPrescription = value ?? false;
                });
              },
              title: const Text('Prescription attached', style: TextStyle(fontSize: 13.5)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF7FA98D),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveVisit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4038),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save visit', style: TextStyle(fontWeight: FontWeight.bold)),
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