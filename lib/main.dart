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
import 'app_colors.dart';

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
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.background,
            ),
          ),
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
    // Settings (patient name, text size, etc.) can change from a
    // screen several levels deep (Home -> PIN -> Manage schedule ->
    // Settings). Listening here means Home reflects those changes
    // the moment they're saved, not just after some unrelated
    // rebuild happens to occur.
    appSettings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    super.dispose();
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

  // Tapping the profile avatar shows who the app is set up for. The
  // name itself is a caregiver setting (not editable from here) so
  // Mary can't accidentally rename herself mid-task; it just points
  // to where that change actually happens.
  void _showProfileSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final name = appSettings.settings.patientName;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        const Text('CareMate patient', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'To change this name or other settings, a caregiver can unlock "Manage schedule" from the lock icon and open Settings.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      },
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerMain),
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
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedNavIndex,
          children: [
            _buildHomeTab(),
            const HealthScreen(),
            SosScreen(settingsController: appSettings),
            AiScreen(medicines: _medicines, patientName: appSettings.settings.patientName),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        selectedItemColor: AppColors.primary,
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

  // The app's brand row: a small emoji "logo" in a colored circle,
  // the wordmark, and a tappable profile avatar on the right. This
  // sits above the personal "Good morning" greeting so the app has
  // a consistent identity even as the greeting/name changes.
  Widget _buildBrandRow() {
    final name = appSettings.settings.patientName;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('🌿', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        const Text(
          'CareMate',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: _showProfileSheet,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.secondary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTab() {
    // Only medicines actually due today show up here — the FULL
    // list stays intact in _medicines for Inventory/Caregiver use.
    final todaysMedicines = _medicines.where((m) => m.isDueToday()).toList();
    final takenCount = todaysMedicines.where((m) => m.isTaken).length;
    final patientName = appSettings.settings.patientName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBrandRow(),
          const SizedBox(height: 20),

          // Header is split into two stacked rows (title, then a
          // Wrap of icons below) rather than one Row — inside a Row,
          // an unconstrained Wrap reports its full intrinsic width
          // instead of actually wrapping, so title + icons together
          // could exceed the screen width. Splitting them lets the
          // Wrap genuinely wrap onto a second line if it ever needs to.
          Text(
            'Good morning, $patientName',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              IconButton(
                onPressed: _openRxScannerScreen,
                icon: const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
                tooltip: 'Scan a prescription',
              ),
              IconButton(
                onPressed: _openDoctorNotesScreen,
                icon: const Icon(Icons.medical_information_outlined, color: AppColors.primary),
                tooltip: 'Doctor visits',
              ),
              IconButton(
                onPressed: _openInventoryScreen,
                icon: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                tooltip: 'Medicine stock',
              ),
              IconButton(
                onPressed: _openHistoryScreen,
                icon: const Icon(Icons.history, color: AppColors.primary),
                tooltip: 'Medication log',
              ),
              IconButton(
                onPressed: _openCaregiverAccess,
                icon: const Icon(Icons.lock_outline, color: AppColors.primary),
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
        border: Border.all(color: AppColors.cardBorder),
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
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Taken at ${med.time}',
                  style: const TextStyle(
                    color: AppColors.successFg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                _actionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Taken',
                  background: AppColors.secondary,
                  foreground: Colors.white,
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
                ),
                const SizedBox(width: 8),
                _actionButton(
                  icon: Icons.snooze,
                  label: 'Snooze',
                  background: AppColors.warningBg,
                  foreground: AppColors.warningFg,
                  onPressed: () {
                    _logHistory(med, 'snoozed');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${med.name} snoozed for 15 minutes')),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _actionButton(
                  icon: Icons.close,
                  label: 'Skip',
                  background: AppColors.dangerBg,
                  foreground: AppColors.dangerFg,
                  onPressed: () => _confirmSkip(med),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // FIX: the old buttons were plain ElevatedButtons with an emoji +
  // word (e.g. "Snooze") inside a fixed-width Expanded slot. Once
  // the accessibility text-size setting scales the font up, or on a
  // narrower phone, "Snooze" no longer fits on one line and Flutter
  // wraps it mid-word ("Sn" / "ooze"). Wrapping the icon+label row in
  // a FittedBox(fit: BoxFit.scaleDown) instead shrinks the whole
  // thing down to fit the available width as one unit — so it either
  // renders at full size or slightly smaller, but never breaks a
  // word across two lines. Using Material icons instead of emoji
  // also gives the three actions a single consistent, formal look.
  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(fontWeight: FontWeight.w600, color: foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
