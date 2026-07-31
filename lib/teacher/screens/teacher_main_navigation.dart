import 'package:flutter/material.dart';
import 'materials_upload_page.dart';
import 'teacher_dashboard_page.dart';
import 'teacher_marks_page.dart';
import 'notice_panel_page.dart';
import 'teacher_profile_page.dart';

class TeacherMainNavigation
    extends StatefulWidget {

  TeacherMainNavigation({
    super.key,
  });

  @override
  State<TeacherMainNavigation>
  createState() =>
      _TeacherMainNavigationState();
}

class _TeacherMainNavigationState
    extends State<TeacherMainNavigation> {

  int currentIndex = 0;

  final List<Widget> pages = [

    TeacherDashboardPage(),

    const TeacherMarksPage(),

    const TeacherNoticePage(),

    const TeacherMaterialUploadPage(),

    const TeacherProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(

      extendBody: true,

      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF6F8FC),

      body: Stack(

        children: [

          /// CURRENT PAGE
          pages[currentIndex],

          /// FLOATING NAV BAR
          Positioned(

            left: 14,
            right: 14,
            bottom: 14,

            child: Container(

              padding:
              const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),

              decoration: BoxDecoration(

                color: isDark
                    ? const Color(0xFF15263D)
                    : Colors.white,

                borderRadius: BorderRadius.circular(22),

                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.grey.shade300,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),

              child: Row(

                mainAxisAlignment:
                MainAxisAlignment.spaceAround,

                children: [


                  navItem(
                    Icons.home,
                    "Home",
                    0,
                  ),

                  navItem(
                    Icons.fact_check,
                    "Marks",
                    1,
                  ),

                  navItem(
                    Icons.campaign,
                    "Notice",
                    2,
                  ),

                  navItem(
                    Icons.menu_book,
                    "Mats",
                    3,
                  ),

                  navItem(
                    Icons.person,
                    "Me",
                    4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget navItem(
      IconData icon,
      String label,
      int index,
      ) {
    final bool isDark =
        Theme.of(context).brightness == Brightness.dark;

    final bool isSelected =
        currentIndex == index;

    return GestureDetector(

      onTap: () {

        setState(() {

          currentIndex = index;
        });
      },

      child: AnimatedContainer(

        duration:
        const Duration(
          milliseconds: 250,
        ),

        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),

        decoration: BoxDecoration(

          color: isSelected
              ? const Color(0xFF1976D2).withOpacity(
            isDark ? 0.25 : 0.12,
          )
              : Colors.transparent,

          borderRadius:
          BorderRadius.circular(20),
        ),

        child: Column(

          mainAxisSize:
          MainAxisSize.min,

          children: [

            Icon(
              icon,

              size: 24,

              color: isSelected
                  ? const Color(0xFF1976D2)
                  : isDark
                  ? Colors.white70
                  : Colors.black54,
            ),

            const SizedBox(height: 4),

            Text(
              label,

              style: TextStyle(

                fontSize: 12,

                color: isSelected
                    ? const Color(0xFF1976D2)
                    : isDark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}