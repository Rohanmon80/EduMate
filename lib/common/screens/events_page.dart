import 'dart:ui';

import 'package:flutter/material.dart';

import '../../main.dart';

class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final List<Map<String, dynamic>>
    events = [

      {
        "title": "AI Hackathon 2026",
        "date": "24 June 2026",
        "venue": "Main Auditorium",
        "category": "Technical",
        "color": Colors.blue,
      },

      {
        "title": "Annual Cultural Fest",
        "date": "02 July 2026",
        "venue": "Open Ground",
        "category": "Cultural",
        "color": Colors.purple,
      },

      {
        "title": "Startup Summit",
        "date": "15 July 2026",
        "venue": "Seminar Hall",
        "category": "Business",
        "color": Colors.orange,
      },

      {
        "title": "Sports Tournament",
        "date": "20 July 2026",
        "venue": "College Stadium",
        "category": "Sports",
        "color": Colors.green,
      },
    ];

    return Scaffold(

      appBar: AppBar(

        backgroundColor: Colors.transparent,

        elevation: 0,

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed: () {

            Navigator.pop(context);
          },
        ),
      ),

      backgroundColor:
      isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      body: SafeArea(

        child: SingleChildScrollView(

          padding:
          const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              /// TOP BAR
              Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

                children: [

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [

                      Text(
                        "College Events",

                        style: TextStyle(
                          fontSize: 36,
                          fontWeight:
                          FontWeight.bold,

                          color:
                          isDark
                              ? Colors.white
                              : const Color(
                            0xFF0B1736,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        "Explore upcoming activities",

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

                      EduMateApp.of(
                        context,
                      )?.toggleTheme();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 35),

              /// EVENTS LIST
              ...events.map(
                    (event) => eventCard(
                  isDark: isDark,
                  event: event,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget eventCard({
    required bool isDark,
    required Map<String, dynamic>
    event,
  }) {

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 22,
      ),

      child: glassCard(

        isDark: isDark,

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            /// EVENT IMAGE AREA
            Container(
              height: 180,
              width: double.infinity,

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [

                    event["color"]
                        .withOpacity(0.8),

                    event["color"]
                        .withOpacity(0.4),
                  ],
                ),

                borderRadius:
                BorderRadius.circular(
                  24,
                ),
              ),

              child: Center(

                child: Icon(
                  Icons.event,
                  size: 70,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 22),

            /// CATEGORY
            Container(

              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),

              decoration: BoxDecoration(
                color:
                event["color"]
                    .withOpacity(0.15),

                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),

              child: Text(
                event["category"],

                style: TextStyle(
                  color: event["color"],
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// TITLE
            Text(
              event["title"],

              style: TextStyle(
                fontSize: 24,
                fontWeight:
                FontWeight.bold,

                color:
                isDark
                    ? Colors.white
                    : Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            Row(

              children: [

                Icon(
                  Icons.calendar_today,
                  color: event["color"],
                  size: 20,
                ),

                const SizedBox(width: 10),

                Text(
                  event["date"],

                  style: TextStyle(
                    color:
                    isDark
                        ? Colors.white70
                        : Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(

              children: [

                Icon(
                  Icons.location_on,
                  color: event["color"],
                  size: 20,
                ),

                const SizedBox(width: 10),

                Text(
                  event["venue"],

                  style: TextStyle(
                    color:
                    isDark
                        ? Colors.white70
                        : Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 56,

              child: ElevatedButton(

                onPressed: () {},

                style:
                ElevatedButton.styleFrom(

                  backgroundColor:
                  event["color"],

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),
                ),

                child: const Text(
                  "Register Now",

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
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

          padding:
          const EdgeInsets.all(22),

          decoration: BoxDecoration(

            color:
            isDark
                ? Colors.white
                .withOpacity(0.08)
                : Colors.white
                .withOpacity(0.35),

            borderRadius:
            BorderRadius.circular(
              30,
            ),

            border: Border.all(
              color:
              Colors.white
                  .withOpacity(0.2),
            ),
          ),

          child: child,
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

      child: Container(
        width: 52,
        height: 52,

        decoration:
        BoxDecoration(

          color: Colors.white
              .withOpacity(
            0.12,
          ),

          borderRadius:
          BorderRadius.circular(
            18,
          ),

          border: Border.all(
            color: Colors.white24,
          ),
        ),

        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}