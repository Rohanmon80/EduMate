import 'dart:ui';

import 'package:flutter/material.dart';

import '../../main.dart';

class CampusMapPage extends StatelessWidget {
  const CampusMapPage({super.key});

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final List<Map<String, dynamic>>
    places = [

      {
        "name": "Main Library",
        "location": "Block A",
        "distance": "120m Away",
        "icon": Icons.local_library,
        "color": Colors.blue,
      },

      {
        "name": "Computer Science Dept",
        "location": "Block C",
        "distance": "300m Away",
        "icon": Icons.computer,
        "color": Colors.green,
      },

      {
        "name": "Boys Hostel",
        "location": "North Campus",
        "distance": "500m Away",
        "icon": Icons.apartment,
        "color": Colors.orange,
      },

      {
        "name": "College Cafeteria",
        "location": "Central Area",
        "distance": "180m Away",
        "icon": Icons.restaurant,
        "color": Colors.purple,
      },

      {
        "name": "Sports Complex",
        "location": "South Campus",
        "distance": "650m Away",
        "icon": Icons.sports_soccer,
        "color": Colors.redAccent,
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
                        "Campus Map",

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
                        "Navigate around campus",

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

              /// MAP PREVIEW
              glassCard(

                isDark: isDark,

                child: Container(
                  height: 220,
                  width: double.infinity,

                  decoration: BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(
                      24,
                    ),

                    gradient:
                    const LinearGradient(
                      colors: [
                        Color(0xFF005BEA),
                        Color(0xFF00C6FB),
                      ],
                    ),
                  ),

                  child: const Center(
                    child: Icon(
                      Icons.map,
                      size: 90,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              Text(
                "Campus Locations",

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

              ...places.map(
                    (place) => placeCard(
                  isDark: isDark,
                  place: place,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget placeCard({
    required bool isDark,
    required Map<String, dynamic>
    place,
  }) {

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 20,
      ),

      child: glassCard(

        isDark: isDark,

        child: Row(

          children: [

            Container(
              width: 72,
              height: 72,

              decoration:
              BoxDecoration(
                color:
                place["color"]
                    .withOpacity(
                  0.15,
                ),

                borderRadius:
                BorderRadius.circular(
                  22,
                ),
              ),

              child: Icon(
                place["icon"],
                color:
                place["color"],
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
                    place["name"],

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
                    place["location"],

                    style: TextStyle(
                      color:
                      isDark
                          ? Colors
                          .white70
                          : Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    place["distance"],

                    style: TextStyle(
                      color:
                      place["color"],
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(

              onPressed: () {},

              icon: Icon(
                Icons.navigation,
                color:
                place["color"],
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