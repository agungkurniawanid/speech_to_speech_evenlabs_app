import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_speech_evenlabs/shared/theme.dart';

class DetailTrainPage extends ConsumerWidget {
  DetailTrainPage({super.key});

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
        ],
      ),
    );
  }

  Widget cardCarousel() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 16, bottom: 16, left: 8, right: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 2,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(12),
              // boxShadow: [
              //   BoxShadow(
              //     color: lightGreyColor,
              //     spreadRadius: 2,
              //     blurRadius: 5,
              //   ),
              // ],
            ),
            // child: Column(
            //   mainAxisAlignment: MainAxisAlignment.center,
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   children: [
            //     Text(
            //       'Wawacara Kerja',
            //       style: GoogleFonts.montserrat(
            //         color: blackColor,
            //         fontWeight: bold,
            //         fontSize: 16,
            //       ),
            //     ),
            //   ],
            // ),
          );
        },
      ),
    );
  }
}
