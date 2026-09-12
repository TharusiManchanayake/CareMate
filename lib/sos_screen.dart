import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sos_alert.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _isSending = false;

  // Hardcoded for now — a real version would let the caregiver set
  // this in a settings screen. Being explicit about this limitation
  // rather than pretending it's fully configurable.
  static const _caregiverPhone = '+1234567890';

  Future<void> _handleSosPress() async {
    final confirmed = await _showConfirmation();
    if (confirmed != true) return;

    setState(() {
      _isSending = true;
    });

    try {
      final position = await _getCurrentLocation();

      final now = DateTime.now();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final dateStr = '${now.day} ${months[now.month - 1]} ${now.year}';
      final hour12 = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final minuteStr = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final timeStr = '$hour12:$minuteStr $period';

      await SosStorage.logAlert(SosAlert(
        latitude: position.latitude,
        longitude: position.longitude,
        date: dateStr,
        time: timeStr,
      ));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location shared. Opening phone dialer...')),
      );

      await _callCaregiver();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not complete request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // Handles the full permission-request dance geolocator requires
  // before it'll actually give you a location.
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are turned off');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied — enable it in phone settings');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _callCaregiver() async {
    final uri = Uri(scheme: 'tel', path: _caregiverPhone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<bool?> _showConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send emergency alert?'),
        content: const Text(
          'This will share your current location and open your phone dialer to call your caregiver.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD2574C)),
            child: const Text('Send Alert', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B1512), Color(0xFF1E4038)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _isSending ? null : _handleSosPress,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-0.3, -0.4),
                    colors: [Color(0xFFE4685C), Color(0xFFD2574C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD2574C).withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Center(
                  child: _isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tap to alert',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Emergency Assistance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Pressing this button shares your real location and opens your phone to call your caregiver.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}