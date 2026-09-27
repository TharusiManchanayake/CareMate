import 'app_colors.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'add_medicine_screen.dart';
import 'medicine.dart';

class RxScannerScreen extends StatefulWidget {
  const RxScannerScreen({super.key});

  @override
  State<RxScannerScreen> createState() => _RxScannerScreenState();
}

class _RxScannerScreenState extends State<RxScannerScreen> {
  File? _pickedImage; // the photo the user took, once they've taken one
  String _recognizedText = '';
  bool _isProcessing = false;

  // ImagePicker handles opening the camera app and getting the
  // resulting photo back as a file.
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo == null) return; // user cancelled the camera

    setState(() {
      _pickedImage = File(photo.path);
      _isProcessing = true;
      _recognizedText = '';
    });

    await _runTextRecognition(File(photo.path));
  }

  Future<void> _runTextRecognition(File imageFile) async {
    // TextRecognizer is the actual ML Kit OCR engine — it takes an
    // InputImage (built from our file) and returns a RecognizedText
    // object containing everything it could read.
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final inputImage = InputImage.fromFile(imageFile);

    try {
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      setState(() {
        _recognizedText = recognizedText.text;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _recognizedText = 'Could not read text from this image. Try again with better lighting.';
        _isProcessing = false;
      });
    } finally {
      // Always release the recognizer's resources when done, similar
      // in spirit to dispose() on a controller.
      textRecognizer.close();
    }
  }

  // FIX: previously the scanner only ever displayed the raw OCR
  // text — there was no way to turn a scanned prescription into an
  // actual scheduled medicine, so the caregiver had to re-type
  // everything by hand in Add Medicine anyway. This takes the first
  // non-empty line (usually the medicine's name on a label) as a
  // starting point, opens Add Medicine pre-filled, and — if the
  // caregiver saves it there — passes that new Medicine straight
  // back up to whoever opened the scanner (see main.dart), so it's
  // scheduled in one flow instead of two disconnected screens.
  Future<void> _addAsMedicine() async {
    final firstLine = _recognizedText
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicineScreen(initialName: firstLine),
      ),
    );

    if (result != null && result is Medicine && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Prescription scanner', style: TextStyle(color: AppColors.primary)),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Take a photo of a prescription and CareMate will try to read the text.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF4C6B63)),
            ),
            const SizedBox(height: 20),

            // Show the photo preview once one's been taken, otherwise
            // a placeholder box.
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: _pickedImage == null
                  ? const Center(
                      child: Icon(Icons.camera_alt_outlined, size: 48, color: Color(0xFFBFAF8D)),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(_pickedImage!, fit: BoxFit.cover),
                    ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else if (_recognizedText.isNotEmpty) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✓ Text recognized',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.successFg,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recognizedText,
                          style: const TextStyle(fontSize: 13.5, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addAsMedicine,
                  icon: const Icon(Icons.add),
                  label: const Text('Use this as a new medicine'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
