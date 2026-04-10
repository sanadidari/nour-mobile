import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:developer' as dev;
import 'package:uuid/uuid.dart';
import 'package:nour/core/utils.dart' as utils;

class LocalEvidence {
  final String localPath;
  final Position position;
  final DateTime timestamp;

  LocalEvidence({
    required this.localPath,
    required this.position,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'localPath': localPath,
    'lat': position.latitude,
    'lon': position.longitude,
    'time': timestamp.toUtc().toIso8601String(),
  };

  factory LocalEvidence.fromJson(Map<String, dynamic> json) => LocalEvidence(
    localPath: json['localPath'],
    position: Position(
      latitude: (json['lat'] as num).toDouble(),
      longitude: (json['lon'] as num).toDouble(),
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    ),
    timestamp: DateTime.parse(json['time']).toLocal(),
  );
}

class PendingMission {
  final String id;
  final String dossierId;
  final String interventionType;
  final List<LocalEvidence> evidences;
  final Map<String, String>? formFields;
  final DateTime createdAt;
  bool isSyncing;

  PendingMission({
    required this.id,
    required this.dossierId,
    required this.interventionType,
    required this.evidences,
    this.formFields,
    required this.createdAt,
    this.isSyncing = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'dossierId': dossierId,
    'interventionType': interventionType,
    'evidences': evidences.map((e) => e.toJson()).toList(),
    'formFields': formFields,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory PendingMission.fromJson(Map<String, dynamic> json) => PendingMission(
    id: json['id'] ?? const Uuid().v4(),
    dossierId: json['dossierId'],
    interventionType: json['interventionType'],
    evidences: (json['evidences'] as List)
        .map((e) => LocalEvidence.fromJson(e))
        .toList(),
    formFields: json['formFields'] != null
        ? Map<String, String>.from(json['formFields'])
        : null,
    createdAt: DateTime.parse(
      json['createdAt'] ?? DateTime.now().toUtc().toIso8601String(),
    ).toLocal(),
  );
}

class EvidenceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Vérifie et demande les permissions GPS avant utilisation
  Future<Position?> _getPositionSafely() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return _fallbackPosition();

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return _fallbackPosition();
      }
      if (permission == LocationPermission.deniedForever)
        return _fallbackPosition();

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e, stack) {
      dev.log('Erreur GPS: $e', stackTrace: stack);
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return _fallbackPosition();
      }
    }
  }

  Position _fallbackPosition() {
    return Position(
      latitude: 0,
      longitude: 0,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  Future<LocalEvidence?> captureLocal() async {
    final Position pos = await _getPositionSafely() ?? _fallbackPosition();
    await _savePreCaptureState(pos);

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 25,
      maxWidth: 800,
      maxHeight: 600,
    );

    if (photo == null) {
      await _clearPreCaptureState();
      return null;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final evidenceDir = Directory('${appDir.path}/evidence_photos');
    if (!await evidenceDir.exists()) {
      await evidenceDir.create(recursive: true);
    }
    final savedPath =
        '${evidenceDir.path}/ev_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(photo.path).copy(savedPath);

    await _clearPreCaptureState();

    return LocalEvidence(
      localPath: savedPath,
      position: pos,
      timestamp: DateTime.now(),
    );
  }

  Future<LocalEvidence?> retrieveLostCapture() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null) return null;

      final pos = await _loadPreCaptureState();
      final appDir = await getApplicationDocumentsDirectory();
      final evidenceDir = Directory('${appDir.path}/evidence_photos');
      if (!await evidenceDir.exists())
        await evidenceDir.create(recursive: true);

      final savedPath =
          '${evidenceDir.path}/ev_recovered_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(response.file!.path).copy(savedPath);
      await _clearPreCaptureState();

      return LocalEvidence(
        localPath: savedPath,
        position: pos ?? _fallbackPosition(),
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePreCaptureState(Position pos) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/pre_capture_gps.json');
      await file.writeAsString(
        jsonEncode({
          'lat': pos.latitude,
          'lon': pos.longitude,
          'time': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  Future<Position?> _loadPreCaptureState() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/pre_capture_gps.json');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString());
        return Position(
          latitude: (data['lat'] as num).toDouble(),
          longitude: (data['lon'] as num).toDouble(),
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _clearPreCaptureState() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/pre_capture_gps.json');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  /// Cette méthode remplace l'ancienne approche directe.
  /// Elle place la mission dans la file d'attente locale.
  Future<String> stageMissionForUpload({
    required String dossierId,
    required String interventionType,
    required List<LocalEvidence> queue,
    Map<String, String>? formFields,
  }) async {
    final missionId = const Uuid().v4();
    final mission = PendingMission(
      id: missionId,
      dossierId: dossierId,
      interventionType: interventionType,
      evidences: queue,
      formFields: formFields,
      createdAt: DateTime.now(),
    );

    await _saveToQueue(mission);
    await clearPersistence(); // Nettoyer le brouillon de capture
    return missionId;
  }

  Future<void> _saveToQueue(PendingMission mission) async {
    final appDir = await getApplicationDocumentsDirectory();
    final queueDir = Directory('${appDir.path}/upload_queue');
    if (!await queueDir.exists()) await queueDir.create(recursive: true);

    final file = File('${queueDir.path}/${mission.id}.json');
    await file.writeAsString(jsonEncode(mission.toJson()));
  }

  Future<List<PendingMission>> getPendingMissions() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final queueDir = Directory('${appDir.path}/upload_queue');
      if (!await queueDir.exists()) return [];

      final files = queueDir.listSync().whereType<File>().toList();
      final List<PendingMission> missions = [];
      for (var f in files) {
        if (f.path.endsWith('.json')) {
          try {
            final content = await f.readAsString();
            missions.add(PendingMission.fromJson(jsonDecode(content)));
          } catch (e) {
            dev.log('Fichier JSON mission corrompu: ${f.path} - $e');
          }
        }
      }
      // Trier par date
      missions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return missions;
    } catch (_) {
      return [];
    }
  }

  /// Nettoie les anciens fichiers photos locaux qui datent de plus de 7 jours
  Future<int> cleanupOldLocalPhotos({int daysOlderThan = 7}) async {
    int deletedCount = 0;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final evidenceDir = Directory('${appDir.path}/evidence_photos');
      if (await evidenceDir.exists()) {
        final threshold = DateTime.now().subtract(
          Duration(days: daysOlderThan),
        );
        final files = evidenceDir.listSync().whereType<File>().toList();
        for (var file in files) {
          final stat = await file.stat();
          if (stat.modified.isBefore(threshold)) {
            try {
              await file.delete();
              deletedCount++;
            } catch (_) {}
          }
        }
      }
      if (deletedCount > 0)
        dev.log(
          'Nettoyage local: $deletedCount fichiers supprimés (> $daysOlderThan jours)',
        );
    } catch (e) {
      dev.log('Erreur nettoyage local: $e');
    }
    return deletedCount;
  }

  Future<void> removeMissionFromQueue(String id) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File('${appDir.path}/upload_queue/$id.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e, stack) {
      dev.log('Erreur suppression mission queue: $e', stackTrace: stack);
    }
  }

  /// Exécute l'upload d'une mission spécifique
  Future<void> uploadMission(PendingMission mission) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('غير مسجل الدخول');

    for (var ev in mission.evidences) {
      // 1. Process image specifically for upload
      File? processedFile;
      try {
        processedFile = await processImage(
          File(ev.localPath),
          dossierId: mission.dossierId,
          interventionType: mission.interventionType,
          position: ev.position,
          timestamp: ev.timestamp,
        );
      } catch (e, stack) {
        dev.log(
          "Erreur processImage pour ${ev.localPath}: $e",
          stackTrace: stack,
        );
        rethrow;
      }

      final String fileExt = processedFile.path.split('.').last;
      final String fileName =
          '$userId/EVD_${DateTime.now().millisecondsSinceEpoch}_${const Uuid().v4()}.$fileExt';

      bool storageSuccess = false;
      try {
        // 2. Upload photo
        await _supabase.storage
            .from('evidence')
            .upload(fileName, processedFile);
        storageSuccess = true;

        // 3. Insert metadata
        await _supabase.from('evidence').insert({
          'user_id': userId,
          'image_path': fileName,
          'captured_at': ev.timestamp.toUtc().toIso8601String(),
          'dossier_id': mission.dossierId,
          'intervention_type': mission.interventionType,
          'latitude': ev.position.latitude,
          'longitude': ev.position.longitude,
          'notes': mission.formFields != null
              ? mission.formFields!.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .join(' | ')
              : '',
        });

        // 4. Nettoyage physique du fichier local original si tout réussi
        try {
          if (await File(ev.localPath).exists())
            await File(ev.localPath).delete();
          if (await processedFile.exists()) await processedFile.delete();
        } catch (_) {}
      } catch (e, stack) {
        dev.log("Erreur lors de l'upload/insert: $e", stackTrace: stack);
        // Si l'insert a échoué mais le storage a réussi, on essaie de nettoyer le storage pour éviter les orphelins
        if (storageSuccess) {
          try {
            await _supabase.storage.from('evidence').remove([fileName]);
            dev.log("Nettoyage storage réussi après échec metadata insert.");
          } catch (cleanupErr) {
            dev.log("Échec du nettoyage storage orphelin: $cleanupErr");
          }
        }
        rethrow;
      }
    }

    // Mission finie, retirer du JSON
    await removeMissionFromQueue(mission.id);
  }

  Future<List<Map<String, dynamic>>> getHistory({
    int limit = 100,
    int offset = 0,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final response = await _supabase
          .from('evidence')
          .select()
          .eq('user_id', userId)
          .order('captured_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, int>> getStats() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return {'total': 0, 'today': 0, 'photos': 0};
    try {
      final all = await _supabase
          .from('evidence')
          .select('id, captured_at, dossier_id')
          .eq('user_id', userId);
      final List<dynamic> records = all as List;
      final dossiers = <String>{};
      final todayDossiers = <String>{};
      final today = DateTime.now();
      for (var r in records) {
        final dId = (r['dossier_id']?.toString() ?? '').trim();
        if (dId.isNotEmpty) dossiers.add(dId);
        final capturedAt = DateTime.tryParse(r['captured_at'] ?? '')?.toLocal();
        if (capturedAt != null &&
            capturedAt.year == today.year &&
            capturedAt.month == today.month &&
            capturedAt.day == today.day) {
          if (dId.isNotEmpty) todayDossiers.add(dId);
        }
      }
      return {
        'photos': records.length,
        'dossiers': dossiers.length,
        'today': todayDossiers.length,
      };
    } catch (_) {
      return {'photos': 0, 'dossiers': 0, 'today': 0};
    }
  }

  Future<void> saveQueuePersistence(
    List<LocalEvidence> queue, {
    String? dossierId,
    String? interventionType,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/mission_draft.json');
    await file.writeAsString(
      jsonEncode({
        'queue': queue.map((e) => e.toJson()).toList(),
        'dossierId': dossierId,
        'interventionType': interventionType,
      }),
    );
  }

  Future<List<LocalEvidence>> loadQueuePersistence() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/mission_draft.json');
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString());
        if (raw is List)
          return raw.map((e) => LocalEvidence.fromJson(e)).toList();
        if (raw is Map && raw['queue'] is List) {
          return (raw['queue'] as List)
              .map((e) => LocalEvidence.fromJson(e))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, String?>> loadFormMetadata() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/mission_draft.json');
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString());
        if (raw is Map)
          return {
            'dossierId': raw['dossierId'] as String?,
            'interventionType': raw['interventionType'] as String?,
          };
      }
    } catch (_) {}
    return {};
  }

  Future<void> clearPersistence() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/mission_draft.json');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  String _formatDateArabic(DateTime dt) => utils.formatDateArabic(dt);

  Future<String> _getAddress(double lat, double lon) async {
    try {
      try {
        await setLocaleIdentifier('ar_MA');
      } catch (_) {}
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        String zone = (p.subLocality?.isNotEmpty == true)
            ? p.subLocality!
            : (p.thoroughfare?.isNotEmpty == true
                  ? p.thoroughfare!
                  : p.subAdministrativeArea ?? '');
        return [
          zone,
          p.locality,
        ].where((e) => e != null && e.isNotEmpty).join('، ');
      }
    } catch (_) {}
    return '';
  }

  Future<File> processImage(
    File originalFile, {
    required String dossierId,
    required String interventionType,
    required Position position,
    required DateTime timestamp,
  }) async {
    final bytes = await originalFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1200);
    final frame = await codec.getNextFrame();
    final ui.Image image = frame.image;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    );

    canvas.drawImage(image, Offset.zero, Paint());

    try {
      // === Draw Round Logo ===
      final logoData = await rootBundle.load('assets/images/logo.png');
      final ui.Codec logoCodec = await ui.instantiateImageCodec(
        logoData.buffer.asUint8List(),
      );
      final ui.FrameInfo logoFrame = await logoCodec.getNextFrame();
      final ui.Image logo = logoFrame.image;

      final double scale = image.width / 1200;
      final double logoSize = 180 * scale;
      final double margin = 40 * scale;

      final rect = Rect.fromLTWH(margin, margin, logoSize, logoSize);

      canvas.saveLayer(rect, Paint());

      // Circular clip
      canvas.clipPath(Path()..addOval(rect));

      // Fill with white background (optional but often looks better for logos)
      // canvas.drawPaint(Paint()..color = Colors.white);

      // Draw logo (fill the circle)
      final double srcSize = logo.width < logo.height
          ? logo.width.toDouble()
          : logo.height.toDouble();
      final double srcX = (logo.width - srcSize) / 2;
      final double srcY = (logo.height - srcSize) / 2;

      canvas.drawImageRect(
        logo,
        Rect.fromLTWH(srcX, srcY, srcSize, srcSize),
        rect,
        Paint()..filterQuality = ui.FilterQuality.high,
      );

      canvas.restore();
    } catch (_) {}

    int rectHeight = 130;
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        image.height.toDouble() - rectHeight,
        image.width.toDouble(),
        rectHeight.toDouble(),
      ),
      Paint()..color = Colors.black.withOpacity(0.6),
    );

    final address = await _getAddress(position.latitude, position.longitude);
    final dateStr = _formatDateArabic(timestamp);
    final locStr =
        '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
    final fullLocStr = address.isNotEmpty ? '$address | $locStr' : locStr;

    final datePainter = TextPainter(
      text: TextSpan(
        text: dateStr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    datePainter.layout(maxWidth: image.width.toDouble() - 40);

    final locPainter = TextPainter(
      text: TextSpan(
        text: fullLocStr,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 26,
          fontFamily: 'Cairo',
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    locPainter.layout(maxWidth: image.width.toDouble() - 40);

    double dateY =
        image.height.toDouble() - rectHeight + 20; // Plus d'espace en haut
    datePainter.paint(
      canvas,
      Offset(image.width.toDouble() - 20 - datePainter.width, dateY),
    );
    locPainter.paint(
      canvas,
      Offset(
        image.width.toDouble() - 20 - locPainter.width,
        dateY + datePainter.height + 8,
      ),
    ); // Plus d'espace entre les lignes

    final finalImage = await (recorder.endRecording()).toImage(
      image.width,
      image.height,
    );

    // RAM Optimization: Use raw RGBA instead of intermediate PNG encoding
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (byteData == null) throw Exception("Failed to get byte data from image");

    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/final_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // Create img.Image directly from raw bytes (much faster and less RAM than PNG intermediate)
    final decodedImage = img.Image.fromBytes(
      width: finalImage.width,
      height: finalImage.height,
      bytes: byteData.buffer,
      order: img.ChannelOrder.rgba,
    );

    await file.writeAsBytes(img.encodeJpg(decodedImage, quality: 50));

    // Cleanup UI images explicitly to help GC
    image.dispose();
    finalImage.dispose();

    return file;
  }
}
