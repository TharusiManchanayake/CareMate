import 'package:flutter/material.dart';

void main() {
  runApp(const CareMateApp());
}

class CareMateApp extends StatelessWidget {
  const CareMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareMate',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

// StatefulWidget = a widget that has data (state) that can change
// over time and needs to redraw itself when that data changes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// The "State" class holds the actual data and the build() method.
// Notice: it's a separate class from HomeScreen itself — this is
// Flutter's pattern, always two classes for a StatefulWidget.
class _HomeScreenState extends State<HomeScreen> {
  // This variable is our "state" — when it changes, we want the
  // screen to redraw to reflect the new value.
  bool _isTaken = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning, Mary',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E4038),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE4DDCB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amlodipine 5mg',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Blood pressure · 1 tablet · after breakfast',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),

                    // Conditional UI: show either the status message
                    // OR the three buttons, depending on _isTaken.
                    if (_isTaken)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4EFE6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            '✓ Taken at 9:41 AM',
                            style: TextStyle(
                              color: Color(0xFF2F5B45),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // setState() tells Flutter: "data
                                // changed, please rebuild this widget"
                                setState(() {
                                  _isTaken = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7FA98D),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('✓ Taken'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => debugPrint('Snoozed'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFBEBD2),
                                foregroundColor: const Color(0xFF93611B),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('⏰ Snooze'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => debugPrint('Skipped'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFBE3E0),
                                foregroundColor: const Color(0xFF9A362D),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('✕ Skip'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}