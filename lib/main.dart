import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_speech_evenlabs/pages/main/home_page.dart';
import 'package:speech_to_speech_evenlabs/pages/speech/speech_page.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Convertation AI',
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
