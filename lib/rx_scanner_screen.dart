import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF6EC),
        elevation: 0,
        title: const Text('Prescription scanner', style: TextStyle(color: Color(0xFF1E4038))),
        iconTheme: const IconThemeData(color: Color(0xFF1E4038)),
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
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4DDCB)),
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
                  backgroundColor: const Color(0xFF1E4038),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else if (_recognizedText.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4EFE6),
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
                            color: Color(0xFF2F5B45),
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
          ],
        ),
      ),
    );
  }
}