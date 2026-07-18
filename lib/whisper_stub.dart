// Mentesana — Web stub for whisper_ggml

class WhisperTranscription {
  final String text;
  WhisperTranscription(this.text);
}

class WhisperResult {
  final WhisperTranscription transcription;
  WhisperResult(this.transcription);
}

class WhisperController {
  Future<void> downloadModel(dynamic model) async {}
  Future<WhisperResult?> transcribe({
    dynamic model,
    required String audioPath,
    required String lang,
  }) async {
    return WhisperResult(WhisperTranscription("Voice transcription is not supported on Web."));
  }
}

enum WhisperModel { tiny, base, small }
