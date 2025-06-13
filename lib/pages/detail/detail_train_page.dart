import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_speech_evenlabs/shared/theme.dart';

class DetailTrainPage extends ConsumerWidget {
  DetailTrainPage({super.key});
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
              titleSection('Lina', true),
              heroSection(),
              contentSection(context),
              // heroSection(name: 'Lina'),
              // trainVariantSection(context, true),
              // trainVariantSection(context, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget titleSection(String name, bool isPublicRole) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            child: Row(
              children: [
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
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$name',
                      style: GoogleFonts.montserrat(
                        color: blackColor,
                        fontWeight: bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${isPublicRole ? 'Pengguna Gratis' : 'Pengguna Premium'}',
                      style: GoogleFonts.montserrat(
                        color: darkGreyColor,
                        fontWeight: bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.notifications_none_rounded,
                color: darkGreyColor,
                size: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget heroSection() {
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
            'Siap untuk Latihan?',
            style: GoogleFonts.montserrat(
              color: blackColor,
              fontWeight: bold,
              fontSize: 28,
            ),
          ),
          Text(
            'Pilih sesi latihan di bawah ini',
            style: GoogleFonts.roboto(
              color: greyColor,
              fontWeight: regular,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            child: Row(
              children: [
                cardSkenario(
                  title: 'Skenario 1',
                  subTitle: '15',
                  icon: Icons.work_rounded,
                  sizeIcon: 30,
                ),
                SizedBox(width: 14),
                cardSkenario(
                  title: 'Skenario 1',
                  subTitle: '10',
                  icon: Icons.star_rounded,
                  sizeIcon: 36,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget contentSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 16, right: 16, top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sesi Terbaru',
            style: GoogleFonts.montserrat(
              color: blackColor,
              fontWeight: bold,
              fontSize: 24,
            ),
          ),
          trainVariantSection(context),
        ],
      ),
    );
  }

  Widget cardSkenario({
    required String title,
    required String subTitle,
    required IconData icon,
    required int sizeIcon,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: whiteColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            circleIcon(
              icon: icon,
              colorBg: lightBlueColor,
              iconColor: blueColor,
              sizeIcon: sizeIcon,
            ),
            SizedBox(height: 8),
            Text(
              title ?? 'Skenario 1',
              style: GoogleFonts.montserrat(
                color: blackColor,
                fontWeight: bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 2),
            Text(
              '${subTitle}+ skenario',
              style: GoogleFonts.roboto(
                color: greyColor,
                fontWeight: regular,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget circleIcon({
    required IconData icon,
    required Color colorBg,
    required Color iconColor,
    required int sizeIcon,
  }) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(shape: BoxShape.circle, color: colorBg),
      child: Icon(icon, color: iconColor, size: sizeIcon.toDouble()),
    );
  }

  Widget trainVariantSection(BuildContext context) {
    final data = recentSessions;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8),
          ...List.generate(
            data.length,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: cardChoice(
                title: data[index]['title'],
                subtitle: data[index]['subtitle'],
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
    required BuildContext context,
    required IconData icon,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fitur session ready.'),
            duration: Duration(seconds: 2),
          ),
        );
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
                maxWidth: MediaQuery.of(context).size.width * 0.6,
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
            Icon(Icons.play_arrow_rounded, color: blueColor, size: 32),
          ],
        ),
      ),
    );
  }
}
