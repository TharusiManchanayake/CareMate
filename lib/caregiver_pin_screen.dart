import 'package:flutter/material.dart';
import 'medicine.dart';
import 'caregiver_screen.dart';

const String _caregiverPin = '1234';

class CaregiverPinScreen extends StatefulWidget {
  final List<Medicine> medicines;
  final VoidCallback onDataChanged;

  const CaregiverPinScreen({
    super.key,
    required this.medicines,
    required this.onDataChanged,
  });

  @override
  State<CaregiverPinScreen> createState() => _CaregiverPinScreenState();
}

class _CaregiverPinScreenState extends State<CaregiverPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _checkPin() {
    if (_pinController.text == _caregiverPin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CaregiverScreen(
            medicines: widget.medicines,
            onDataChanged: widget.onDataChanged,
          ),
        ),
      );
    } else {
      setState(() {
        _errorText = 'Incorrect PIN. Try again.';
      });
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EC),
        elevation: 0,
        title: const Text('Caregiver access', style: TextStyle(color: Color(0xFF1E4038))),
        iconTheme: const IconThemeData(color: Color(0xFF1E4038)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline, size: 40, color: Color(0xFF1E4038)),
            const SizedBox(height: 16),
            const Text(
              'Enter caregiver PIN',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E4038)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Editing the medicine schedule is limited to caregivers to help prevent accidental changes.',
              style: TextStyle(fontSize: 13, color: Color(0xFF4C6B63)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              style: const TextStyle(fontSize: 22, letterSpacing: 8),
              decoration: InputDecoration(
                counterText: '',
                errorText: _errorText,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: Color(0xFFE4DDCB)),
                ),
              ),
              onSubmitted: (_) => _checkPin(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _checkPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4038),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Unlock', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

