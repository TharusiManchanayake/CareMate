import 'package:flutter/material.dart';
import 'medicine.dart';

class InventoryScreen extends StatelessWidget {
  final List<Medicine> medicines;

  const InventoryScreen({super.key, required this.medicines});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EC),
        elevation: 0,
        title: const Text('Medicine stock', style: TextStyle(color: Color(0xFF1E4038))),
        iconTheme: const IconThemeData(color: Color(0xFF1E4038)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: medicines.length,
        itemBuilder: (context, index) {
          return _stockCard(medicines[index]);
        },
      ),
    );
  }

  Widget _stockCard(Medicine med) {
    // Assume 30 tablets is "full stock" for the progress bar's scale.
    const fullStock = 30;
    final fraction = (med.stockCount / fullStock).clamp(0.0, 1.0);
    final isLow = med.stockCount <= 5;

    Color barColor;
    if (isLow) {
      barColor = const Color(0xFFD2574C);
    } else if (fraction < 0.5) {
      barColor = const Color(0xFFE9A23B);
    } else {
      barColor = const Color(0xFF7FA98D);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4DDCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                med.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '${med.stockCount} left',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ClipRRect rounds the corners of whatever's inside it —
          // here, the LinearProgressIndicator bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: fraction, // 0.0 to 1.0
              minHeight: 7,
              backgroundColor: const Color(0xFFEFE7D4),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),

          if (isLow) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ Running low — reorder soon',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF9A362D),
              ),
            ),
          ],
        ],
      ),
    );
  }
}