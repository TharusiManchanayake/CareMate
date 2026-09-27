import 'app_colors.dart';
import 'package:flutter/material.dart';
import 'medicine.dart';

class AddMedicineScreen extends StatefulWidget {
  // Lets other screens hand this one a head start: the RX scanner
  // passes in whatever text it recognized as a starting point for
  // the name, and CaregiverScreen passes in the caregiver's chosen
  // default reminder style so new medicines don't always start as
  // 'alarm' regardless of preference.
  final String? initialName;
  final String? initialReminderStyle;

  const AddMedicineScreen({super.key, this.initialName, this.initialReminderStyle});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  // One controller per text field, so we can read what's typed.
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();

  String _selectedTiming = 'After meals'; // default selection for the chips
  String _selectedFrequency = 'Daily'; // default selection for frequency chips
  final List<String> _selectedDays = []; // which weekdays are checked, only used if frequency is 'Specific days'
  bool _hasEndDate = false; // whether the caregiver has opted to set an end date
  DateTime? _endDate; // the actual picked end date, if any

  TimeOfDay _reminderTimeOfDay = const TimeOfDay(hour: 8, minute: 0);
  String _reminderStyle = 'alarm'; // 'notification' or 'alarm'

  static const _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null && widget.initialName!.trim().isNotEmpty) {
      _nameController.text = widget.initialName!.trim();
    }
    if (widget.initialReminderStyle != null) {
      _reminderStyle = widget.initialReminderStyle!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  // Opens Flutter's built-in date picker dialog and stores whatever
  // date the caregiver selects (or does nothing if they cancel).
  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTimeOfDay,
    );
    if (picked != null) {
      setState(() {
        _reminderTimeOfDay = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minuteStr = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minuteStr $period';
  }

  // "HH:mm" 24-hour, for storage/scheduling.
  String _reminderTimeAsString() {
    final hourStr = _reminderTimeOfDay.hour.toString().padLeft(2, '0');
    final minuteStr = _reminderTimeOfDay.minute.toString().padLeft(2, '0');
    return '$hourStr:$minuteStr';
  }

  void _saveMedicine() {
    if (_nameController.text.trim().isEmpty) {
      // A SnackBar is a small message that pops up briefly at the
      // bottom of the screen — good for quick feedback like errors.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a medicine name')),
      );
      return;
    }

    // Guard against saving a "Specific days" medicine with no days
    // actually checked — that would mean it never shows up at all.
    if (_selectedFrequency == 'Specific days' && _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }

    final newMedicine = Medicine(
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim().isEmpty
          ? '1 tablet'
          : _dosageController.text.trim(),
      condition: 'General',
      timing: _selectedTiming.toLowerCase(),
      time: _formatTimeOfDay(_reminderTimeOfDay),
      frequency: _selectedFrequency,
      // List.from(...) makes a real COPY of _selectedDays, so the
      // saved Medicine isn't left referencing this screen's
      // temporary internal list after the screen closes.
      activeDays: List.from(_selectedDays),
      endDate: _hasEndDate && _endDate != null
          ? Medicine.dateToString(_endDate!)
          : null,
      reminderTime: _reminderTimeAsString(),
      reminderStyle: _reminderStyle,
    );

    // Navigator.pop can optionally carry a RESULT back to whoever
    // pushed this screen — here, we send the new Medicine object
    // back so HomeScreen (or the RX scanner) can add it to the list.
    Navigator.pop(context, newMedicine);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Add a medicine',
          style: TextStyle(color: AppColors.primary),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medicine name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: _fieldDecoration('e.g. Warfarin'),
            ),
            const SizedBox(height: 16),

            const Text('Dosage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _dosageController,
              decoration: _fieldDecoration('e.g. 2mg, 1 tablet'),
            ),
            const SizedBox(height: 16),

            const Text('Timing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['After meals', 'Before meals', 'Anytime'].map((option) {
                final isSelected = _selectedTiming == option;
                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedTiming = option;
                    });
                  },
                  selectedColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4C6B63),
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ---- Reminder time ----
            const Text('Reminder time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickReminderTime,
              icon: const Icon(Icons.access_time, size: 18),
              label: Text(_formatTimeOfDay(_reminderTimeOfDay)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Reminder style ----
            const Text('Reminder style', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              'Alarm is louder and harder to miss — good for important medicines.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                {'label': 'Alarm', 'value': 'alarm'},
                {'label': 'Notification', 'value': 'notification'},
              ].map((option) {
                final isSelected = _reminderStyle == option['value'];
                return ChoiceChip(
                  label: Text(option['label']!),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _reminderStyle = option['value']!;
                    });
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4C6B63),
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ---- Frequency: Daily vs Specific days ----
            const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Daily', 'Specific days'].map((option) {
                final isSelected = _selectedFrequency == option;
                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFrequency = option;
                    });
                  },
                  selectedColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4C6B63),
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),

            // Only show the day picker when relevant — this is
            // conditional UI driven by the frequency choice above.
            if (_selectedFrequency == 'Specific days') ...[
              const SizedBox(height: 12),
              // FilterChip (not ChoiceChip) since MULTIPLE days can
              // be selected at once, unlike Timing/Frequency above
              // which only ever allow one active choice.
              Wrap(
                spacing: 6,
                children: _allDays.map((day) {
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(day, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedDays.add(day);
                        } else {
                          _selectedDays.remove(day);
                        }
                      });
                    },
                    selectedColor: AppColors.secondary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF4C6B63),
                    ),
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // ---- Optional end date ----
            CheckboxListTile(
              value: _hasEndDate,
              onChanged: (value) {
                setState(() {
                  _hasEndDate = value ?? false;
                });
              },
              title: const Text('This medicine has an end date', style: TextStyle(fontSize: 13.5)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.secondary,
            ),

            if (_hasEndDate) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickEndDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _endDate == null
                      ? 'Choose end date'
                      : 'Ends: ${Medicine.dateToString(_endDate!)}',
                ),
              ),
            ],
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveMedicine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save medicine', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
    );
  }
}
