// Mentesana — on-device voice transcription.
//
// Records a voice note locally (16kHz mono WAV, the format whisper.cpp
// wants) and transcribes it fully on-device via whisper_ggml, a Flutter
// wrapper around whisper.cpp. No audio and no transcript text is ever
// sent off the device — this mirrors the app's core promise ("this page
// never leaves your device") for the voice path too.
//
// Record-first, not live: the recording is transcribed only after it
// stops. See the Feature & Design Research page for why — reflective
// speech is full of pauses a live transcript would stumble over, and a
// finished clip gives whisper more context to work with than streaming
// chunks would.
//
// Model handling: whisper_ggml downloads the chosen ggml model once (like
// any one-time app asset) and caches it on-device; every transcription
// after that first download is fully offline. To ship fully offline from
// install instead, bundle the same ggml file under assets/models/ and
// point the package at it per its README.
//
// NOTE: verified against the whisper_ggml 2.4.0 README's own quick-start
// snippet (pub.dev/packages/whisper_ggml): WhisperController().transcribe
// (model:, audioPath:, lang:) returns a *nullable result object*, with
// the transcript text at result.transcription.text — not a flat String.
// downloadModel(model) primes the on-device model before first use. This
// file has not been compiled or run inside an actual Flutter project —
// re-check against whichever version `flutter pub add whisper_ggml`
// resolves to before shipping, in case the API has shifted again since.

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:whisper_ggml/whisper_ggml.dart'
    if (dart.library.html) 'whisper_stub.dart';

/// Which ggml model to transcribe with. `balanced` (the `base` model) is
/// the default: small enough to download quickly and accurate enough for
/// reflective journaling speech. `accurate` trades a larger download for
/// better results on accented or noisy audio; `fast` is the smallest and
/// quickest, best for a low-power device or a first try.
enum VoiceModelQuality { fast, balanced, accurate }

extension on VoiceModelQuality {
  WhisperModel get ggmlModel => switch (this) {
        VoiceModelQuality.fast => WhisperModel.tiny,
        VoiceModelQuality.balanced => WhisperModel.base,
        VoiceModelQuality.accurate => WhisperModel.small,
      };
}

/// Thrown when the microphone permission is denied.
class MicPermissionDenied implements Exception {}

/// The outcome of one recorded-and-transcribed voice note.
class VoiceNoteResult {
  VoiceNoteResult({required this.transcript, required this.audioPath});

  final String transcript;
  final String audioPath;
}

/// Transcribes an already-recorded audio file, fully on-device via
/// whisper_ggml. Holds no microphone/recording state at all, so a single
/// instance can safely outlive any one editor screen — AppStore keeps one
/// of these around to finish a transcription in the background after its
/// journal entry has already been kept and the editor has closed.
class WhisperTranscriber {
  WhisperTranscriber({this.quality = VoiceModelQuality.balanced});

  final VoiceModelQuality quality;
  final WhisperController _whisper = WhisperController();
  bool _modelReady = false;

  /// Downloads the ggml model on first use — one-time, then cached.
  ///
  /// NOTE: verified against the whisper_ggml 2.4.0 README's own
  /// quick-start snippet (pub.dev/packages/whisper_ggml):
  /// WhisperController().transcribe(model:, audioPath:, lang:) returns a
  /// *nullable result object*, with the transcript text at
  /// result.transcription.text — not a flat String. This file has not
  /// been compiled or run inside an actual Flutter project — re-check
  /// against whichever version `flutter pub add whisper_ggml` resolves
  /// to before shipping, in case the API has shifted again since.
  Future<String> transcribe(String audioPath,
      {String language = 'auto'}) async {
    if (!_modelReady) {
      await _whisper.downloadModel(quality.ggmlModel);
      _modelReady = true;
    }
    final result = await _whisper.transcribe(
      model: quality.ggmlModel,
      audioPath: audioPath,
      lang: language,
    );
    return (result?.transcription.text ?? '').trim();
  }
}

/// Records a voice note to a local file, then transcribes it on-device.
/// Create one instance per journal editor session and call [dispose] when
/// the editor closes.
///
/// Recording is intentionally scoped to the editor's lifetime — closing
/// the editor mid-recording releases the mic (see JournalEditor.dispose).
/// Transcription itself does not have to be: [transcribe] only touches
/// the underlying [WhisperTranscriber], which keeps working even after
/// this service's [dispose] has released the recorder, so a call already
/// in flight when the editor closes still finishes normally. The editor
/// hands that finished (or still-running) transcription off to
/// AppStore.transcribeInBackground so the page can be kept immediately
/// instead of waiting on it.
class VoiceTranscriptionService {
  VoiceTranscriptionService(
      {VoiceModelQuality quality = VoiceModelQuality.balanced})
      : _transcriber = WhisperTranscriber(quality: quality);

  final AudioRecorder _recorder = AudioRecorder();
  final WhisperTranscriber _transcriber;

  /// Starts recording to a fresh temp file. Throws [MicPermissionDenied]
  /// if the user has declined microphone access.
  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      throw MicPermissionDenied();
    }
    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/mentesana-voice-${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
  }

  /// True while a recording is in progress.
  Future<bool> isRecording() => _recorder.isRecording();

  /// Stops recording and returns the local audio file path, or null if
  /// nothing was recorded (e.g. stopped immediately after starting).
  Future<String?> stopRecording() => _recorder.stop();

  /// Transcribes an already-recorded audio file, fully on-device.
  Future<String> transcribe(String audioPath, {String language = 'auto'}) =>
      _transcriber.transcribe(audioPath, language: language);

  /// Records, then immediately transcribes on stop — the app's "record
  /// first" flow. Returns null if nothing was recorded. Kept for a
  /// simple, fully-blocking single-shot use; the editor itself now calls
  /// [stopRecording] + [transcribe] separately so it can hand the
  /// transcription off to run in the background instead of awaiting it
  /// here.
  Future<VoiceNoteResult?> stopAndTranscribe({String language = 'auto'}) async {
    final path = await stopRecording();
    if (path == null) return null;
    final transcript = await transcribe(path, language: language);
    return VoiceNoteResult(transcript: transcript, audioPath: path);
  }

  Future<void> dispose() => _recorder.dispose();
}
