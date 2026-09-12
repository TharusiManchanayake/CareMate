import 'package:flutter/material.dart';
import 'vital_reading.dart';
import 'add_vital_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  bool _isLoading = true;

  // The most recent reading of each type, or null if never logged.
  VitalReading? _latestBP;
  VitalReading? _latestSugar;
  VitalReading? _latestHeartRate;
  VitalReading? _latestOxygen;
  VitalReading? _latestWeight;

  @override
  void initState() {
    super.initState();
    _loadLatestReadings();
  }

  Future<void> _loadLatestReadings() async {
    // Each of these looks up the newest reading of that specific
    // type — they run one after another here since there are only
    // five, simple and easy to follow.
    final bp = await VitalStorage.latestOfType('Blood Pressure');
    final sugar = await VitalStorage.latestOfType('Blood Sugar');
    final heartRate = await VitalStorage.latestOfType('Heart Rate');
    final oxygen = await VitalStorage.latestOfType('Oxygen');
    final weight = await VitalStorage.latestOfType('Weight');

    setState(() {
      _latestBP = bp;
      _latestSugar = sugar;
      _latestHeartRate = heartRate;
      _latestOxygen = oxygen;
      _latestWeight = weight;
      _isLoading = false;
    });
  }

  Future<void> _openAddVitalScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVitalScreen()),
    );

    if (result != null && result is VitalReading) {
      await VitalStorage.addReading(result);
      _loadLatestReadings(); // refresh so the new reading shows immediately
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

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
            'Most recent readings',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          _vitalCard('🩺', 'Blood Pressure', _latestBP, const Color(0xFFD2574C)),
          const SizedBox(height: 10),
          _vitalCard('🩸', 'Blood Sugar', _latestSugar, const Color(0xFFE9A23B)),
          const SizedBox(height: 10),
          _vitalCard('❤️', 'Heart Rate', _latestHeartRate, const Color(0xFF7FA98D)),
          const SizedBox(height: 10),
          _vitalCard('🫁', 'Oxygen', _latestOxygen, const Color(0xFF1E4038)),
          const SizedBox(height: 10),
          _vitalCard('⚖️', 'Weight', _latestWeight, const Color(0xFF7FA98D)),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _openAddVitalScreen,
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

  // Handles both the "has a reading" and "never logged" cases in
  // one place, so the calling code above stays simple.
  Widget _vitalCard(String icon, String name, VitalReading? reading, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DDCB)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                if (reading != null)
                  Text(
                    '${reading.date} · ${reading.time}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ),
          Text(
            reading?.value ?? 'No data',
            style: TextStyle(
              fontSize: reading != null ? 17 : 13,
              fontWeight: reading != null ? FontWeight.bold : FontWeight.normal,
              color: reading != null ? color : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}