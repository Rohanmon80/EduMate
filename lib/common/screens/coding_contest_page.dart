import 'dart:ui';

import 'package:flutter/material.dart';

import '../../main.dart';

class CodingContestPage extends StatelessWidget {
  const CodingContestPage({super.key});

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final List<Map<String, dynamic>>
    contests = [

      {
        "title": "LeetCode Weekly Contest",
        "platform": "LeetCode",
        "difficulty": "Hard",
        "time": "Sunday • 8:00 PM",
        "color": Colors.orange,
      },

      {
        "title": "Codeforces Round #942",
        "platform": "Codeforces",
        "difficulty": "Medium",
        "time": "Saturday • 7:30 PM",
        "color": Colors.blue,
      },

      {
        "title": "Hackathon Sprint",
        "platform": "HackerRank",
        "difficulty": "Easy",
        "time": "Friday • 5:00 PM",
        "color": Colors.green,
      },

      {
        "title": "AI Coding Challenge",
        "platform": "EduMate",
        "difficulty": "Hard",
        "time": "Monday • 6:00 PM",
        "color": Colors.purple,
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
                        "Coding Contests",

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
                        "Compete & improve coding skills",

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

              /// CONTESTS
              ...contests.map(
                    (contest) =>
                    contestCard(
                      isDark: isDark,
                      contest: contest,
                    ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget contestCard({
    required bool isDark,
    required Map<String, dynamic>
    contest,
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

            Row(

              children: [

                Container(
                  width: 72,
                  height: 72,

                  decoration:
                  BoxDecoration(
                    color:
                    contest["color"]
                        .withOpacity(
                      0.15,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      22,
                    ),
                  ),

                  child: Icon(
                    Icons.code,
                    color:
                    contest["color"],
                    size: 42,
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [

                      Text(
                        contest["title"],

                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                          FontWeight.bold,

                          color:
                          isDark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        contest[
                        "platform"],

                        style: TextStyle(
                          color:
                          contest["color"],
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            infoTile(
              icon:
              Icons.speed,
              label: "Difficulty",
              value:
              contest["difficulty"],
              color: Colors.orange,
            ),

            const SizedBox(height: 14),

            infoTile(
              icon:
              Icons.schedule,
              label: "Contest Time",
              value:
              contest["time"],
              color: Colors.blue,
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
                  contest["color"],

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),
                ),

                child: const Text(
                  "Join Contest",

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

  Widget infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {

    return Container(

      padding:
      const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color:
        color.withOpacity(0.12),

        borderRadius:
        BorderRadius.circular(18),
      ),

      child: Row(

        children: [

          Icon(
            icon,
            color: color,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  label,

                  style: TextStyle(
                    color: color,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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