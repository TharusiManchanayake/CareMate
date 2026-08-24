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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isTaken = false;
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),

      // IndexedStack shows only the child at `index`, but keeps all
      // children alive in memory — switching tabs is instant and
      // doesn't lose any state on the screens you switch away from.
      body: SafeArea(
        child: IndexedStack(
          index: _selectedNavIndex,
          children: [
            _buildHomeTab(),
            _placeholderTab('Health', Icons.favorite, const Color(0xFF7FA98D)),
            _placeholderTab('Emergency SOS', Icons.sos, const Color(0xFFD2574C)),
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

  // ---- The real Home tab content (everything we built so far) ----
  Widget _buildHomeTab() {
    return Padding(
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
          const SizedBox(height: 20),
          Row(
            children: [
              _statChip('92%', 'Adherence'),
              const SizedBox(width: 10),
              _statChip('5', 'Pills left'),
              const SizedBox(width: 10),
              _statChip('14', 'Day streak'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String number, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE4DDCB)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E4038),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Simple placeholder for tabs we haven't built yet ----
  Widget _placeholderTab(String label, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Coming soon',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}