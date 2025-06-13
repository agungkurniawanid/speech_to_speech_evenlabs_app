import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_speech_evenlabs/shared/theme.dart';
import 'package:permission_handler/permission_handler.dart';

final recorderProvider = StateNotifierProvider<RecorderNotifier, RecorderState>(
  (ref) => RecorderNotifier(),
);

class RecorderNotifier extends StateNotifier<RecorderState> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isInitialized = false;
  Timer? _timer;
  double _currentLevel = 0;

  RecorderNotifier() : super(RecorderState(isRecording: false, soundLevel: 0));

  Future<void> init() async {
    try {
      var micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        debugPrint('Microphone permission not granted');
        _isInitialized = false;
        return;
      }

      // (Opsional) Storage permission jika perlu simpan file
      var storageStatus = await Permission.storage.request();
      if (storageStatus != PermissionStatus.granted) {
        debugPrint('Storage permission not granted');
        _isInitialized = false;
        return;
      }

      await _recorder.openRecorder();
      await _recorder.setSubscriptionDuration(const Duration(milliseconds: 50));
      _isInitialized = true;
      debugPrint('Recorder initialized');
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
      _isInitialized = false;
    }
  }

  Future<void> toggleRecording() async {
    if (!_isInitialized) {
      debugPrint('Recorder not initialized');
      return;
    }

    if (state.isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  Future<void> startRecording() async {
    await _recorder.startRecorder(toFile: 'recording.aac');
    state = state.copyWith(isRecording: true);

    _recorder.onProgress!.listen((event) {
      _currentLevel = event.decibels ?? 0;
      state = state.copyWith(soundLevel: _currentLevel);
    });
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    state = state.copyWith(isRecording: false, soundLevel: 0);
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _timer?.cancel();
    super.dispose();
  }
}

class RecorderState {
  final bool isRecording;
  final double soundLevel;

  RecorderState({required this.isRecording, required this.soundLevel});

  RecorderState copyWith({bool? isRecording, double? soundLevel}) {
    return RecorderState(
      isRecording: isRecording ?? this.isRecording,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}

class SpeechPage extends ConsumerStatefulWidget {
  const SpeechPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SpeechPageState();
}

class _SpeechPageState extends ConsumerState<SpeechPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recorderProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final recorderState = ref.watch(recorderProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: blueColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Latihan Wawancara',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.roboto(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: blueColor),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(Icons.android, color: blueColor, size: 50),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rizky Aditya - VP of Engineering',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Posisi Software Engineering',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '00:05:23',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Container dengan animasi voice wave
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: VoiceWaveVisualizer(
                        soundLevel: recorderState.soundLevel,
                        isRecording: recorderState.isRecording,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bagian transkrip tetap sama
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Transkrip Langsung',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Tampilan Lengkap',
                                style: GoogleFonts.roboto(
                                  color: blueColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue.shade50,
                              child: Icon(
                                Icons.android,
                                color: blueColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ceritakan tentang proyek menantang yang pernah kamu kerjakan',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey.shade300,
                              child: Icon(
                                Icons.person,
                                color: blackColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                recorderState.isRecording
                                    ? 'Mendengarkan...'
                                    : 'Di posisi sebelumnya, saya memimpin tim...',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.grey.shade200,
                          child: Icon(
                            recorderState.isRecording
                                ? Icons.mic
                                : Icons.mic_off,
                            color: blueColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(recorderProvider.notifier)
                                .toggleRecording();
                          },
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: recorderState.isRecording
                                ? Colors.redAccent
                                : Colors.grey.shade200,
                            child: Icon(
                              recorderState.isRecording
                                  ? Icons.mic
                                  : Icons.phone_disabled,
                              color: recorderState.isRecording
                                  ? Colors.white
                                  : Colors.black,
                              size: 30,
                            ),
                          ),
                        ),
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: Colors.grey.shade200,
                          child: Icon(Icons.volume_up, color: blueColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VoiceWaveVisualizer extends StatelessWidget {
  final double soundLevel;
  final bool isRecording;

  const VoiceWaveVisualizer({
    super.key,
    required this.soundLevel,
    required this.isRecording,
  });

  @override
  Widget build(BuildContext context) {
    // Normalisasi level suara ke range 0-1 untuk animasi
    final normalizedLevel = isRecording
        ? (soundLevel + 50) /
              50 // Asumsi range decibel -50 sampai 0
        : 0.2; // Nilai default ketika tidak merekam

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildWaveBar(normalizedLevel * 0.8, 0),
          _buildWaveBar(normalizedLevel * 1.2, 100),
          _buildWaveBar(normalizedLevel * 1.0, 200),
          _buildWaveBar(normalizedLevel * 1.4, 300),
          _buildWaveBar(normalizedLevel * 0.6, 400),
          _buildWaveBar(normalizedLevel * 1.1, 500),
          _buildWaveBar(normalizedLevel * 0.9, 600),
        ],
      ),
    );
  }

  Widget _buildWaveBar(double height, int delay) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100 + delay),
        curve: Curves.easeOut,
        width: 6,
        height: height.clamp(10, 40).toDouble(),
        decoration: BoxDecoration(
          color: blueColor,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}
