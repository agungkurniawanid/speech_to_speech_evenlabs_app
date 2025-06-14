import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_speech_evenlabs/pages/navigation/bottom_bar.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

Future main() async {
  // WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  // runApp(MyApp());
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'VoiceMentor',
      debugShowCheckedModeBanner: false,
      home: BottomBar(),
    );
  }
}

// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Voice Gemini TTS Demo',
//       theme: ThemeData(primarySwatch: Colors.blue),
//       home: MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final TextEditingController _textFieldController = TextEditingController();
//   final TextEditingController _responseController = TextEditingController();
//   final AudioPlayer _player = AudioPlayer();

//   // STT Variables
//   late stt.SpeechToText _speech;
//   bool _isListening = false;
//   String _sttResult = '';
//   bool _speechAvailable = false;
//   bool _isLoading = false; // loading indikator untuk proses Gemini/TTS
//   bool _started = false;

//   @override
//   void initState() {
//     super.initState();
//     _speech = stt.SpeechToText();
//     _initSpeech();
//   }

//   Future<void> _startListeningManually() async {
//     var status = await Permission.microphone.status;
//     if (!status.isGranted) {
//       status = await Permission.microphone.request();
//       if (!status.isGranted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Izin microphone diperlukan')),
//         );
//         return;
//       }
//     }

//     if (!_speechAvailable) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Speech recognition belum siap')),
//       );
//       return;
//     }

//     setState(() => _started = true);
//     startListeningLoop();
//   }

//   @override
//   void dispose() {
//     _textFieldController.dispose();
//     _responseController.dispose();
//     _player.dispose();
//     _speech.stop();
//     super.dispose();
//   }

//   void startListeningLoop() async {
//     if (!_speechAvailable || _isListening) return;

//     setState(() => _isListening = true);
//     await _speech.listen(
//       onResult: (result) async {
//         if (result.finalResult && result.recognizedWords.isNotEmpty) {
//           String recognizedText = result.recognizedWords;
//           setState(() {
//             _isListening = false;
//             _sttResult = recognizedText;
//             _textFieldController.text = recognizedText;
//           });

//           await _speech.stop();
//           await processSpeechToGeminiAndTTS(recognizedText);

//           await Future.delayed(Duration(milliseconds: 400));
//           startListeningLoop();
//         }
//       },
//       localeId: 'id_ID',
//       listenMode: stt.ListenMode.dictation,
//       cancelOnError: true,
//       partialResults: true,
//     );
//   }

//   // Inisialisasi STT
//   Future<void> _initSpeech() async {
//     try {
//       bool available = await _speech.initialize(
//         onStatus: (status) => print('STT Status: $status'),
//         onError: (error) => print('STT Error: $error'),
//       );
//       setState(() {
//         _speechAvailable = available;
//         if (!available) {
//           _textFieldController.text = "Periksa izin microphone dan coba lagi";
//         }
//       });
//     } catch (e) {
//       print('Error inisialisasi STT: $e');
//       setState(() => _speechAvailable = false);
//     }
//   }

//   // Start/Stop listening
//   // void _toggleListening() async {
//   //   var status = await Permission.microphone.status;
//   //   if (!status.isGranted) {
//   //     status = await Permission.microphone.request();
//   //     if (status != PermissionStatus.granted) {
//   //       ScaffoldMessenger.of(
//   //         context,
//   //       ).showSnackBar(SnackBar(content: Text('Izin microphone diperlukan')));
//   //       return;
//   //     }
//   //     await _initSpeech();
//   //   }

//   //   if (!_speechAvailable) {
//   //     ScaffoldMessenger.of(
//   //       context,
//   //     ).showSnackBar(SnackBar(content: Text('Speech recognition belum siap')));
//   //     return;
//   //   }

//   //   if (_isListening) {
//   //     await _speech.stop();
//   //     setState(() => _isListening = false);
//   //   } else {
//   //     setState(() => _isListening = true);
//   //     _speech.listen(
//   //       onResult: (result) async {
//   //         setState(() {
//   //           _sttResult = result.recognizedWords;
//   //           _textFieldController.text = _sttResult;
//   //         });

//   //         // Deteksi jika hasil sudah final dan tidak kosong (user berhenti bicara)
//   //         if (result.finalResult && _sttResult.isNotEmpty) {
//   //           setState(() => _isListening = false);
//   //           await _speech.stop();
//   //           await processSpeechToGeminiAndTTS(_sttResult);
//   //         }
//   //       },
//   //       localeId: 'id_ID', // Ganti ke 'en_US' kalau mau Bahasa Inggris
//   //       listenMode: stt.ListenMode.dictation,
//   //       cancelOnError: true,
//   //       partialResults: true,
//   //     );
//   //   }
//   // }

//   // Step utama: kirim ke Gemini, lalu ke ElevenLabs TTS
//   Future<void> processSpeechToGeminiAndTTS(String userText) async {
//     setState(() {
//       _isLoading = true;
//       _responseController.text = '';
//     });
//     try {
//       String geminiResponse = await fetchGeminiResponse(userText);
//       setState(() {
//         _responseController.text = geminiResponse;
//       });
//       await playTextToSpeech(geminiResponse);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
//     } finally {
//       await Future.delayed(const Duration(milliseconds: 500));
//       setState(() => _isLoading = false);
//     }
//   }

//   // Call Gemini API
//   Future<String> fetchGeminiResponse(String prompt) async {
//     final apiKey = dotenv.env['GEMINI_API_KEY'];
//     if (apiKey == null || apiKey.isEmpty) {
//       throw Exception('GEMINI_API_KEY tidak ditemukan di .env');
//     }
//     final url =
//         'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';

//     final response = await http.post(
//       Uri.parse(url),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         "contents": [
//           {
//             "parts": [
//               {"text": prompt},
//             ],
//           },
//         ],
//       }),
//     );

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       try {
//         return data['candidates'][0]['content']['parts'][0]['text'] ?? '';
//       } catch (e) {
//         throw Exception('Format jawaban Gemini tidak cocok: ${response.body}');
//       }
//     } else {
//       throw Exception("Gemini API error: ${response.body}");
//     }
//   }

//   // TTS ElevenLabs
//   Future<void> playTextToSpeech(String text) async {
//     if (text.isEmpty) return;

//     final apiKey = dotenv.env['EL_API_KEY'];
//     if (apiKey == null || apiKey.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('API Key ElevenLabs tidak ditemukan')),
//       );
//       return;
//     }

//     try {
//       await _player.stop();
//       final response = await http
//           .post(
//             Uri.parse(
//               'https://api.elevenlabs.io/v1/text-to-speech/21m00Tcm4TlvDq8ikWAM',
//             ),
//             headers: {
//               'accept': 'audio/mpeg',
//               'xi-api-key': apiKey,
//               'Content-Type': 'application/json',
//             },
//             body: json.encode({
//               "text": text,
//               "model_id": "eleven_monolingual_v1",
//               "voice_settings": {"stability": .15, "similarity_boost": .75},
//             }),
//           )
//           .timeout(const Duration(seconds: 15));

//       if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
//         await _player.setAudioSource(MyCustomSource(response.bodyBytes));
//         await _player.play();
//       } else {
//         throw Exception("Gagal mendapatkan audio: ${response.statusCode}");
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Gagal memutar suara, silakan coba lagi')),
//       );

//       debugPrint('TTS error: $e');
//       setState(() {
//         _isLoading = false;
//         _isListening = false;
//         _started = false;
//         _sttResult = '';
//         _textFieldController.clear();
//         _responseController.clear();
//       });

//       try {
//         await _speech.stop();
//         await _player.stop();
//       } catch (_) {}
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Voice Gemini TTS Demo')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: <Widget>[
//             TextField(
//               controller: _textFieldController,
//               decoration: const InputDecoration(
//                 labelText: 'Teks dari ucapan kamu',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 2,
//               minLines: 1,
//               readOnly: true,
//             ),
//             const SizedBox(height: 12.0),
//             // if (_isLoading)
//             //   const Center(
//             //     child: Padding(
//             //       padding: EdgeInsets.all(8.0),
//             //       child: CircularProgressIndicator(),
//             //     ),
//             //   ),
//             TextField(
//               controller: _responseController,
//               decoration: const InputDecoration(
//                 labelText: 'Jawaban Gemini',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 4,
//               minLines: 1,
//               readOnly: true,
//             ),
//             const SizedBox(height: 16.0),
//             if (_started)
//               AnimatedSwitcher(
//                 duration: const Duration(milliseconds: 400),
//                 transitionBuilder: (child, animation) {
//                   return ScaleTransition(scale: animation, child: child);
//                 },
//                 child: _isLoading
//                     ?
//                       //  const Text(
//                       //     'Jawab...',
//                       //     key: ValueKey('listening'),
//                       //     style: TextStyle(color: Colors.red),
//                       //     textAlign: TextAlign.center,
//                       //   )
//                       Image.asset(
//                         'assets/gif/loads/ai_load.gif',
//                         key: const ValueKey('gif'),
//                         height: 80,
//                       )
//                     : _isListening
//                     ? const Text(
//                         'Mendengarkan...',
//                         key: ValueKey('listening'),
//                         style: TextStyle(color: Colors.red),
//                         textAlign: TextAlign.center,
//                       )
//                     : const SizedBox(key: ValueKey('empty')),
//               ),

//             if (!_speechAvailable)
//               const Padding(
//                 padding: EdgeInsets.only(top: 16.0),
//                 child: Text(
//                   'Speech recognition tidak tersedia',
//                   style: TextStyle(color: Colors.red),
//                   textAlign: TextAlign.center,
//                 ),
//               ),

//             if (!_started) SizedBox(height: 24),
//             if (!_started)
//               Center(
//                 child: InkWell(
//                   onTap: _startListeningManually,
//                   borderRadius: BorderRadius.circular(50),
//                   child: Container(
//                     padding: EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.blue,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.play_arrow,
//                       size: 40,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // Helper untuk audio stream ElevenLabs
// class MyCustomSource extends StreamAudioSource {
//   final List<int> bytes;
//   MyCustomSource(this.bytes);

//   @override
//   Future<StreamAudioResponse> request([int? start, int? end]) async {
//     start ??= 0;
//     end ??= bytes.length;
//     return StreamAudioResponse(
//       sourceLength: bytes.length,
//       contentLength: end - start,
//       offset: start,
//       stream: Stream.value(bytes.sublist(start, end)),
//       contentType: 'audio/mpeg',
//     );
//   }
// }
