import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons/lucide_icons.dart';

/// Retourne l'icône correspondant au type d'intervention.
/// Utilisé dans le Dashboard, l'Historique et le Détail Opération.
IconData getIconForType(String type) {
  if (type.contains('إثبات')) return LucideIcons.scan;
  if (type.contains('امتناع')) return LucideIcons.ban;
  if (type.contains('تبليغ')) return LucideIcons.mail;
  if (type.contains('تعذر')) return LucideIcons.alertTriangle;
  if (type.contains('تسليم')) return LucideIcons.hand;
  if (type.contains('رفض')) return LucideIcons.userX;
  if (type.contains('غياب')) return LucideIcons.doorClosed;
  if (type.contains('تصريح')) return LucideIcons.messageSquare;
  if (type.contains('قضائي')) return LucideIcons.gavel;
  return LucideIcons.fileText;
}

/// Formate une date en arabe avec chiffres latins.
String formatDateArabic(DateTime dt) {
  String text = DateFormat('EEEE dd MMMM yyyy - HH:mm:ss', 'ar').format(dt);
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (int i = 0; i < 10; i++) {
    text = text.replaceAll(arabicDigits[i], i.toString());
  }
  return text;
}

/// Extrait le numéro de dossier depuis le champ notes legacy.
String extractDossierFromNotes(String notes) {
  final match = RegExp(r'Dossier:\s*([^\|]+)').firstMatch(notes);
  return match?.group(1)?.trim() ?? 'غير محدد';
}

/// Extrait le type d'intervention depuis le champ notes legacy.
String extractTypeFromNotes(String notes) {
  final match = RegExp(r'Type:\s*([^\|]+)').firstMatch(notes);
  return match?.group(1)?.trim() ?? '';
}

/// Extrait les coordonnées GPS depuis le champ notes legacy.
String extractGpsFromNotes(String notes) {
  final match = RegExp(r'GPS:\s*([^\|]+)').firstMatch(notes);
  return match?.group(1)?.trim() ?? '';
}

/// Copie du texte dans le presse-papiers avec un SnackBar de confirmation.
void copyToClipboard(BuildContext context, String text, String label) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('تم نسخ $label بنجاح'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Vérifie si un record d'historique possède des coordonnées GPS valides.
bool hasValidGps(Map<String, dynamic> item) {
  final lat = item['latitude'];
  final lon = item['longitude'];
  if (lat != null && lon != null && (lat != 0 || lon != 0)) return true;
  final notes = item['notes'] ?? '';
  return notes.toString().contains('GPS:');
}

/// Applique la logique de filtrage partagée entre Dashboard et History.
List<Map<String, dynamic>> applyDossierFilters({
  required List<Map<String, dynamic>> source,
  required String dossier,
  required String type,
  required String demandeur,
  required String demande,
  required String ville,
  required String zone,
}) {
  if (dossier.isEmpty &&
      type.isEmpty &&
      demandeur.isEmpty &&
      demande.isEmpty &&
      ville.isEmpty &&
      zone.isEmpty) {
    return source;
  }

  return source.where((item) {
    final dId = (item['dossier_id']?.toString() ?? '');
    final iType = (item['intervention_type']?.toString() ?? '');
    final notes = (item['notes']?.toString() ?? '');
    final form = (item['formFields'] as Map<dynamic, dynamic>?) ?? {};

    bool matches = true;
    if (dossier.isNotEmpty && !dId.contains(dossier)) matches = false;
    if (type.isNotEmpty && !iType.contains(type) && !notes.contains(type))
      matches = false;
    if (demandeur.isNotEmpty && !notes.contains(demandeur)) matches = false;
    if (demande.isNotEmpty && !notes.contains(demande)) matches = false;

    final itemVille = (form['المدينة'] ?? form['العمالة / الإقليم'] ?? '')
        .toString();
    final itemZone = (form['المنطقة / الحي'] ?? form['الجماعة / المدينة'] ?? '')
        .toString();

    if (ville.isNotEmpty) {
      bool match = false;
      if (itemVille.isNotEmpty && itemVille.contains(ville)) match = true;
      if (notes.contains('المدينة: $ville') ||
          notes.contains('العمالة / الإقليم: $ville'))
        match = true;
      if (!match) matches = false;
    }

    if (zone.isNotEmpty) {
      bool match = false;
      if (itemZone.isNotEmpty && itemZone.contains(zone)) match = true;
      if (notes.contains('المنطقة / الحي: $zone') ||
          notes.contains('الجماعة / المدينة: $zone'))
        match = true;
      if (!match) matches = false;
    }

    return matches;
  }).toList();
}
