import 'package:flutter/material.dart';
import 'medicine.dart';
import 'add_medicine_screen.dart';

class CaregiverScreen extends StatefulWidget {
  final List<Medicine> medicines;
  final VoidCallback onDataChanged;

  const CaregiverScreen({
    super.key,
    required this.medicines,
    required this.onDataChanged,
  });

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  Future<void> _openAddMedicineScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicineScreen()),
    );

    if (result != null && result is Medicine) {
      setState(() {
        widget.medicines.add(result);
      });
      widget.onDataChanged();
    }
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
              
              MedicineCloudSync.deleteMedicine(med);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD2574C)),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EC),
        elevation: 0,
        title: const Text('Manage schedule', style: TextStyle(color: Color(0xFF1E4038))),
        iconTheme: const IconThemeData(color: Color(0xFF1E4038)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE4EFE6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Color(0xFF2F5B45)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You're editing Mary's medicine schedule. Changes appear on her Home screen immediately.",
                      style: TextStyle(fontSize: 12, color: Color(0xFF2F5B45)),
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
                            border: Border.all(color: const Color(0xFFE4DDCB)),
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
                                icon: const Icon(Icons.delete_outline, color: Color(0xFF9A362D)),
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
        backgroundColor: const Color(0xFF1E4038),
        onPressed: _openAddMedicineScreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}