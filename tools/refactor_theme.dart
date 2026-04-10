import 'dart:io';

void main() {
  final dir = Directory('C:\\src\\nour\\lib');
  final files = dir.listSync(recursive: true).whereType<File>().toList();
  for (var file in files) {
    if (file.path.endsWith('.dart') &&
        !file.path.endsWith('theme.dart') &&
        !file.path.endsWith('app_colors.dart') &&
        !file.path.endsWith('main.dart') &&
        !file.path.endsWith('theme_provider.dart')) {
      var content = file.readAsStringSync();
      var changed = false;
      content = content.replaceAllMapped(
        RegExp(r'AppTheme\.([a-z][a-zA-Z0-9_]*)'),
        (match) {
          changed = true;
          return 'context.appColors.${match.group(1)}';
        },
      );
      if (changed) {
        file.writeAsStringSync(content);
      }
    }
  }
}
