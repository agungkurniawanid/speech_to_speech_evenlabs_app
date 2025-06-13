import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_speech_evenlabs/pages/detail/detail_train_page.dart';
import 'package:speech_to_speech_evenlabs/shared/theme.dart';

final counterProvider = StateProvider<int>((ref) => 0);

class HomePage extends ConsumerWidget {
  HomePage({super.key});

  final List<Map<String, dynamic>> trainVariants = [
    {
      'title': 'Wawancara Kerja',
      'subtitle': 'Latihan pertanyaan wawancara umum',
      'icon': Icons.work_outline,
    },
    {
      'title': 'Keterampilan Presentasi',
      'subtitle': 'Tingkatkan kemampuan berbicara di depan umum',
      'icon': Icons.present_to_all_outlined,
    },
    {
      'title': 'Latihan Percakapan',
      'subtitle': 'Kuasai interaksi sehari-hari',
      'icon': Icons.chat_bubble_outline,
    },
  ];

  final List<Map<String, dynamic>> recentSessions = [
    {
      'title': 'Wawancara Software Engineer',
      'subtitle': 'Kemarin • 15 menit',
      'icon': Icons.mic_none_sharp,
    },
    {
      'title': 'Presenstasi Kepemimpinan',
      'subtitle': '2 hari lalu • 20 menit',
      'icon': Icons.speaker_notes_outlined,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: whiteColor,
        padding: EdgeInsets.only(top: 48, bottom: 14),
        child: SingleChildScrollView(
          child: Column(
            children: [
              titleSection(),
              heroSection(name: 'Lina'),
              trainVariantSection(context, true),
              trainVariantSection(context, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget titleSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'VoiceMentor',
            style: GoogleFonts.montserrat(
              color: blueColor,
              fontWeight: bold,
              fontSize: 24,
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: darkGreyColor,
                size: 32,
              ),
              SizedBox(width: 14),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blueColor,
                  // image: DecorationImage(
                  //   image: AssetImage('assets/images/avatars/avatar_1.png'),
                  //   fit: BoxFit.cover,
                  // ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget heroSection({required String name}) {
    return Container(
      color: greyBgColor,
      width: double.infinity,
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo ${name}!',
            style: GoogleFonts.montserrat(
              color: blackColor,
              fontWeight: bold,
              fontSize: 32,
            ),
          ),
          Text(
            'Siap melatih keterampilan wawancara anda?',
            style: GoogleFonts.roboto(
              color: greyColor,
              fontWeight: regular,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget trainVariantSection(BuildContext context, bool isTrainVariant) {
    final data = isTrainVariant ? trainVariants : recentSessions;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 16, right: 16, top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTrainVariant ? 'Pilih Jenis Latihan' : 'Sesi Terbaru',
            style: GoogleFonts.montserrat(
              color: blackColor,
              fontWeight: bold,
              fontSize: 20,
            ),
          ),
          SizedBox(height: 16),
          ...List.generate(
            data.length,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: cardChoice(
                title: data[index]['title'],
                subtitle: data[index]['subtitle'],
                isTrainVariant: isTrainVariant,
                context: context,
                icon: data[index]['icon'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget cardChoice({
    required String title,
    required String subtitle,
    required bool isTrainVariant,
    required BuildContext context,
    required IconData icon,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        if (title == 'Wawancara Kerja') {
          // Navigate to training page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetailTrainPage()),
          );
        } else {
          // Navigate to session details page
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (_) => const SessionDetailsPage()),
          // );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: BoxBorder.all(color: lightGreyColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title',
                    softWrap: true,
                    textAlign: TextAlign.start,
                    style: GoogleFonts.montserrat(
                      color: blackColor,
                      fontWeight: semiBold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$subtitle',
                    softWrap: true,
                    style: GoogleFonts.roboto(
                      color: greyColor,
                      fontWeight: regular,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isTrainVariant ? icon : Icons.play_arrow_rounded,
              color: blueColor,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }
}

// Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => const TrainingPage()),
                // );