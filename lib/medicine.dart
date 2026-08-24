// A "model" class — just a plain Dart class that represents one
// real-world thing (a medicine) as structured data. No UI code
// here at all, purely data.
class Medicine {
  final String name;
  final String dosage;
  final String condition; // e.g. "Blood pressure"
  final String timing; // e.g. "after breakfast"
  final String time; // e.g. "9:41 AM"
  bool isTaken; // NOT final — this one needs to change over time

  Medicine({
    required this.name,
    required this.dosage,
    required this.condition,
    required this.timing,
    required this.time,
    this.isTaken = false, // default value if not specified
  });
}