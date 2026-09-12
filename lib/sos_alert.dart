import 'package:cloud_firestore/cloud_firestore.dart';

// A real emergency alert record — this is what would let a real
// caregiver-side view someday show "Mary triggered SOS at X near Y".
class SosAlert {
  final double latitude;
  final double longitude;
  final String date;
  final String time;

  SosAlert({
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'date': date,
      'time': time,
    };
  }
}

class SosStorage {
  // Each alert becomes its own document, using the current
  // timestamp as part of the ID so alerts never overwrite each
  // other — unlike medicines, where each one has ONE ongoing
  // document, every SOS press is a distinct historical event.
  static Future<void> logAlert(SosAlert alert) async {
    await FirebaseFirestore.instance.collection('sos_alerts').add(alert.toMap());
  }
}