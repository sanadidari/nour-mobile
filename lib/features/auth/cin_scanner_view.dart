import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:nour/core/theme.dart';
import 'package:path_provider/path_provider.dart';

class CinData {
  String cinNumber;
  String lastName;
  String firstName;
  String dateOfBirth;
  String address;
  String city;
  String country;
  File? rectoImage;
  File? versoImage;

  CinData({
    this.cinNumber = '',
    this.lastName = '',
    this.firstName = '',
    this.dateOfBirth = '',
    this.address = '',
    this.city = '',
    this.country = 'المغرب',
    this.rectoImage,
    this.versoImage,
  });
}

enum ScanPhase {
  scanningRecto,
  processingRecto,
  confirmRecto,
  waitForFlip,
  scanningVerso,
  processingVerso,
  confirmVerso,
  done,
}

class CinScannerView extends StatefulWidget {
  const CinScannerView({super.key});

  @override
  State<CinScannerView> createState() => _CinScannerViewState();
}

class _CinScannerViewState extends State<CinScannerView> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  int _stableFrames = 0;
  final int _requiredStableFrames = 8;
  double _detectionProgress = 0;
  ScanPhase _phase = ScanPhase.scanningRecto;
  final CinData _cinData = CinData();
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  File? _tempCapturedImage; // Image CROPPÉE de la carte seule
  int _frameSkip = 0;

  bool _isSharp = false;
  bool _hasCard = false;
  String _qualityMessage = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _stopCamera();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _stopCamera() async {
    try {
      if (_cameraController != null) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
      } catch (_) {}

      if (mounted) {
        setState(() => _isInitialized = true);
        await Future.delayed(const Duration(milliseconds: 800));
        _startDetection();
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  void _startDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (_cameraController!.value.isStreamingImages) return;
    _stableFrames = 0;
    _detectionProgress = 0;
    _isSharp = false;
    _hasCard = false;
    _cameraController!.startImageStream(_processFrame);
  }

  void _processFrame(CameraImage image) {
    if (_isProcessing) return;
    if (_phase != ScanPhase.scanningRecto && _phase != ScanPhase.scanningVerso)
      return;

    _frameSkip++;
    if (_frameSkip % 4 != 0) return;

    _isProcessing = true;

    try {
      final quality = _analyzeQuality(image);

      if (!mounted) {
        _isProcessing = false;
        return;
      }

      final cardDetected = quality['hasCard'] as bool;
      final sharp = quality['isSharp'] as bool;
      final bothOk = cardDetected && sharp;

      setState(() {
        _isSharp = sharp;
        _hasCard = cardDetected;

        if (!cardDetected) {
          _qualityMessage = 'ضع البطاقة داخل الإطار';
        } else if (!sharp) {
          _qualityMessage = 'الصورة غير واضحة، ثبّت يدك';
        } else {
          _qualityMessage = 'ممتاز! ابقِ ثابتاً...';
        }
      });

      if (bothOk) {
        _stableFrames++;
        final progress = min(1.0, _stableFrames / _requiredStableFrames);
        setState(() => _detectionProgress = progress);

        if (_stableFrames >= _requiredStableFrames) {
          _captureAndProcess();
        }
      } else {
        _stableFrames = max(0, _stableFrames - 2);
        setState(
          () => _detectionProgress = max(
            0,
            _stableFrames / _requiredStableFrames,
          ),
        );
      }
    } catch (_) {}

    _isProcessing = false;
  }

  Map<String, dynamic> _analyzeQuality(CameraImage image) {
    final plane = image.planes[0];
    final bytes = plane.bytes;
    final width = image.width;
    final height = image.height;
    final bpr = plane.bytesPerRow;

    final startX = (width * 0.2).toInt();
    final endX = (width * 0.8).toInt();
    final startY = (height * 0.3).toInt();
    final endY = (height * 0.7).toInt();

    // Laplacien pour la netteté
    double lapSum = 0, lapSumSq = 0;
    int lapCount = 0;

    for (int y = startY + 2; y < endY - 2; y += 4) {
      for (int x = startX + 2; x < endX - 2; x += 4) {
        final idx = y * bpr + x;
        final idxUp = (y - 2) * bpr + x;
        final idxDown = (y + 2) * bpr + x;
        final idxLeft = y * bpr + (x - 2);
        final idxRight = y * bpr + (x + 2);

        if (idxDown >= bytes.length || idxRight >= bytes.length) continue;

        final lap =
            (4 * bytes[idx] -
                    bytes[idxUp] -
                    bytes[idxDown] -
                    bytes[idxLeft] -
                    bytes[idxRight])
                .abs()
                .toDouble();
        lapSum += lap;
        lapSumSq += lap * lap;
        lapCount++;
      }
    }

    double sharpness = 0;
    if (lapCount > 0) {
      final lapMean = lapSum / lapCount;
      sharpness = (lapSumSq / lapCount) - (lapMean * lapMean);
    }

    // Edge density
    int innerEdges = 0, innerCount = 0;
    for (int y = startY; y < endY; y += 3) {
      for (int x = startX; x < endX - 3; x += 3) {
        final idx = y * bpr + x;
        final idxR = y * bpr + (x + 3);
        if (idx >= bytes.length || idxR >= bytes.length) continue;
        innerCount++;
        if ((bytes[idxR] - bytes[idx]).abs() > 20) innerEdges++;
      }
    }

    double edgeDensity = innerCount > 0 ? innerEdges / innerCount : 0;

    return {'hasCard': edgeDensity > 0.06, 'isSharp': sharpness > 150};
  }

  // =======================================================
  // CAPTURE + DÉTECTION INTELLIGENTE DES BORDS DE LA CARTE
  // =======================================================

  Future<void> _captureAndProcess() async {
    if (_cameraController == null) return;

    final isRecto = _phase == ScanPhase.scanningRecto;
    setState(() {
      _phase = isRecto ? ScanPhase.processingRecto : ScanPhase.processingVerso;
      _qualityMessage = 'جاري استخراج البطاقة...';
    });

    try {
      await _cameraController!.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 300));

      final XFile photo = await _cameraController!.takePicture();
      final fullImageFile = File(photo.path);

      // === ÉTAPE 1 : Détecter les bords de la carte via OCR ===
      final croppedFile = await _detectAndCropCard(fullImageFile, isRecto);

      if (mounted) {
        setState(() {
          _tempCapturedImage = croppedFile;
          _phase = isRecto ? ScanPhase.confirmRecto : ScanPhase.confirmVerso;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stableFrames = 0;
          _detectionProgress = 0;
          _phase = isRecto ? ScanPhase.scanningRecto : ScanPhase.scanningVerso;
          _qualityMessage = 'خطأ، أعد المحاولة';
        });
        _startDetection();
      }
    }
  }

  Future<void> _manualCapture() async {
    if (_cameraController == null || !_isSharp || !_hasCard) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !_hasCard ? 'البطاقة غير مكتشفة' : 'الصورة غير واضحة، ثبّت يدك',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    await _captureAndProcess();
  }

  /// Détecte les bords de la carte via les blocs de texte OCR
  /// et retourne l'image croppée de la carte seule
  Future<File> _detectAndCropCard(File fullImageFile, bool isRecto) async {
    // Lancer OCR sur l'image complète pour trouver les blocs de texte
    final inputImage = InputImage.fromFile(fullImageFile);
    final recognized = await _textRecognizer.processImage(inputImage);

    // Lire les dimensions de l'image
    final imageBytes = await fullImageFile.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return fullImageFile;

    final imgW = decoded.width;
    final imgH = decoded.height;

    // Trouver le rectangle englobant tous les blocs de texte
    int minX = imgW, minY = imgH, maxX = 0, maxY = 0;
    int textBlockCount = 0;

    for (final block in recognized.blocks) {
      final bbox = block.boundingBox;
      if (bbox.left < minX) minX = bbox.left.toInt();
      if (bbox.top < minY) minY = bbox.top.toInt();
      if (bbox.right > maxX) maxX = bbox.right.toInt();
      if (bbox.bottom > maxY) maxY = bbox.bottom.toInt();
      textBlockCount++;
    }

    File croppedFile;
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/cin_scans');
    if (!await folder.exists()) await folder.create(recursive: true);
    final side = isRecto ? 'recto' : 'verso';
    final destPath =
        '${folder.path}/cin_${side}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (textBlockCount >= 3 && maxX > minX && maxY > minY) {
      // Ajouter un padding de 8% autour des blocs de texte
      final textW = maxX - minX;
      final textH = maxY - minY;
      final padX = (textW * 0.08).toInt();
      final padY = (textH * 0.12).toInt();

      final cropX = (minX - padX).clamp(0, imgW - 1);
      final cropY = (minY - padY).clamp(0, imgH - 1);
      final cropW = (textW + padX * 2).clamp(1, imgW - cropX);
      final cropH = (textH + padY * 2).clamp(1, imgH - cropY);

      final cropped = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );
      croppedFile = File(destPath);
      await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 95));
    } else {
      // Fallback : crop au cadre proportionnel
      final cardW = (imgW * 0.88).toInt();
      final cardH = (cardW / 1.58).toInt();
      final cropX = ((imgW - cardW) / 2).toInt();
      final cropY = ((imgH - cardH) / 2).toInt().clamp(0, imgH - cardH);

      final cropped = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: cardW,
        height: cardH,
      );
      croppedFile = File(destPath);
      await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 95));
    }

    return croppedFile;
  }

  // =======================================================
  // LECTURE OCR SUR L'IMAGE CROPPÉE (après confirmation)
  // =======================================================

  Future<void> _readCroppedCard(File cardImage, bool isRecto) async {
    try {
      final inputImage = InputImage.fromFile(cardImage);
      final recognized = await _textRecognizer.processImage(inputImage);
      final text = recognized.text;

      if (isRecto) {
        _parseRectoData(text);
      } else {
        _parseVersoData(text);
      }
    } catch (_) {}
  }

  /// Parse les données du RECTO — priorité au MRZ (zone machine en bas)
  void _parseRectoData(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // === 1. Chercher la zone MRZ (lignes avec <<< ou IDMAR) ===
    final mrzLines = <String>[];
    for (var line in lines) {
      final cleaned = line.replaceAll(' ', '').toUpperCase();
      if (cleaned.contains('<<<') ||
          cleaned.startsWith('IDMAR') ||
          cleaned.startsWith('1DMAR')) {
        mrzLines.add(cleaned);
      }
    }

    if (mrzLines.length >= 3) {
      _parseMRZ(mrzLines);
      return;
    }

    // Si MRZ non trouvé, essayer de trouver 2-3 longues lignes avec < en fin de texte
    final longLines = <String>[];
    for (var line in lines) {
      final cleaned = line.replaceAll(' ', '').toUpperCase();
      if (cleaned.length > 20 &&
          (cleaned.contains('<') || cleaned.contains('MAR'))) {
        longLines.add(cleaned);
      }
    }
    if (longLines.length >= 2) {
      _parseMRZ(longLines);
      return;
    }

    // === 2. Fallback : extraction classique ===
    _parseRectoClassic(lines);
  }

  /// Parse le MRZ de la CIN marocaine (3 lignes)
  void _parseMRZ(List<String> mrzLines) {
    try {
      // Ligne 1 : IDMAR... + numéro CIN
      // Format: IDMARO[CIN_NUMBER]<...
      if (mrzLines.isNotEmpty) {
        final line1 = mrzLines[0].replaceAll(RegExp(r'[^A-Z0-9<]'), '');
        // Chercher le numéro CIN (2 lettres + 6 chiffres)
        final cinMatch = RegExp(r'([A-Z]{1,2}\d{5,7})').firstMatch(line1);
        if (cinMatch != null) {
          // Filtrer le préfixe IDMAR
          String cin = cinMatch.group(1)!;
          if (cin.startsWith('IDMAR')) {
            cin = cin.substring(5);
            final cinMatch2 = RegExp(r'([A-Z]{1,2}\d{5,7})').firstMatch(cin);
            if (cinMatch2 != null) cin = cinMatch2.group(1)!;
          }
          _cinData.cinNumber = cin;
        }
      }

      // Ligne 2 : Date de naissance (YYMMDD) + sexe + date expiration
      if (mrzLines.length >= 2) {
        final line2 = mrzLines[1].replaceAll(RegExp(r'[^A-Z0-9<]'), '');
        // Format : YYMMDDC... (6 premiers chiffres = DOB)
        final dobMatch = RegExp(r'^(\d{6})').firstMatch(line2);
        if (dobMatch != null) {
          final dob = dobMatch.group(1)!;
          final yy = dob.substring(0, 2);
          final mm = dob.substring(2, 4);
          final dd = dob.substring(4, 6);
          final year = int.parse(yy) > 50 ? '19$yy' : '20$yy';
          _cinData.dateOfBirth = '$dd/$mm/$year';
        }
      }

      // Ligne 3 : NOM<<PRENOM
      if (mrzLines.length >= 3) {
        final line3 = mrzLines[2].replaceAll(RegExp(r'[^A-Z<]'), '');
        final parts = line3.split('<<').where((p) => p.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          _cinData.lastName = parts[0].replaceAll('<', ' ').trim();
        }
        if (parts.length >= 2) {
          _cinData.firstName = parts[1].replaceAll('<', ' ').trim();
        }
      }
    } catch (_) {}
  }

  /// Extraction classique (si MRZ non trouvé)
  void _parseRectoClassic(List<String> lines) {
    // Ignorer les titres de la carte
    final ignorePatterns = [
      'ROYAUME',
      'MAROC',
      'CARTE',
      'NATIONALE',
      'IDENTITE',
      'البطاقة',
      'المملكة',
      'المغربية',
      'الوطنية',
      'للتعريف',
    ];

    // Numéro CIN
    for (var line in lines) {
      final cleaned = line.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final cinMatch = RegExp(r'^[A-Z]{1,2}\d{5,7}$').firstMatch(cleaned);
      if (cinMatch != null) {
        _cinData.cinNumber = cinMatch.group(0)!;
        break;
      }
    }

    // Date
    for (var line in lines) {
      final dateMatch = RegExp(
        r'(\d{2})[/.\-\s](\d{2})[/.\-\s](\d{4})',
      ).firstMatch(line);
      if (dateMatch != null) {
        _cinData.dateOfBirth =
            '${dateMatch.group(1)}/${dateMatch.group(2)}/${dateMatch.group(3)}';
        break;
      }
    }

    // Nom / Prénom — lignes courtes en latin, pas de titres
    final nameLines = <String>[];
    for (var line in lines) {
      final cleaned = line.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ\s]'), '').trim();
      if (cleaned.length < 2 || cleaned.length > 30) continue;
      final isTitle = ignorePatterns.any(
        (p) => cleaned.toUpperCase().contains(p),
      );
      if (!isTitle && cleaned.toUpperCase() != cleaned.toLowerCase()) {
        nameLines.add(cleaned);
      }
    }
    if (nameLines.isNotEmpty) _cinData.lastName = nameLines[0].toUpperCase();
    if (nameLines.length >= 2) _cinData.firstName = nameLines[1];
  }

  void _parseVersoData(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Adresse — ligne la plus longue avec des chiffres
    String bestAddress = '';
    for (var line in lines) {
      if (line.contains(RegExp(r'\d')) &&
          line.length > 10 &&
          line.length > bestAddress.length) {
        if (!line.contains('<<<') && !line.contains('IDMAR')) {
          bestAddress = line;
        }
      }
    }
    if (bestAddress.isNotEmpty) _cinData.address = bestAddress;

    // Ville
    final cities = [
      'Casablanca',
      'Rabat',
      'Marrakech',
      'Fes',
      'Tanger',
      'Agadir',
      'Meknes',
      'Kenitra',
      'Oujda',
      'Tetouan',
      'Safi',
      'El Jadida',
      'Mohammedia',
      'Sale',
      'Nador',
      'Beni Mellal',
      'Khouribga',
      'Settat',
      'Berrechid',
      'Taza',
      'Temara',
    ];
    for (var line in lines) {
      for (var city in cities) {
        if (line.toUpperCase().contains(city.toUpperCase())) {
          _cinData.city = city;
          return;
        }
      }
    }
  }

  // =======================================================
  // ACTIONS UTILISATEUR
  // =======================================================

  Future<void> _confirmRectoPhoto() async {
    if (_tempCapturedImage == null) return;
    _cinData.rectoImage = _tempCapturedImage;
    // Lire les infos DEPUIS l'image croppée propre
    await _readCroppedCard(_tempCapturedImage!, true);
    setState(() {
      _tempCapturedImage = null;
      _phase = ScanPhase.waitForFlip;
    });
  }

  Future<void> _confirmVersoPhoto() async {
    if (_tempCapturedImage == null) return;
    _cinData.versoImage = _tempCapturedImage;
    await _readCroppedCard(_tempCapturedImage!, false);
    setState(() {
      _tempCapturedImage = null;
      _phase = ScanPhase.done;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) Navigator.of(context).pop(_cinData);
  }

  void _retakePhoto() {
    final wasRecto = _phase == ScanPhase.confirmRecto;
    setState(() {
      _tempCapturedImage = null;
      _stableFrames = 0;
      _detectionProgress = 0;
      _phase = wasRecto ? ScanPhase.scanningRecto : ScanPhase.scanningVerso;
    });
    _startDetection();
  }

  void _startVersoScan() {
    setState(() {
      _phase = ScanPhase.scanningVerso;
      _stableFrames = 0;
      _detectionProgress = 0;
    });
    _startDetection();
  }

  // =======================================================
  // UI
  // =======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_getTitle()),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  String _getTitle() {
    switch (_phase) {
      case ScanPhase.scanningRecto:
        return 'مسح الوجه الأمامي';
      case ScanPhase.processingRecto:
        return 'جاري الاستخراج...';
      case ScanPhase.confirmRecto:
        return 'تأكيد الوجه الأمامي';
      case ScanPhase.waitForFlip:
        return 'اقلب البطاقة';
      case ScanPhase.scanningVerso:
        return 'مسح الوجه الخلفي';
      case ScanPhase.processingVerso:
        return 'جاري الاستخراج...';
      case ScanPhase.confirmVerso:
        return 'تأكيد الوجه الخلفي';
      case ScanPhase.done:
        return 'تم!';
    }
  }

  Widget _buildBody() {
    switch (_phase) {
      case ScanPhase.scanningRecto:
      case ScanPhase.scanningVerso:
        return _buildCameraView();
      case ScanPhase.processingRecto:
      case ScanPhase.processingVerso:
        return _buildProcessingView();
      case ScanPhase.confirmRecto:
      case ScanPhase.confirmVerso:
        return _buildConfirmView();
      case ScanPhase.waitForFlip:
        return _buildFlipScreen();
      case ScanPhase.done:
        return Center(
          child: CircularProgressIndicator(color: context.appColors.accentGold),
        );
    }
  }

  /// Écran de traitement (pendant l'extraction)
  Widget _buildProcessingView() {
    return Container(
      color: context.appColors.bgDark,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: context.appColors.accentGold,
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'جاري استخراج البطاقة...',
              style: TextStyle(
                color: context.appColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'الرجاء الانتظار',
              style: TextStyle(
                color: context.appColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Écran caméra
  Widget _buildCameraView() {
    if (!_isInitialized || _cameraController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: context.appColors.accentGold),
            SizedBox(height: 16),
            Text(
              'جاري تشغيل الكاميرا...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: CameraPreview(_cameraController!)),

        // Cadre
        Positioned.fill(
          child: CustomPaint(
            painter: _CardFramePainter(
              progress: _detectionProgress,
              hasCard: _hasCard,
              isSharp: _isSharp,
            ),
          ),
        ),

        // Indicateurs qualité
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _hasCard && _isSharp
                          ? LucideIcons.checkCircle
                          : LucideIcons.info,
                      color: _hasCard && _isSharp
                          ? context.appColors.success
                          : context.appColors.accentGold,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _qualityMessage.isEmpty
                            ? 'ضع البطاقة داخل الإطار'
                            : _qualityMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildQualityBadge(
                      'البطاقة',
                      _hasCard,
                      LucideIcons.creditCard,
                    ),
                    const SizedBox(width: 8),
                    _buildQualityBadge('الوضوح', _isSharp, LucideIcons.focus),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Barre progression
        if (_hasCard && _isSharp)
          Positioned(
            bottom: 130,
            left: 36,
            right: 36,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _detectionProgress,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(
                      _detectionProgress > 0.6
                          ? context.appColors.success
                          : context.appColors.accentGold,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'الالتقاط التلقائي ${(_detectionProgress * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

        // Steps
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepDot(
                'الأمامي',
                _cinData.rectoImage != null,
                _phase == ScanPhase.scanningRecto,
              ),
              Container(
                width: 40,
                height: 2,
                color: _cinData.rectoImage != null
                    ? context.appColors.success
                    : Colors.white24,
              ),
              _buildStepDot(
                'الخلفي',
                _cinData.versoImage != null,
                _phase == ScanPhase.scanningVerso,
              ),
            ],
          ),
        ),

        // Bouton capture manuelle
        Positioned(
          bottom: 10,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _manualCapture,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (_hasCard && _isSharp)
                        ? Colors.white
                        : Colors.white24,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_hasCard && _isSharp)
                          ? Colors.white24
                          : Colors.transparent,
                    ),
                    child: Icon(
                      LucideIcons.camera,
                      color: (_hasCard && _isSharp)
                          ? Colors.white
                          : Colors.white30,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQualityBadge(String label, bool ok, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: ok
              ? context.appColors.success.withOpacity(0.15)
              : Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ok
                ? context.appColors.success.withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              ok ? LucideIcons.checkCircle : icon,
              size: 14,
              color: ok ? context.appColors.success : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: ok ? context.appColors.success : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Écran de confirmation (montre la carte CROPPÉE)
  Widget _buildConfirmView() {
    final isRecto = _phase == ScanPhase.confirmRecto;

    return Container(
      color: context.appColors.bgDark,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.appColors.accentGold.withOpacity(0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _tempCapturedImage != null
                      ? Image.file(_tempCapturedImage!, fit: BoxFit.contain)
                      : const SizedBox(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              isRecto
                  ? 'هل تم استخراج البطاقة بشكل صحيح؟'
                  : 'هل تم استخراج الوجه الخلفي بشكل صحيح؟',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.appColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _retakePhoto,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: context.appColors.error),
                      foregroundColor: context.appColors.error,
                    ),
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    label: const Text('إعادة'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: isRecto
                        ? _confirmRectoPhoto
                        : _confirmVersoPhoto,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: context.appColors.success,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(LucideIcons.checkCircle, size: 18),
                    label: const Text(
                      'تأكيد ✓',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  /// Écran retourner la carte
  Widget _buildFlipScreen() {
    return Container(
      color: context.appColors.bgDark,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_cinData.rectoImage != null)
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.appColors.success,
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_cinData.rectoImage!, fit: BoxFit.cover),
                    Container(
                      color: Colors.black.withOpacity(0.4),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.checkCircle,
                              color: context.appColors.success,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '✓ تم استخراج الأمامي',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 36),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.appColors.accentGold.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: context.appColors.accentGold.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              LucideIcons.rotateCcw,
              size: 48,
              color: context.appColors.accentGold,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'اقلب البطاقة الآن',
            style: TextStyle(
              color: context.appColors.accentGold,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ثم اضغط "جاهز" لمسح الوجه الخلفي',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _startVersoScan,
              icon: const Icon(LucideIcons.camera, size: 20),
              label: const Text('جاهز للمسح', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(String label, bool completed, bool active) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? context.appColors.success
                : (active ? context.appColors.accentGold : Colors.white24),
          ),
          child: Icon(
            completed ? LucideIcons.check : LucideIcons.creditCard,
            size: 14,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? Colors.white : Colors.white54,
          ),
        ),
      ],
    );
  }
}

/// Cadre carte
class _CardFramePainter extends CustomPainter {
  final double progress;
  final bool hasCard;
  final bool isSharp;

  _CardFramePainter({
    required this.progress,
    required this.hasCard,
    required this.isSharp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.55);

    final cardWidth = size.width * 0.88;
    final cardHeight = cardWidth / 1.58;
    final left = (size.width - cardWidth) / 2;
    final top = (size.height - cardHeight) / 2 - 20;
    final cardRect = Rect.fromLTWH(left, top, cardWidth, cardHeight);
    final rrect = RRect.fromRectAndRadius(cardRect, const Radius.circular(14));

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, overlayPaint);

    Color borderColor;
    if (hasCard && isSharp) {
      borderColor = const Color(0xFF10B981);
    } else if (hasCard) {
      borderColor = const Color(0xFFF59E0B);
    } else {
      borderColor = Colors.white38;
    }

    canvas.drawRRect(
      rrect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final cl = 28.0;
    final cp = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(left + 14, top), Offset(left + 14 + cl, top), cp);
    canvas.drawLine(Offset(left, top + 14), Offset(left, top + 14 + cl), cp);
    canvas.drawLine(
      Offset(left + cardWidth - 14, top),
      Offset(left + cardWidth - 14 - cl, top),
      cp,
    );
    canvas.drawLine(
      Offset(left + cardWidth, top + 14),
      Offset(left + cardWidth, top + 14 + cl),
      cp,
    );
    canvas.drawLine(
      Offset(left + 14, top + cardHeight),
      Offset(left + 14 + cl, top + cardHeight),
      cp,
    );
    canvas.drawLine(
      Offset(left, top + cardHeight - 14),
      Offset(left, top + cardHeight - 14 - cl),
      cp,
    );
    canvas.drawLine(
      Offset(left + cardWidth - 14, top + cardHeight),
      Offset(left + cardWidth - 14 - cl, top + cardHeight),
      cp,
    );
    canvas.drawLine(
      Offset(left + cardWidth, top + cardHeight - 14),
      Offset(left + cardWidth, top + cardHeight - 14 - cl),
      cp,
    );
  }

  @override
  bool shouldRepaint(covariant _CardFramePainter old) =>
      old.progress != progress ||
      old.hasCard != hasCard ||
      old.isSharp != isSharp;
}
