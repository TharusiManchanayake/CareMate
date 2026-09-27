import 'app_colors.dart';
import 'package:flutter/material.dart';
import 'medicine.dart';
import 'add_medicine_screen.dart';
import 'notification_service.dart';
import 'settings.dart';
import 'settings_screen.dart';

class CaregiverScreen extends StatefulWidget {
  final List<Medicine> medicines;
  final VoidCallback onDataChanged;
  final AppSettingsController settingsController;

  const CaregiverScreen({
    super.key,
    required this.medicines,
    required this.onDataChanged,
    required this.settingsController,
  });

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  Future<void> _openAddMedicineScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(
          // New medicines start with whatever reminder style the
          // caregiver picked as their default in Settings, rather
          // than always defaulting to 'alarm'.
          initialReminderStyle: widget.settingsController.settings.defaultReminderStyle,
        ),
      ),
    );

    if (result != null && result is Medicine) {
      setState(() {
        widget.medicines.add(result);
      });
      widget.onDataChanged();
      NotificationService.scheduleForMedicine(result);
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(controller: widget.settingsController),
      ),
    );
  }

  void _confirmDelete(Medicine med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove medicine?'),
        content: Text('This will remove "${med.name}" from the schedule.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.medicines.remove(med);
              });
              widget.onDataChanged();
              // FIX: onDataChanged() only re-saves the REMAINING
              // medicines (to SharedPreferences and via
              // syncAllMedicines to Firestore) — it never told
              // Firestore to delete the one we just removed, so the
              // old document just sat there indefinitely. This
              // explicitly deletes it from the cloud too.
              MedicineCloudSync.deleteMedicine(med);
              NotificationService.cancelForMedicine(med);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.dangerMain),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Manage schedule', style: TextStyle(color: AppColors.primary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.successFg),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You're editing Mary's medicine schedule. Changes appear on her Home screen immediately.",
                      style: TextStyle(fontSize: 12, color: AppColors.successFg),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.medicines.isEmpty
                  ? Center(
                      child: Text('No medicines yet', style: TextStyle(color: Colors.grey[500])),
                    )
                  : ListView.builder(
                      itemCount: widget.medicines.length,
                      itemBuilder: (context, index) {
                        final med = widget.medicines[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${med.condition} · ${med.dosage} · ${med.timing}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _confirmDelete(med),
                                icon: const Icon(Icons.delete_outline, color: AppColors.dangerFg),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _openAddMedicineScreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
