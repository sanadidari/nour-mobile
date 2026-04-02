import 'dart:io';

void main() {
  final file = File('analyze.txt');
  if (!file.existsSync()) return;
  final bytes = file.readAsBytesSync();
  String text = String.fromCharCodes(bytes).replaceAll('\x00', '');
  final lines = text.split('\n');
  
  Map<String, Set<int>> constLinesToFix = {};
  
  for (var line in lines) {
    if (line.contains('INVALID_CONSTANT')) {
      var parts = line.split('|');
      if (parts.length > 5) {
        var filePath = parts[3];
        var lineNum = int.parse(parts[4]);
        constLinesToFix.putIfAbsent(filePath, () => {}).add(lineNum);
      }
    }
  }
  
  for (var entry in constLinesToFix.entries) {
    var filePath = entry.key;
    var file = File(filePath);
    if (!file.existsSync()) continue;
    
    var fileLines = file.readAsLinesSync();
    
    // Sort lines in descending order to avoid messing up line numbers if we were inserting, 
    // although we are just modifying in place.
    var sortedLines = entry.value.toList()..sort((a,b) => b.compareTo(a));
    
    for (var lineNum in sortedLines) {
      if (lineNum <= fileLines.length) {
         var idx = lineNum - 1;
         for (int i = 0; i < 5 && idx - i >= 0; i++) {
            var targetLine = fileLines[idx - i];
            
            // Only replace if 'const ' exists and doesn't look like part of another word
            if (RegExp(r'\bconst\s+').hasMatch(targetLine)) {
               fileLines[idx - i] = targetLine.replaceFirst(RegExp(r'\bconst\s+'), '');
               break;
            }
         }
      }
    }
    file.writeAsStringSync(fileLines.join('\n') + '\n');
  }
  print("Fixed ${constLinesToFix.length} files");
}
