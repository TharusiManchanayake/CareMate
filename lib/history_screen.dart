import 'package:flutter/material.dart';

// A record of one dose event — separate from Medicine, because a
// medicine can have MANY history entries over time (one per dose),
// while Medicine itself just represents "today's" current status.
class HistoryEntry {
  final String medicineName;
  final String date; // e.g. "15 Aug"
  final String time; // e.g. "8:00 AM"
  final String status; // 'taken', 'missed', or 'snoozed'

  HistoryEntry({
    required this.medicineName,
    required this.date,
    required this.time,
    required this.status,
  });
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';

  // Mock data for now — in a later step we'll replace this with
  // real entries logged automatically whenever Taken/Snooze/Skip
  // is pressed on the Home screen.
  final List<HistoryEntry> _allEntries = [
    HistoryEntry(medicineName: 'Metformin 500mg', date: '15 Aug', time: '8:00 AM', status: 'taken'),
    HistoryEntry(medicineName: 'Amlodipine 5mg', date: '14 Aug', time: '9:41 AM', status: 'snoozed'),
    HistoryEntry(medicineName: 'Atorvastatin 10mg', date: '14 Aug', time: '8:00 PM', status: 'missed'),
    HistoryEntry(medicineName: 'Vitamin D 1000IU', date: '13 Aug', time: '1:00 PM', status: 'taken'),
    HistoryEntry(medicineName: 'Metformin 500mg', date: '13 Aug', time: '8:00 AM', status: 'taken'),
  ];

  @override
  Widget build(BuildContext context) {
    // .where() filters the full list down based on the selected chip.
    // If 'All' is selected, skip filtering entirely and show everything.
    final filteredEntries = _selectedFilter == 'All'
        ? _allEntries
        : _allEntries.where((e) => e.status == _selectedFilter.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EC),
        elevation: 0,
        title: const Text('Medication log', style: TextStyle(color: Color(0xFF1E4038))),
        iconTheme: const IconThemeData(color: Color(0xFF1E4038)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter chip row
            Wrap(
              spacing: 8,
              children: ['All', 'Taken', 'Missed', 'Snoozed'].map((option) {
                final isSelected = _selectedFilter == option;
                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedFilter = option;
                    });
                  },
                  selectedColor: const Color(0xFF1E4038),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF4C6B63),
                    fontWeight: FontWeight.bold,
                  ),
                  backgroundColor: Colors.white,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // The filtered list, scrollable, taking up remaining space
            Expanded(
              child: filteredEntries.isEmpty
                  ? Center(
                      child: Text(
                        'No entries for "$_selectedFilter"',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredEntries.length,
                      itemBuilder: (context, index) {
                        return _historyRow(filteredEntries[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyRow(HistoryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4DDCB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.medicineName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.date} · ${entry.time}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          _statusBadge(entry.status),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    // Pick a color scheme based on the status string.
    Color bg;
    Color fg;
    switch (status) {
      case 'taken':
        bg = const Color(0xFFE4EFE6);
        fg = const Color(0xFF2F5B45);
        break;
      case 'missed':
        bg = const Color(0xFFFBE3E0);
        fg = const Color(0xFF9A362D);
        break;
      default: // snoozed
        bg = const Color(0xFFFBEBD2);
        fg = const Color(0xFF93611B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(
        status[0].toUpperCase() + status.substring(1), // capitalize first letter
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}