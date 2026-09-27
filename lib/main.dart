import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'medicine.dart';
import 'health_screen.dart';
import 'sos_screen.dart';
import 'ai_screen.dart';
import 'history_screen.dart';
import 'history_entry.dart';
import 'inventory_screen.dart';
import 'doctor_notes_screen.dart';
import 'rx_scanner_screen.dart';
import 'caregiver_pin_screen.dart';
import 'notification_service.dart';
import 'settings.dart';

// One shared settings controller for the whole app's lifetime. It's
// a ChangeNotifier, so wrapping MaterialApp in an AnimatedBuilder
// below means changing text size (or anything else in Settings)
// takes effect immediately everywhere, without restarting the app.
final AppSettingsController appSettings = AppSettingsController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();
  await appSettings.load();
  runApp(const CareMateApp());
}

class CareMateApp extends StatelessWidget {
  const CareMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        return MaterialApp(
          title: 'CareMate',
          debugShowCheckedModeBanner: false,
          // Applies the caregiver's chosen text size to every screen
          // in the app via MediaQuery, rather than each screen having
          // to opt in individually.
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(appSettings.settings.textSize.scale),
              ),
              child: child!,
            );
          },
          home: const HomeScreen(),
        );
      },
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
      stockCount: 18,
    ),
    Medicine(
      name: 'Metformin 500mg',
      dosage: '1 tablet',
      condition: 'Diabetes',
      timing: 'before lunch',
      time: '12:30 PM',
      stockCount: 42,
    ),
    Medicine(
      name: 'Vitamin D 1000IU',
      dosage: '1 tablet',
      condition: 'Supplement',
      timing: 'anytime',
      time: '1:00 PM',
      stockCount: 5,
    ),
  ];

  // The FULL list — every medicine ever added, regardless of
  // whether it's due today. Caregiver screens (Inventory, Manage
  // Schedule) should see everything.
  List<Medicine> _medicines = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final saved = await MedicineStorage.loadMedicines();
    final medicines = saved ?? _defaultMedicines;

    for (final med in medicines) {
      med.resetIfNewDay();
    }

    setState(() {
      _medicines = medicines;
      _isLoading = false;
    });

    _saveData();
    _rescheduleAllReminders();
  }

  // Re-syncs every medicine's OS-level reminder on each app start.
  // This is what makes ended medicines' reminders actually stop
  // (scheduleForMedicine skips anything past its endDate) and keeps
  // reminders correct if the caregiver edited something outside the
  // app's own scheduling calls, e.g. after a fresh install/restore.
  void _rescheduleAllReminders() {
    for (final med in _medicines) {
      NotificationService.scheduleForMedicine(med);
    }
  }

  void _saveData() {
    MedicineStorage.saveMedicines(_medicines);
    MedicineCloudSync.syncAllMedicines(_medicines);
  }

  void _onCaregiverDataChanged() {
    setState(() {});
    _saveData();
  }

  String _currentTimeString() {
    final now = DateTime.now();
    final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minuteStr = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minuteStr $period';
  }

  String _currentDateString() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day} ${months[now.month - 1]}';
  }

  void _logHistory(Medicine med, String status) {
    HistoryStorage.addEntry(HistoryEntry(
      medicineName: med.name,
      date: _currentDateString(),
      time: _currentTimeString(),
      status: status,
    ));
  }

  void _openHistoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );
  }

  void _openInventoryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => InventoryScreen(medicines: _medicines)),
    );
  }

  void _openDoctorNotesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorNotesScreen()),
    );
  }

  // FIX: previously this fired-and-forgot — the RX scanner had no
  // way to hand a newly created medicine back to Home at all. Now
  // that RxScannerScreen can pop itself with a Medicine (via its
  // "Use this as a new medicine" flow), this mirrors how Add
  // Medicine and Caregiver screen already add + schedule a medicine.
  Future<void> _openRxScannerScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RxScannerScreen()),
    );

    if (result != null && result is Medicine) {
      setState(() {
        _medicines.add(result);
      });
      _saveData();
      NotificationService.scheduleForMedicine(result);
    }
  }

  void _openCaregiverAccess() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaregiverPinScreen(
          medicines: _medicines,
          onDataChanged: _onCaregiverDataChanged,
          settingsController: appSettings,
        ),
      ),
    );
  }

  // FIX: Skip used to fire immediately on tap with no confirmation,
  // unlike deleting a medicine (which does confirm). A single
  // accidental tap silently logged a real missed dose. This adds
  // the same confirm-before-acting pattern used elsewhere in the app.
  Future<void> _confirmSkip(Medicine med) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip this dose?'),
        content: Text('This will mark "${med.name}" as missed for today.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD2574C)),
            child: const Text('Skip dose', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _logHistory(med, 'missed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${med.name} marked as skipped')),
        );
      }
    }
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
            SosScreen(settingsController: appSettings),
            AiScreen(medicines: _medicines),
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
    // Only medicines actually due today show up here — the FULL
    // list stays intact in _medicines for Inventory/Caregiver use.
    final todaysMedicines = _medicines.where((m) => m.isDueToday()).toList();
    final takenCount = todaysMedicines.where((m) => m.isTaken).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header is split into two stacked rows (title, then a
          // Wrap of icons below) rather than one Row — inside a Row,
          // an unconstrained Wrap reports its full intrinsic width
          // instead of actually wrapping, so title + icons together
          // could exceed the screen width. Splitting them lets the
          // Wrap genuinely wrap onto a second line if it ever needs to.
          const Text(
            'Good morning, Mary',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E4038),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              IconButton(
                onPressed: _openRxScannerScreen,
                icon: const Icon(Icons.document_scanner_outlined, color: Color(0xFF1E4038)),
                tooltip: 'Scan a prescription',
              ),
              IconButton(
                onPressed: _openDoctorNotesScreen,
                icon: const Icon(Icons.medical_information_outlined, color: Color(0xFF1E4038)),
                tooltip: 'Doctor visits',
              ),
              IconButton(
                onPressed: _openInventoryScreen,
                icon: const Icon(Icons.inventory_2_outlined, color: Color(0xFF1E4038)),
                tooltip: 'Medicine stock',
              ),
              IconButton(
                onPressed: _openHistoryScreen,
                icon: const Icon(Icons.history, color: Color(0xFF1E4038)),
                tooltip: 'Medication log',
              ),
              IconButton(
                onPressed: _openCaregiverAccess,
                icon: const Icon(Icons.lock_outline, color: Color(0xFF1E4038)),
                tooltip: 'Caregiver access & settings',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            todaysMedicines.isEmpty
                ? "No medicines scheduled for today"
                : "You've taken $takenCount of ${todaysMedicines.length} doses today",
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          for (final med in todaysMedicines) ...[
            _medicineCard(med),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 20),
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
                      final actualTime = _currentTimeString();
                      setState(() {
                        med.isTaken = true;
                        med.time = actualTime;
                        med.lastTakenDate = Medicine.todayString();
                        if (med.stockCount > 0) {
                          med.stockCount--;
                        }
                      });
                      _saveData();
                      _logHistory(med, 'taken');
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
                    onPressed: () {
                      _logHistory(med, 'snoozed');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${med.name} snoozed for 15 minutes')),
                      );
                    },
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
                    onPressed: () => _confirmSkip(med),
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
