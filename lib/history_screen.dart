import 'package:flutter/material.dart';
import 'history_entry.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'All';
  bool _isLoading = true;
  List<HistoryEntry> _allEntries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await HistoryStorage.loadEntries();
    setState(() {
      _allEntries = entries;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Expanded(
                    child: filteredEntries.isEmpty
                        ? Center(
                            child: Text(
                              _allEntries.isEmpty
                                  ? 'No history yet — mark a dose on Home to get started'
                                  : 'No entries for "$_selectedFilter"',
                              textAlign: TextAlign.center,
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
      default:
        bg = const Color(0xFFFBEBD2);
        fg = const Color(0xFF93611B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}