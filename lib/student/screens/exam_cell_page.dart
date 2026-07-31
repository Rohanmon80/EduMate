import 'dart:ui';

import 'package:flutter/material.dart';

import '../../main.dart';

class ExamCellPage extends StatelessWidget {
  const ExamCellPage({super.key});

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      backgroundColor:
      isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      body: SafeArea(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              /// TOP BAR
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Exam Cell",

                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,

                          color:
                          isDark
                              ? Colors.white
                              : const Color(0xFF0B1736),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Upcoming exams & schedules",

                        style: TextStyle(
                          fontSize: 16,

                          color:
                          isDark
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  glassIcon(
                    icon:
                    isDark
                        ? Icons.light_mode
                        : Icons.dark_mode,

                    onTap: () {

                      EduMateApp.of(context)
                          ?.toggleTheme();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 35),

              /// UPCOMING EXAM CARD
              glassCard(
                isDark: isDark,

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const Text(
                      "Next Exam",

                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      "Data Structures",

                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,

                        color:
                        isDark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "20 June 2026 • 10:00 AM",

                      style: TextStyle(
                        fontSize: 16,

                        color:
                        isDark
                            ? Colors.white70
                            : Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(

                      children: [

                        Expanded(
                          child: infoBox(
                            title: "Room",
                            value: "B-204",
                            color: Colors.orange,
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: infoBox(
                            title: "Duration",
                            value: "3 Hours",
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              Text(
                "Exam Schedule",

                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,

                  color:
                  isDark
                      ? Colors.white
                      : Colors.black,
                ),
              ),

              const SizedBox(height: 20),

              examTile(
                isDark: isDark,
                subject: "Data Structures",
                date: "20 June",
                time: "10:00 AM",
                color: Colors.blue,
              ),

              examTile(
                isDark: isDark,
                subject: "Operating Systems",
                date: "22 June",
                time: "02:00 PM",
                color: Colors.green,
              ),

              examTile(
                isDark: isDark,
                subject: "DBMS",
                date: "24 June",
                time: "10:00 AM",
                color: Colors.orange,
              ),

              examTile(
                isDark: isDark,
                subject: "Java Programming",
                date: "26 June",
                time: "09:00 AM",
                color: Colors.purple,
              ),

              const SizedBox(height: 35),

              /// BUTTONS
              SizedBox(
                width: double.infinity,
                height: 62,

                child: ElevatedButton(

                  onPressed: () {},

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                    const Color(0xFF008CFF),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(22),
                    ),
                  ),

                  child: const Text(
                    "Download Hall Ticket",

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 62,

                child: ElevatedButton(

                  onPressed: () {},

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                    Colors.deepPurple,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(22),
                    ),
                  ),

                  child: const Text(
                    "Download Timetable",

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget glassCard({
    required bool isDark,
    required Widget child,
  }) {

    return ClipRRect(

      borderRadius:
      BorderRadius.circular(30),

      child: BackdropFilter(

        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: Container(

          padding: const EdgeInsets.all(24),

          decoration: BoxDecoration(

            color:
            isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.35),

            borderRadius:
            BorderRadius.circular(30),

            border: Border.all(
              color:
              Colors.white.withOpacity(0.2),
            ),
          ),

          child: child,
        ),
      ),
    );
  }

  Widget examTile({
    required bool isDark,
    required String subject,
    required String date,
    required String time,
    required Color color,
  }) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: glassCard(

        isDark: isDark,

        child: Row(

          children: [

            Container(
              width: 58,
              height: 58,

              decoration: BoxDecoration(
                color:
                color.withOpacity(0.15),

                borderRadius:
                BorderRadius.circular(18),
              ),

              child: Icon(
                Icons.menu_book,
                color: color,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    subject,

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,

                      color:
                      isDark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "$date • $time",

                    style: TextStyle(
                      color:
                      isDark
                          ? Colors.white70
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.blue,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget infoBox({
    required String title,
    required String value,
    required Color color,
  }) {

    return Container(

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
        color.withOpacity(0.15),

        borderRadius:
        BorderRadius.circular(20),
      ),

      child: Column(

        children: [

          Text(
            title,

            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,

            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget glassIcon({
    required IconData icon,
    VoidCallback? onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: ClipRRect(

        borderRadius:
        BorderRadius.circular(18),

        child: BackdropFilter(

          filter: ImageFilter.blur(
            sigmaX: 15,
            sigmaY: 15,
          ),

          child: Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(

              color: Colors.white.withOpacity(0.12),

              borderRadius:
              BorderRadius.circular(18),

              border: Border.all(
                color: Colors.white24,
              ),
            ),

            child: Icon(
              icon,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}