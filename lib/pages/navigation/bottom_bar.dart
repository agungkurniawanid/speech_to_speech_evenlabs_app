import 'package:awesome_bottom_bar/widgets/inspired/inspired.dart';
import 'package:flutter/material.dart';
import 'package:awesome_bottom_bar/awesome_bottom_bar.dart';
import 'package:speech_to_speech_evenlabs/pages/main/home_page.dart';
import 'package:speech_to_speech_evenlabs/pages/main/progress_page.dart';
import 'package:speech_to_speech_evenlabs/pages/main/reference_page.dart';
import 'package:speech_to_speech_evenlabs/pages/main/setting_page.dart';
import 'package:speech_to_speech_evenlabs/pages/main/training_page.dart';
import 'package:speech_to_speech_evenlabs/shared/theme.dart';

// Define icons
const List<IconData> outlinedIcons = [
  Icons.home_outlined,
  Icons.insert_chart_outlined_outlined,
  Icons.mic_none_rounded,
  Icons.book_outlined,
  Icons.settings_outlined,
];

const List<IconData> filledIcons = [
  Icons.home_filled,
  Icons.insert_chart_rounded,
  Icons.mic,
  Icons.book_rounded,
  Icons.settings_rounded,
];

const List<String> titles = [
  'Beranda',
  'Progres',
  'Latihan',
  'Referensi',
  'Pengaturan',
];

class BottomBar extends StatefulWidget {
  const BottomBar({Key? key}) : super(key: key);

  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Check if matkulApi is empty before switching tabs
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (_selectedIndex != index) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        children: [
          HomePage(),
          const ProgressPage(),
          const TrainingPage(),
          const ReferencePage(),
          const SettingPage(),
        ],
      ),
      bottomNavigationBar: BottomBarCreative(
        items: List.generate(5, (index) {
          return TabItem(
            icon: _selectedIndex == index
                ? filledIcons[index]
                : outlinedIcons[index],
            title: titles[index],
          );
        }),
        isFloating: true,
        backgroundColor: whiteColor,
        color: greyColor,
        colorSelected: blueColor,
        indexSelected: _selectedIndex,
        onTap: (int index) {
          _onItemTapped(index);
        },
        highlightStyle: const HighlightStyle(
          sizeLarge: true,
          background: Color(0xFF355DEB),
          elevation: 3,
        ),

        // animated: false,

        // itemStyle: ItemStyle.circle,
        // chipStyle: const ChipStyle(notchSmoothness: NotchSmoothness.sharpEdge),
        // isFloating: true,

        // highlightStyle: HighlightStyle(
        //   sizeLarge: true,
        //   background: blueColor,
        //   color: whiteColor,
        //   elevation: 3,
        // ),
      ),
    );
  }
}
