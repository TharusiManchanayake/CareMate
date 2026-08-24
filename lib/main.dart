import 'package:flutter/material.dart';
import 'medicine.dart'; // our new data model file
import 'health_screen.dart';
import 'sos_screen.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  // Our list of medicines — this is now the single source of truth.
  // Instead of hardcoding one card, we generate cards from this list.
  final List<Medicine> _medicines = [
    Medicine(
      name: 'Amlodipine 5mg',
      dosage: '1 tablet',
      condition: 'Blood pressure',
      timing: 'after breakfast',
      time: '9:41 AM',
    ),
    Medicine(
      name: 'Metformin 500mg',
      dosage: '1 tablet',
      condition: 'Diabetes',
      timing: 'before lunch',
      time: '12:30 PM',
    ),
    Medicine(
      name: 'Vitamin D 1000IU',
      dosage: '1 tablet',
      condition: 'Supplement',
      timing: 'anytime',
      time: '1:00 PM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedNavIndex,
          children: [
            _buildHomeTab(),
            const HealthScreen(),
            const SosScreen(),
            _placeholderTab('AI Assistant', Icons.smart_toy, const Color(0xFFE9A23B)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        selectedItemColor: const Color(0xFF1E4038),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Health'),
          BottomNavigationBarItem(icon: Icon(Icons.sos), label: 'SOS'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    // Count how many are taken, for the greeting subtitle — this is
    // computed live from the list every time build() runs.
    final takenCount = _medicines.where((m) => m.isTaken).length;

    return SingleChildScrollView(
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
          const SizedBox(height: 2),
          Text(
            "You've taken $takenCount of ${_medicines.length} doses today",
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          // ---- Generate one card per medicine using a for loop ----
          // Dart lets you put a `for` directly inside a list literal
          // (this is called a "collection for"). For each medicine
          // in _medicines, it builds a card widget and adds it here.
          for (final med in _medicines) ...[
            _medicineCard(med),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  // Takes a Medicine object and returns a card widget for it.
  // Because this same method is reused for every medicine, we only
  // wrote the card UI once, no matter how many medicines exist.
  Widget _medicineCard(Medicine med) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4DDCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            med.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${med.condition} · ${med.dosage} · ${med.timing}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          if (med.isTaken)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE4EFE6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '✓ Taken at ${med.time}',
                  style: const TextStyle(
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
                      // We mutate the object's field directly (it's
                      // not `final`), then call setState so Flutter
                      // knows to redraw with the new value.
                      setState(() {
                        med.isTaken = true;
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
                    onPressed: () => debugPrint('Snoozed ${med.name}'),
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
                    onPressed: () => debugPrint('Skipped ${med.name}'),
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
    );
  }

  Widget _placeholderTab(String label, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Coming soon', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }
}