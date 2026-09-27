import 'package:flutter/material.dart';
import 'medicine.dart';
import 'app_colors.dart';

class InventoryScreen extends StatelessWidget {
  final List<Medicine> medicines;

  const InventoryScreen({super.key, required this.medicines});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Medicine stock', style: TextStyle(color: AppColors.primary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
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
      barColor = AppColors.dangerMain;
    } else if (fraction < 0.5) {
      barColor = AppColors.gold;
    } else {
      barColor = AppColors.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
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
                color: AppColors.dangerFg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
