import 'package:flutter/material.dart';

// A small "model" for one vital reading — same idea as Medicine.
class Vital {
  final String name;
  final String value;
  final String icon;
  final Color color;

  Vital({
    required this.name,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vitals = [
      Vital(name: 'Blood Pressure', value: '128/82', icon: '🩺', color: const Color(0xFFD2574C)),
      Vital(name: 'Blood Sugar', value: '104 mg/dL', icon: '🩸', color: const Color(0xFFE9A23B)),
      Vital(name: 'Heart Rate', value: '76 bpm', icon: '❤️', color: const Color(0xFF7FA98D)),
      Vital(name: 'Oxygen', value: '97%', icon: '🫁', color: const Color(0xFF1E4038)),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your vitals',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E4038),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Last 7 days',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          for (final v in vitals) ...[
            _vitalCard(v),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => debugPrint('Add vital reading tapped'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('+ Log a new reading'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vitalCard(Vital v) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DDCB)),
      ),
      child: Row(
        children: [
          Text(v.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              v.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            v.value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: v.color,
            ),
          ),
        ],
      ),
    );
  }
}