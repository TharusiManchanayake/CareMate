import 'package:flutter/material.dart';
import 'doctor_visit.dart';
import 'add_visit_screen.dart';

class DoctorNotesScreen extends StatefulWidget {
  const DoctorNotesScreen({super.key});

  @override
  State<DoctorNotesScreen> createState() => _DoctorNotesScreenState();
}

class _DoctorNotesScreenState extends State<DoctorNotesScreen> {
  bool _isLoading = true;
  List<DoctorVisit> _visits = [];

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    final visits = await DoctorVisitStorage.loadVisits();
    setState(() {
      _visits = visits;
      _isLoading = false;
    });
  }

  Future<void> _openAddVisitScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVisitScreen()),
    );

    if (result != null && result is DoctorVisit) {
      await DoctorVisitStorage.addVisit(result);
      _loadVisits(); // reload from storage to reflect the new entry
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EC),
        elevation: 0,
        title: const Text('Doctor visits', style: TextStyle(color: Color(0xFF1E4038))),
        iconTheme: const IconThemeData(color: Color(0xFF1E4038)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visits.isEmpty
              ? Center(
                  child: Text(
                    'No visits logged yet — tap + to add one',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _visits.length,
                  itemBuilder: (context, index) {
                    return _visitCard(_visits[index]);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E4038),
        onPressed: _openAddVisitScreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _visitCard(DoctorVisit visit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4DDCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                visit.doctorName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
              Text(
                visit.date,
                style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            visit.note,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          if (visit.hasPrescription) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE4EFE6),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Prescription attached',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2F5B45)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}