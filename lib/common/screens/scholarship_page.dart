import 'dart:ui';

import 'package:flutter/material.dart';

import '../../main.dart';

class ScholarshipPage extends StatelessWidget {
  const ScholarshipPage({super.key});

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final List<Map<String, dynamic>>
    scholarships = [

      {
        "title": "Merit Scholarship",
        "amount": "₹50,000",
        "deadline": "30 June 2026",
        "eligibility": "CGPA 8.5+",
        "category": "Academic",
        "color": Colors.blue,
      },

      {
        "title": "AI Research Grant",
        "amount": "₹1,20,000",
        "deadline": "15 July 2026",
        "eligibility": "AI Project Required",
        "category": "Research",
        "color": Colors.green,
      },

      {
        "title": "Sports Excellence",
        "amount": "₹40,000",
        "deadline": "10 July 2026",
        "eligibility": "State/National Level",
        "category": "Sports",
        "color": Colors.orange,
      },

      {
        "title": "Women in Tech",
        "amount": "₹75,000",
        "deadline": "25 July 2026",
        "eligibility": "CSE/IT Female Students",
        "category": "Special",
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
                        "Scholarships",

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
                        "Financial support opportunities",

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

              /// SCHOLARSHIPS
              ...scholarships.map(
                    (scholarship) =>
                    scholarshipCard(
                      isDark: isDark,
                      scholarship:
                      scholarship,
                    ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget scholarshipCard({
    required bool isDark,
    required Map<String, dynamic>
    scholarship,
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
                    scholarship["color"]
                        .withOpacity(
                      0.15,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      22,
                    ),
                  ),

                  child: Icon(
                    Icons.workspace_premium,
                    color:
                    scholarship[
                    "color"],
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
                        scholarship[
                        "title"],

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
                        scholarship[
                        "category"],

                        style: TextStyle(
                          color:
                          scholarship[
                          "color"],
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
              icon: Icons.currency_rupee,
              label: "Scholarship Amount",
              value:
              scholarship["amount"],
              color: Colors.green,
            ),

            const SizedBox(height: 14),

            infoTile(
              icon: Icons.school,
              label: "Eligibility",
              value: scholarship[
              "eligibility"],
              color: Colors.orange,
            ),

            const SizedBox(height: 14),

            infoTile(
              icon:
              Icons.calendar_today,
              label: "Deadline",
              value:
              scholarship[
              "deadline"],
              color: Colors.redAccent,
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
                  scholarship["color"],

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),
                ),

                child: const Text(
                  "Apply Now",

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