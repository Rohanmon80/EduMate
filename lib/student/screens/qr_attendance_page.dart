import 'dart:ui';

import 'package:flutter/material.dart';

import '../../main.dart';

class QRAttendancePage extends StatelessWidget {
  const QRAttendancePage({super.key});

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
                        "QR Attendance",

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
                        "Scan classroom QR code",

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

              /// QR CARD
              glassCard(

                isDark: isDark,

                child: Column(

                  children: [

                    Container(
                      width: 220,
                      height: 220,

                      decoration: BoxDecoration(
                        color:
                        Colors.white.withOpacity(0.1),

                        borderRadius:
                        BorderRadius.circular(30),

                        border: Border.all(
                          color:
                          Colors.white24,
                          width: 2,
                        ),
                      ),

                      child: const Center(
                        child: Icon(
                          Icons.qr_code_scanner,
                          size: 120,
                          color: Colors.blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Text(
                      "Ready to Scan",

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
                      "Point camera at classroom QR code",

                      style: TextStyle(
                        fontSize: 16,

                        color:
                        isDark
                            ? Colors.white70
                            : Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 30),

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

                        child: const Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,

                          children: [

                            Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),

                            SizedBox(width: 12),

                            Text(
                              "Start Scanning",

                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              Text(
                "Recent Attendance",

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

              attendanceTile(
                isDark: isDark,
                subject: "Data Structures",
                room: "B-204",
                time: "10:00 AM",
                status: "PRESENT",
                color: Colors.green,
              ),

              attendanceTile(
                isDark: isDark,
                subject: "Operating Systems",
                room: "C-101",
                time: "12:00 PM",
                status: "PRESENT",
                color: Colors.blue,
              ),

              attendanceTile(
                isDark: isDark,
                subject: "DBMS",
                room: "A-302",
                time: "02:00 PM",
                status: "ABSENT",
                color: Colors.redAccent,
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

  Widget attendanceTile({
    required bool isDark,
    required String subject,
    required String room,
    required String time,
    required String status,
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
                Icons.qr_code,
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
                    "$room • $time",

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

            Container(

              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),

              decoration: BoxDecoration(
                color:
                color.withOpacity(0.15),

                borderRadius:
                BorderRadius.circular(18),
              ),

              child: Text(
                status,

                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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