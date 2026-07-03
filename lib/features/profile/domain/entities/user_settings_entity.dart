import 'package:equatable/equatable.dart';

/// Entity representing user settings in the domain layer.
class UserSettingsEntity extends Equatable {
  final String language;
  final String streamingQuality;
  final String downloadQuality;
  final bool autoPlay;
  final bool showLyrics;
  final String equalizerPreset;

  const UserSettingsEntity({
    this.language = 'en',
    this.streamingQuality = 'high',
    this.downloadQuality = 'high',
    this.autoPlay = true,
    this.showLyrics = false,
    this.equalizerPreset = 'flat',
  });

  // --- Lógica de Dominio Empresarial (Rich Model) ---

  /// Verifica si la configuración demanda streaming de máxima fidelidad
  bool get demandsHighQualityStreaming => streamingQuality.toLowerCase() == 'high';

  /// Verifica si las descargas deben ser de máxima fidelidad
  bool get demandsHighQualityDownload => downloadQuality.toLowerCase() == 'high';

  /// Indica si hay un ecualizador personalizado (distinto al flat)
  bool get hasCustomEqualizer => equalizerPreset.toLowerCase() != 'flat';



  UserSettingsEntity copyWith({
    String? language,
    String? streamingQuality,
    String? downloadQuality,
    bool? autoPlay,
    bool? showLyrics,
    String? equalizerPreset,
  }) {
    return UserSettingsEntity(
      language: language ?? this.language,
      streamingQuality: streamingQuality ?? this.streamingQuality,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      autoPlay: autoPlay ?? this.autoPlay,
      showLyrics: showLyrics ?? this.showLyrics,
      equalizerPreset: equalizerPreset ?? this.equalizerPreset,
    );
  }

  @override
  List<Object?> get props => [
    language,
    streamingQuality,
    downloadQuality,
    autoPlay,
    showLyrics,
    equalizerPreset,
  ];
}
