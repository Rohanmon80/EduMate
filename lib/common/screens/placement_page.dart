import 'dart:ui';

import 'package:flutter/material.dart';

import '../../main.dart';

class PlacementPage extends StatelessWidget {
  const PlacementPage({super.key});

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final List<Map<String, dynamic>>
    companies = [

      {
        "company": "Google",
        "role": "Software Engineer",
        "package": "₹32 LPA",
        "cgpa": "8.5+",
        "color": Colors.blue,
      },

      {
        "company": "Microsoft",
        "role": "App Developer",
        "package": "₹28 LPA",
        "cgpa": "8.0+",
        "color": Colors.green,
      },

      {
        "company": "Amazon",
        "role": "Cloud Engineer",
        "package": "₹24 LPA",
        "cgpa": "7.5+",
        "color": Colors.orange,
      },

      {
        "company": "TCS",
        "role": "System Engineer",
        "package": "₹7 LPA",
        "cgpa": "6.5+",
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

              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Placements",

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

                      const SizedBox(height: 6),

                      Text(
                        "Placement opportunities",

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

              Row(

                children: [

                  Expanded(
                    child: statCard(
                      title: "Highest",
                      value: "₹32L",
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: statCard(
                      title: "Placed",
                      value: "82%",
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 35),

              Text(
                "Top Companies",

                style: TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.bold,

                  color:
                  isDark
                      ? Colors.white
                      : Colors.black,
                ),
              ),

              const SizedBox(height: 20),

              ...companies.map(
                    (company) =>
                    companyCard(
                      isDark: isDark,
                      company: company,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget companyCard({
    required bool isDark,
    required Map<String, dynamic>
    company,
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
                  width: 70,
                  height: 70,

                  decoration:
                  BoxDecoration(
                    color:
                    company["color"]
                        .withOpacity(
                      0.15,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      22,
                    ),
                  ),

                  child: Icon(
                    Icons.business,
                    color:
                    company["color"],
                    size: 40,
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
                        company["company"],

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

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        company["role"],

                        style: TextStyle(
                          color:
                          isDark
                              ? Colors
                              .white70
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            Row(

              children: [

                Expanded(
                  child: infoCard(
                    title: "Package",
                    value:
                    company["package"],
                    color:
                    Colors.green,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: infoCard(
                    title: "CGPA",
                    value:
                    company["cgpa"],
                    color:
                    Colors.orange,
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
                  company["color"],

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

  Widget statCard({
    required String title,
    required String value,
    required Color color,
  }) {

    return Container(

      padding:
      const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color:
        color.withOpacity(0.15),

        borderRadius:
        BorderRadius.circular(22),
      ),

      child: Column(

        children: [

          Text(
            title,

            style: TextStyle(
              color: color,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            value,

            style: TextStyle(
              fontSize: 28,
              fontWeight:
              FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget infoCard({
    required String title,
    required String value,
    required Color color,
  }) {

    return Container(

      padding:
      const EdgeInsets.all(16),

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
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,

            style: TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.bold,
              color: color,
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