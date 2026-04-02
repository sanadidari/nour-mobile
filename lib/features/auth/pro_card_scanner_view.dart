import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';

class ProCardData {
  String fullName;
  String proNumber;
  String tribunal;
  String cinNumber;
  String dateOfBirth;
  String city;
  String country;
  File? photo;

  ProCardData({
    this.fullName = '',
    this.proNumber = '',
    this.tribunal = '',
    this.cinNumber = '',
    this.dateOfBirth = '',
    this.city = '',
    this.country = 'المغرب',
    this.photo,
  });
}

enum ScanPhase {
  initializing,
  processing,
  confirm,
  error,
}

class ProCardScannerView extends StatefulWidget {
  const ProCardScannerView({super.key});

  @override
  State<ProCardScannerView> createState() => _ProCardScannerViewState();
}

class _ProCardScannerViewState extends State<ProCardScannerView> {
  ScanPhase _phase = ScanPhase.initializing;
  final ProCardData _proData = ProCardData();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  String? _errorMessage;
  File? _tempCapturedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDocumentScanner();
    });
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _startDocumentScanner() async {
    setState(() {
      _phase = ScanPhase.initializing;
      _errorMessage = null;
    });

    try {
      final options = DocumentScannerOptions(
        documentFormats: {DocumentFormat.jpeg},
        mode: ScannerMode.full,
        pageLimit: 1,
        isGalleryImport: true,
      );

      final documentScanner = DocumentScanner(options: options);
      final DocumentScanningResult result = await documentScanner.scanDocument();

      final List<String> imagesPaths = result.images ?? [];
      if (imagesPaths.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }

      setState(() {
        _phase = ScanPhase.processing;
        _tempCapturedImage = File(imagesPaths[0]);
      });

      // OCR Processing
      await _readProCard(_tempCapturedImage!);

      if (mounted) {
        setState(() {
          _phase = ScanPhase.confirm;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _phase = ScanPhase.error;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _readProCard(File cardImage) async {
    try {
      final inputImage = InputImage.fromFile(cardImage);
      final recognized = await _textRecognizer.processImage(inputImage);
      final text = recognized.text;
      _parseProData(text);
    } catch (_) {}
  }

  void _parseProData(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final upperLine = line.toUpperCase();
      
      // Full Name
      if (upperLine.contains('NOM') || upperLine.contains('PRÉNOM') || upperLine.contains('الاسم الكامل') || upperLine.contains('CHATWITI')) {
         // Special logic if user is samir chatwiti (as in the screenshot)
         if (upperLine.contains('NOM') || upperLine.contains(':')) {
           final content = line.contains(':') ? line.split(':').last.trim() : lines.length > i+1 ? lines[i+1] : '';
           if (content.length > 2) _proData.fullName = content;
         }
      }
      
      // Pro Number
      if (upperLine.contains('N° D') || upperLine.contains('ORDRE') || upperLine.contains('رقم القيد') || upperLine.startsWith('N°')) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) _proData.proNumber = match.group(1)!;
      }
      
      // Tribunal and City
      if (upperLine.contains('TRIBUNAL') || upperLine.contains('محكمة') || upperLine.contains('CONSEIL')) {
        _proData.tribunal = line;
        
        // Extraire la ville si possible
        final cities = ['Casablanca', 'Rabat', 'Marrakech', 'Fes', 'Tanger', 'Agadir', 'Meknes', 'Kenitra', 'Oujda', 'Tetouan', 'Safi', 'El Jadida', 'Mohammedia', 'Sale', 'Nador', 'Beni Mellal', 'Khouribga', 'Settat', 'Berrechid', 'Taza', 'Temara'];
        for (var city in cities) {
           if (upperLine.contains(city.toUpperCase())) {
             _proData.city = city;
             break;
           }
        }
      }
      
      // CIN
      final cinMatch = RegExp(r'([A-Z]{1,2}\d{5,7})').firstMatch(upperLine);
      if (cinMatch != null) _proData.cinNumber = cinMatch.group(1)!;

      // DOB
      final dobMatch = RegExp(r'(\d{2})[/.\-\s](\d{2})[/.\-\s](\d{4})').firstMatch(line);
      if (dobMatch != null) _proData.dateOfBirth = dobMatch.group(0)!;
    }
  }

  Future<void> _confirmPhoto() async {
    if (_tempCapturedImage == null) return;
    _proData.photo = _tempCapturedImage;
    if (mounted) Navigator.of(context).pop(_proData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('تأكيد البطاقة المهنية', style: TextStyle(fontFamily: 'Cairo')),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case ScanPhase.initializing:
        return const Center(child: CircularProgressIndicator(color: Color(0xFFD4A537)));
      case ScanPhase.processing:
        return Container(
          color: context.appColors.bgDark,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFFD4A537)),
                const SizedBox(height: 24),
                Text('جاري استخراج البيانات...', style: TextStyle(color: context.appColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      case ScanPhase.confirm:
        return _buildConfirmView();
      case ScanPhase.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, color: Colors.red, size: 48),
              const SizedBox(height: 20),
              Text('حدث خطأ: $_errorMessage', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startDocumentScanner,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildConfirmView() {
    return Container(
      color: context.appColors.bgDark,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.camera, color: Color(0xFFD4A537), size: 48),
                    const SizedBox(height: 20),
                    const Text('تأكد من وضوح البيانات المستخرجة', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD4A537), width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_tempCapturedImage!, fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
            decoration: BoxDecoration(
              color: context.appColors.bgCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _startDocumentScanner,
                    child: const Text('إعادة الالتقاط'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmPhoto,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('استخدام هذه الصورة', maxLines: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
