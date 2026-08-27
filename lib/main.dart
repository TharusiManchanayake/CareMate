import 'package:flutter/material.dart';
import 'medicine.dart';
import 'health_screen.dart';
import 'sos_screen.dart';
import 'ai_screen.dart';
import 'add_medicine_screen.dart';
import 'history_screen.dart';

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
  bool _isLoading = true;

  final List<Medicine> _defaultMedicines = [
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

  List<Medicine> _medicines = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final saved = await MedicineStorage.loadMedicines();

    setState(() {
      _medicines = saved ?? _defaultMedicines;
      _isLoading = false;
    });
  }

  void _saveData() {
    MedicineStorage.saveMedicines(_medicines);
  }

  Future<void> _openAddMedicineScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicineScreen()),
    );

    if (result != null && result is Medicine) {
      setState(() {
        _medicines.add(result);
      });
      _saveData();
    }
  }

  void _openHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFBF6EC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedNavIndex,
          children: [
            _buildHomeTab(),
            const HealthScreen(),
            const SosScreen(),
            const AiScreen(),
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
      floatingActionButton: _selectedNavIndex == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF1E4038),
              onPressed: _openAddMedicineScreen,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildHomeTab() {
    final takenCount = _medicines.where((m) => m.isTaken).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Good morning, Mary',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E4038),
                ),
              ),
              IconButton(
                onPressed: _openHistoryScreen,
                icon: const Icon(Icons.history, color: Color(0xFF1E4038)),
              ),
            ],
          ),
          Text(
            "You've taken $takenCount of ${_medicines.length} doses today",
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          for (final med in _medicines) ...[
            _medicineCard(med),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 70),
        ],
      ),
    );
  }

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
                      setState(() {
                        med.isTaken = true;
                      });
                      _saveData();
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
}