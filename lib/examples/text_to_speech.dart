import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'TTS Demo', home: MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textFieldController = TextEditingController();
  final AudioPlayer _player = AudioPlayer();
  bool _isLoadingVoice = false;

  @override
  void dispose() {
    _textFieldController.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> playTextToSpeech(String text) async {
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan teks terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoadingVoice = true);

    final apiKey = dotenv.env['EL_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _isLoadingVoice = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API Key tidak ditemukan')));
      return;
    }

    try {
      // Stop any currently playing audio
      await _player.stop();

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
        await _player.setAudioSource(MyCustomSource(response.bodyBytes));
        await _player.play();
      } else {
        throw Exception("Gagal mendapatkan audio: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoadingVoice = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EL TTS Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _textFieldController,
              decoration: const InputDecoration(
                labelText: 'Enter some text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _isLoadingVoice
                  ? null
                  : () => playTextToSpeech(_textFieldController.text),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoadingVoice)
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                  const Icon(Icons.volume_up),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyCustomSource extends StreamAudioSource {
  final List<int> bytes;
  MyCustomSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
