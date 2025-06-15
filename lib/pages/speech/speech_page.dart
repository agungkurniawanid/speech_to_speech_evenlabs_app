import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_speech_evenlabs/services/elevenLabsSource.dart';
import 'package:speech_to_speech_evenlabs/shared/theme.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(recorderProvider.notifier).init();
    // });
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Timer? _elapsedTimeTimer;
  int _elapsedSeconds = 0;
  Timer? _typingTimer;
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _requestController = TextEditingController();
  final TextEditingController _responseController = TextEditingController();
  final AudioPlayer _player = AudioPlayer();

  // STT Variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _sttResult = '';
  bool _speechAvailable = false;
  bool _isLoading = false;
  bool _started = false;
  bool _isMicrophoneActive = true;
  bool _isLoudspeakerActive = true;
  void _toggleMicrophone() {
    if (_isMicrophoneActive) {
      ref.read(recorderProvider.notifier).stopRecording();
      setState(() {
        _isMicrophoneActive = false;
      });
    } else {
      ref.read(recorderProvider.notifier).startRecording();
      setState(() {
        _isMicrophoneActive = true;
      });
    }
  }

  void _toggleLoudspeaker() {
    if (_isLoudspeakerActive) {
      _player.stop();
      setState(() {
        _isLoudspeakerActive = false;
      });
    } else {
      if (_responseController.text.isNotEmpty) {
        playTextToSpeech(_responseController.text);
        setState(() {
          _isLoudspeakerActive = true;
        });
      }
    }
  }

  void _simulateTyping(String text, TextEditingController controller) {
    controller.clear();
    int charIndex = 0;

    _typingTimer?.cancel();

    _typingTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (charIndex < text.length) {
        controller.text += text[charIndex];
        charIndex++;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _sttResult = '';
        _requestController.clear();
        _responseController.clear();
        _elapsedSeconds = 0;
      });
    }
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => print('STT Status: $status'),
        onError: (error) => print('STT Error: $error'),
      );
      setState(() {
        _speechAvailable = available;
        if (!available) {
          _requestController.text = "Periksa izin microphone dan coba lagi";
        }
      });
    } catch (e) {
      print('Error inisialisasi STT: $e');
      setState(() => _speechAvailable = false);
    }
  }

  Future<void> _startListeningManually() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin microphone diperlukan')),
        );
        return;
      }
    }

    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition belum siap')),
      );
      return;
    }

    setState(() => _started = true);
    startListeningLoop();
  }

  void startListeningLoop() async {
    if (!_speechAvailable || _isListening) return;

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) async {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          String recognizedText = result.recognizedWords;
          setState(() {
            _isListening = false;
            _sttResult = recognizedText;
            _requestController.text = recognizedText;
          });

          await _speech.stop();
          await processSpeechToGeminiAndTTS(recognizedText);

          await Future.delayed(Duration(milliseconds: 50));
          startListeningLoop();
        }
      },
      localeId: 'id_ID',
      listenMode: stt.ListenMode.dictation,
      cancelOnError: true,
      partialResults: true,
    );
  }

  Future<void> processSpeechToGeminiAndTTS(String userText) async {
    setState(() {
      _isLoading = true;
      _responseController.text = '';
    });
    try {
      String geminiResponse = await fetchGeminiResponse(userText);
      String cleanedResponse = geminiResponse.replaceAll('*', '');
      _simulateTyping(cleanedResponse, _responseController);
      await playTextToSpeech(cleanedResponse);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _isLoading = false);
    }
  }

  Future<String> fetchGeminiResponse(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY tidak ditemukan di .env');
    }
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';

    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {"text": prompt},
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      try {
        return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
      } catch (e) {
        throw Exception('Format jawaban Gemini tidak cocok: ${response.body}');
      }
    } else {
      throw Exception("Gemini API error: ${response.body}");
    }
  }

  Future<void> playTextToSpeech(String text) async {
    if (text.isEmpty) return;

    final apiKey = dotenv.env['EL_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key ElevenLabs tidak ditemukan')),
      );
      return;
    }

    try {
      // Stop player jika sedang memainkan audio
      if (_player.playing) {
        await _player.stop();
      }

      // Kirim request ke ElevenLabs
      final response = await http
          .post(
            Uri.parse(
              'https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM',
            ),
            headers: {
              'accept': 'audio/mpeg',
              'xi-api-key': apiKey,
              'Content-Type': 'application/json',
            },
            body: json.encode({
              "text": text,
              "model_id": "eleven_monolingual_v1",
              "voice_settings": {"stability": .15, "similarity_boost": .75},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await _player.setAudioSource(ElevenLabsSource(response.bodyBytes));
        await _player.play();

        // Tunggu hingga selesai diputar
        await _player.processingStateStream.firstWhere(
          (state) => state == ProcessingState.completed,
          orElse: () => ProcessingState.completed,
        );
      } else {
        try {
          final body = jsonDecode(response.body);
          final detail = body['detail'];
          throw Exception("(${detail['status']}) ${detail['message']}");
        } catch (_) {
          throw Exception("Gagal mendapatkan audio: ${response.body}");
        }
      }
    } catch (e) {
      debugPrint('TTS error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memutar suara: ${e.toString()}')),
      );

      // Reset UI state (jika perlu)
      setState(() {
        _isLoading = false;
        _isListening = false;
        _started = false;
        _sttResult = '';
        _requestController.clear();
        _responseController.clear();
      });

      try {
        await _speech.stop();
        if (_player.playing) await _player.stop();
      } catch (_) {}
    }
  }

  void _startTimer() {
    _elapsedSeconds = 0;
    _elapsedTimeTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimeTimer?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _stopTimer() {
    _elapsedTimeTimer?.cancel();
    _elapsedSeconds = 0;
  }

  void _toggleActive() {
    setState(() {
      _started = !_started;
    });

    if (_started) {
      // ref.read(recorderProvider.notifier).startRecording();
      _startListeningManually();
      _startTimer();
    } else {
      // ref.read(recorderProvider.notifier).stopRecording();
      _stopListening();
      _stopTimer();
    }
  }

  String get elapsedTime {
    final hours = (_elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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
                mainAxisAlignment: MainAxisAlignment.end,
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
                        '${elapsedTime}',
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
                      child:
                          // VoiceWaveVisualizer(
                          //   soundLevel: recorderState.soundLevel,
                          //   isRecording: recorderState.isRecording,
                          // ),
                          //  if (_started)
                          _started
                          ? AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: _isLoading
                                  ?
                                    //  const Text(
                                    //     'Jawab...',
                                    //     key: ValueKey('listening'),
                                    //     style: TextStyle(color: Colors.red),
                                    //     textAlign: TextAlign.center,
                                    //   )
                                    Image.asset(
                                      'assets/gif/loads/voice_process.gif',
                                      key: const ValueKey('gif'),
                                      height: 80,
                                    )
                                  : _isListening
                                  ? const Text(
                                      'Mendengarkan...',
                                      key: ValueKey('listening'),
                                      style: TextStyle(
                                        color: Color(0xFF355DEB),
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  : const SizedBox(key: ValueKey('empty')),
                            )
                          : SizedBox(),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Bagian transkrip tetap sama
                  _started
                      ? Expanded(
                          child: Container(
                            // color: redColor,
                            // height: MediaQuery.of(context).size.height / 3,
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: SingleChildScrollView(
                              controller: _scrollController,
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
                                  if (_requestController.text.isNotEmpty)
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
                                            _requestController.text,
                                            style: GoogleFonts.roboto(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 8),
                                  if (_responseController.text.isNotEmpty)
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
                                            _responseController.text,
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
                          ),
                        )
                      : Container(
                          height: MediaQuery.of(context).size.height * 0.1,
                          margin: EdgeInsets.only(
                            bottom: MediaQuery.of(context).size.height * 0.025,
                          ),
                          child: Center(
                            child: Text(
                              'Tekan tombol dibawah ini untuk memulai',
                            ),
                          ),
                        ),
                  // const Spacer(),
                  if (!_started)
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 48,
                      right: 48,

                      bottom: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _toggleMicrophone,
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(
                              _isMicrophoneActive ? Icons.mic : Icons.mic_off,
                              color: darkGreyColor,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // ref
                            //     .read(recorderProvider.notifier)
                            //     .toggleRecording();
                            _toggleActive();
                          },
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: _started
                                ? lightRedColor
                                : lightBlueColor,
                            child: Icon(
                              _started ? Icons.call_end : Icons.call,
                              color: _started ? redColor : blueColor,
                              size: 30,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleLoudspeaker,
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.grey.shade200,
                            child: Icon(
                              _isLoudspeakerActive
                                  ? Icons.volume_up
                                  : Icons.volume_off,
                              color: darkGreyColor,
                            ),
                          ),
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
