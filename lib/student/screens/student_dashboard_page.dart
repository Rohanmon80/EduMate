import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../timetables/timetable_page.dart';
import '../../common/widgets/app_drawer.dart';
import '../../main.dart';
import 'attendance_page.dart';
import 'notices_page.dart';
import 'results_page.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      drawer: const AppDrawer(),

      backgroundColor:
      isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      body: SafeArea(

        child:
        StreamBuilder<DocumentSnapshot>(

          stream:
          FirebaseFirestore.instance

              .collection(
            "users",
          )

              .doc(
            FirebaseAuth
                .instance
                .currentUser!
                .uid,
          )

              .snapshots(),

          builder:
              (
              context,
              snapshot,
              ) {

            if (!snapshot.hasData ||
                !snapshot.data!.exists) {

              return const Center(
                child:
                CircularProgressIndicator(),
              );
            }

            final data =
            snapshot.data!;

            final user =

            data.data()

            as Map<
                String,
                dynamic>;

            final studentName = data["name"].toString();

            final photoUrl =

            user.containsKey(
                "photoUrl"
            )

                ?

            user[
            "photoUrl"
            ]

                : "";

            return SingleChildScrollView(

              padding:
              const EdgeInsets.all(
                20,
              ),

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  /// TOP BAR
                  Row(

                    children: [

                      Builder(
                        builder:
                            (context) {

                          return glassIcon(

                            icon:
                            Icons.menu,

                            isDark:
                            isDark,

                            onTap: () {

                              Scaffold.of(
                                context,
                              ).openDrawer();
                            },
                          );
                        },
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(

                        child:
                        Column(

                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [

                            Text(

                              "EduMate",

                              style:
                              TextStyle(

                                fontSize:
                                30,

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
                              height: 4,
                            ),

                            Text(

                              "Welcome back, ${data["name"]} 👋",

                              style:
                              TextStyle(

                                fontSize:
                                15,

                                color:

                                isDark

                                    ? Colors.white70

                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      glassIcon(

                        icon:

                        isDark

                            ? Icons.light_mode

                            : Icons.dark_mode,

                        isDark:
                        isDark,

                        onTap: () {

                          EduMateApp.of(
                            context,
                          )?.toggleTheme();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  /// PROFILE CARD

                  glassCard(

                    isDark:isDark,

                    child:

                    Row(

                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children:[

                        CircleAvatar(

                          radius:42,

                          backgroundColor:
                          Colors.blue,

                          backgroundImage:

                          photoUrl != null

                              &&

                              photoUrl != ""

                              ?

                          NetworkImage(
                            photoUrl,
                          )

                              : null,

                          child:

                          photoUrl == null

                              ||

                              photoUrl == ""

                              ?

                          Text(

                            studentName.length >= 2
                                ? studentName.substring(0, 2).toUpperCase()
                                : studentName.toUpperCase(),

                            style:

                            const TextStyle(

                              fontSize:26,

                              fontWeight:
                              FontWeight.bold,

                              color:
                              Colors.white,
                            ),
                          )

                              : null,
                        ),

                        const SizedBox(
                          width:18,
                        ),

                        Expanded(

                          child:

                          Column(

                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children:[

                              Text(

                                data["name"],

                                style:

                                TextStyle(

                                  fontSize:24,

                                  fontWeight:
                                  FontWeight.bold,

                                  color:

                                  isDark

                                      ?

                                  Colors.white

                                      :

                                  Colors.black,
                                ),
                              ),

                              const SizedBox(
                                height:6,
                              ),

                              Text(

                                "${data["rollNumber"]} • "

                                    "${data["department"]} • "

                "Sec ${user["section"]?.toString() ?? "-"}",

                                style:

                                TextStyle(

                                  color:

                                  isDark

                                      ?

                                  Colors.white70

                                      :

                                  Colors.grey,
                                ),
                              ),

                              if(

                              user.containsKey(
                                "bio",
                              )

                                  &&

                                  user["bio"] != null

                                  &&

                                  user["bio"] != ""

                              )

                                Padding(

                                  padding:

                                  const EdgeInsets.only(
                                    top:10,
                                  ),

                                  child:

                                  Container(

                                    padding:

                                    const EdgeInsets.all(
                                      12,
                                    ),

                                    decoration:

                                    BoxDecoration(

                                      color:

                                      Colors.blue
                                          .withOpacity(
                                        0.08,
                                      ),

                                      borderRadius:

                                      BorderRadius.circular(
                                        14,
                                      ),
                                    ),

                                    child:

                                    Text(

                                      user["bio"],

                                      maxLines:2,

                                      overflow:
                                      TextOverflow.ellipsis,

                                      style:

                                      TextStyle(

                                        color:

                                        isDark

                                            ?

                                        Colors.white70

                                            :

                                        Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),

                              const SizedBox(
                                height:12,
                              ),

                              Container(

                                padding:

                                const EdgeInsets.symmetric(

                                  horizontal:14,

                                  vertical:7,
                                ),

                                decoration:

                                BoxDecoration(

                                  color:

                                  Colors.blue
                                      .withOpacity(
                                    0.15,
                                  ),

                                  borderRadius:

                                  BorderRadius.circular(
                                    15,
                                  ),
                                ),

                                child:

                                Text(

                                  "Semester ${data["semester"]}",

                                  style:

                                  const TextStyle(

                                    color:
                                    Colors.blue,

                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height:30,
                  ),

                  /// STATS

                  Row(

                    children: [

                      Expanded(
                        child:
                        statCard(
                          title:
                          "Attendance",
                          value:
                          "${user["attendance"] ?? 0}%",
                          color:
                          Colors.green,
                        ),
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child:
                        statCard(
                          title:
                          "CGPA",
                          value:
                          (user["cgpa"] ?? "-").toString(),
                          color:
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Row(

                    children: [

                      Expanded(
                        child:
                        statCard(
                          title:
                          "Semester",
                          value:
                          (user["semester"] ?? "-").toString(),
                          color:
                          Colors.orange,
                        ),
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      Expanded(
                        child:
                        statCard(
                          title:
                          "Fees",
                          value:

                          "₹${user["feesDue"] ?? 0}",
                          color:
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  Text(
                    "Quick Access",

                    style:
                    TextStyle(

                      fontSize: 28,

                      fontWeight:
                      FontWeight.bold,

                color:

                isDark

                ?

                Colors.white

                    :

                Colors.black,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  GridView.count(

                    shrinkWrap: true,

                    physics:
                    const NeverScrollableScrollPhysics(),

                    crossAxisCount: 2,

                    mainAxisSpacing: 16,

                    crossAxisSpacing: 16,

                    childAspectRatio: 1.05,



                    children: [



                      quickCard(
                        context: context,
                        title: "Attendance",
                        icon: Icons.bar_chart,
                        color: Colors.green,
                        isDark: isDark,
                        page: const AttendancePage(),
                      ),

                      quickCard(
                        context: context,
                        title: "Results",
                        icon: Icons.school,
                        color: Colors.blue,
                        isDark: isDark,
                        page: const ResultsPage(),
                      ),
                      quickCard(
                        context: context,
                        title: "Timetable",
                        icon: Icons.calendar_month,
                        color: Colors.orange,
                        isDark: isDark,
                        page: const TimetablePage(),
                      ),



                      quickCard(
                        context: context,
                        title: "Notices",
                        icon: Icons.notifications,
                        color: Colors.purple,
                        isDark: isDark,
                        page: const NoticesPage(),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 35,
                  ),

                  glassCard(

                    isDark:isDark,

                    child:

                    Row(

                      children:[

                        const Icon(
                          Icons.person,
                          color:
                          Colors.blue,
                        ),

                        const SizedBox(
                          width:12,
                        ),

                        Expanded(

                          child:

                          Text(

                            user.containsKey("photoUrl") &&
                photoUrl.toString().isNotEmpty

                                &&

                                data["photoUrl"] != null

                                ?

                            "Profile completed"

                                :

                            "Add profile photo",

                            style:

                            TextStyle(

                              fontWeight:
                              FontWeight.bold,

                              color:

                              isDark

                                  ?

                              Colors.white

                                  :

                              Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height:25,
                  ),

                  Text(
                    "Recent Activity",

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

                  const SizedBox(
                    height: 20,
                  ),

                  glassCard(

                    isDark: isDark,

                    child: Column(

                      children: [

                        activityTile(
                          title:
                          "Attendance Updated",

                          subtitle:
                          "Current attendance ${data["attendance"]}%",

                          color:
                          Colors.green,
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        activityTile(
                          title:
                          "CGPA Updated",

                          subtitle:
                          "Current CGPA ${data["cgpa"]}",

                          color:
                          Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }







  Widget quickCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required Widget page,
  }) {

    return GestureDetector(

      onTap: () {

        Navigator.push(

          context,

          MaterialPageRoute(
            builder: (_) => page,
          ),
        );
      },

      child: glassCard(

        isDark: isDark,

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            Container(
              width: 70,
              height: 70,

              decoration: BoxDecoration(
                color:
                color.withValues(alpha: 0.15),

                borderRadius:
                BorderRadius.circular(
                  22,
                ),
              ),

              child: Icon(
                icon,
                color: color,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              title,

              textAlign: TextAlign.center,

              maxLines: 1,

              overflow:
              TextOverflow.ellipsis,

              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.bold,

                color:
                isDark
                    ? Colors.white
                    : Colors.black,
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
        color.withValues(alpha: 0.15),

        borderRadius:
        BorderRadius.circular(24),
      ),

      child: Column(

        children: [

          Text(
            value,

            style: TextStyle(
              fontSize: 28,
              fontWeight:
              FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,

            style: TextStyle(
              fontWeight:
              FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget activityTile({
    required String title,
    required String subtitle,
    required Color color,
  }) {

    return Row(

      children: [

        Container(
          width: 14,
          height: 14,

          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Text(
                title,

                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
              ),
            ],
          ),
        ),
      ],
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

        filter:
        ImageFilter.blur(
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
    required bool isDark,
    VoidCallback? onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(
        width: 52,
        height: 52,

        decoration:
        BoxDecoration(

          color:
          isDark
              ? Colors.white
              .withOpacity(0.08)
              : Colors.white
              .withOpacity(0.5),

          borderRadius:
          BorderRadius.circular(
            18,
          ),

          border: Border.all(
            color:
            Colors.white24,
          ),
        ),

        child: Icon(
          icon,

          color:

          isDark

              ?

          Colors.white

              :

          Colors.black,
        ),
      ),
    );
  }
}