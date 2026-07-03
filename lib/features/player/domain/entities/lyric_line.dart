/// Modelo para una línea de lyrics con timestamp
class LyricLine {
  final Duration timestamp;
  final String text;
  final int index;

  const LyricLine({
    required this.timestamp,
    required this.text,
    required this.index,
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si la línea lírica es únicamente un salto de formato o un separador visual
  bool get isBlank => text.trim().isEmpty;

  /// Parsea lyrics con timestamps del formato: [MM:SS.xx]texto
  static List<LyricLine> parseLyrics(
    String? lyrics, {
    bool hasTimestamps = true,
  }) {
    if (lyrics == null || lyrics.isEmpty) return [];

    final lines = <LyricLine>[];

    if (!hasTimestamps) {
      // Sin timestamps - crear líneas sin tiempo
      final rawLines = lyrics.split('\n');
      for (int i = 0; i < rawLines.length; i++) {
        final text = rawLines[i].trim();
        if (text.isNotEmpty) {
          lines.add(LyricLine(timestamp: Duration.zero, text: text, index: i));
        }
      }
      return lines;
    }

    // Regex para parsear timestamps: [MM:SS.xx] o [MM:SS]
    final regex = RegExp(r'\[(\d{1,2}):(\d{2})(?:\.(\d{2,3}))?\](.*)');

    final rawLines = lyrics.split('\n');
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      final match = regex.firstMatch(line);

      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisStr = match.group(3);
        final millis = millisStr != null
            ? int.parse(millisStr.padRight(3, '0').substring(0, 3))
            : 0;

        final timestamp = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );

        final text = match.group(4)?.trim() ?? '';

        if (text.isNotEmpty) {
          lines.add(
            LyricLine(timestamp: timestamp, text: text, index: lines.length),
          );
        }
      }
    }

    return lines;
  }

  /// Obtiene el índice de la línea actual basándose en la posición de reproducción
  static int getCurrentLineIndex(List<LyricLine> lines, Duration position) {
    if (lines.isEmpty) return -1;

    for (int i = lines.length - 1; i >= 0; i--) {
      if (position >= lines[i].timestamp) {
        return i;
      }
    }
    return -1;
  }
}
