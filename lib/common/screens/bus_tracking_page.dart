import 'dart:ui';

import 'package:flutter/material.dart';

import '../../main.dart';

class BusTrackingPage extends StatelessWidget {
  const BusTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final List<Map<String, dynamic>>
    buses = [

      {
        "bus": "Bus 01",
        "route":
        "City Center → College",
        "driver": "Ramesh Kumar",
        "time": "08:15 AM",
        "seats": "12 Seats",
        "status": "On Route",
        "color": Colors.green,
      },

      {
        "bus": "Bus 02",
        "route":
        "Railway Station → College",
        "driver": "Sanjay Das",
        "time": "08:30 AM",
        "seats": "5 Seats",
        "status": "Arriving",
        "color": Colors.orange,
      },

      {
        "bus": "Bus 03",
        "route":
        "North Zone → College",
        "driver": "Amit Roy",
        "time": "08:45 AM",
        "seats": "Full",
        "status": "Delayed",
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
                        "Bus Tracking",

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
                        "Track college buses live",

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

              /// BUS LIST
              ...buses.map(
                    (bus) => busCard(
                  isDark: isDark,
                  bus: bus,
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget busCard({
    required bool isDark,
    required Map<String, dynamic>
    bus,
  }) {

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 22,
      ),

      child: glassCard(

        isDark: isDark,

        child: Column(
          children: [

            Row(

              children: [

                Container(
                  width: 75,
                  height: 75,

                  decoration:
                  BoxDecoration(
                    color:
                    bus["color"]
                        .withOpacity(
                      0.15,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      22,
                    ),
                  ),

                  child: Icon(
                    Icons.directions_bus,
                    color: bus["color"],
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
                        bus["bus"],

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
                        bus["route"],

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

            const SizedBox(height: 24),

            Row(

              children: [

                Expanded(
                  child: infoCard(
                    title: "Driver",
                    value:
                    bus["driver"],
                    color:
                    Colors.blue,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: infoCard(
                    title: "Time",
                    value:
                    bus["time"],
                    color:
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(

              children: [

                Expanded(
                  child: infoCard(
                    title: "Seats",
                    value:
                    bus["seats"],
                    color:
                    Colors.green,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: infoCard(
                    title: "Status",
                    value:
                    bus["status"],
                    color:
                    bus["color"],
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
                  bus["color"],

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),
                ),

                child: const Text(
                  "Track Live",

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

            textAlign: TextAlign.center,

            style: TextStyle(
              fontSize: 18,
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