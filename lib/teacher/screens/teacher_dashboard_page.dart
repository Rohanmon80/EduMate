import 'dart:ui';
import '../../timetables/timetable_upload_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mark_attendance_page.dart';
import 'notice_panel_page.dart';
import 'materials_upload_page.dart';
import 'teacher_marks_page.dart';
import 'analytics_page.dart';
import '../../common/screens/ai_assistant_page.dart';
import '../../common/screens/bus_tracking_page.dart';
import '../../common/screens/campus_map_page.dart';
import '../../common/screens/certificate_vault_page.dart';
import '../../common/screens/coding_contest_page.dart';
import '../../common/screens/events_page.dart';
import '../../common/screens/settings_page.dart';
import '../../main.dart';

class TeacherDashboardPage extends StatelessWidget {

  TeacherDashboardPage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context) {

    final bool isDark =
        Theme.of(context)
            .brightness ==
            Brightness.dark;

    return Scaffold(

      backgroundColor:

      isDark

          ? const Color(
        0xFF081120,
      )

          : const Color(
        0xFFF4F8FC,
      ),

      drawer: Drawer(

        child: ListView(

          children: [

            const DrawerHeader(

              child: Text(

                "Faculty Hub",

                style: TextStyle(

                  fontSize: 30,

                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),

            drawerTile(
              context,
              Icons.route,
              "Bus Tracking",
              const BusTrackingPage(),
            ),

            drawerTile(
              context,
              Icons.map,
              "Campus Map",
              const CampusMapPage(),
            ),

            drawerTile(
              context,
              Icons.workspace_premium,
              "Certificates",
              const CertificateVaultPage(),
            ),

            drawerTile(
              context,
              Icons.psychology,
              "AI Assistant",
              const AIAssistantPage(),
            ),

            drawerTile(
              context,
              Icons.code,
              "Coding Contest",
              const CodingContestPage(),
            ),

            drawerTile(
              context,
              Icons.event,
              "Events",
              const EventsPage(),
            ),

            drawerTile(
              context,
              Icons.settings,
              "Settings",
              const SettingsPage(),
            ),


          ],
        ),
      ),

      body: SafeArea(

        child:
        SingleChildScrollView(

          padding:
          const EdgeInsets.all(
            20,
          ),

          child: Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Row(

                children: [

                  Builder(

                    builder:
                        (
                        context,
                        ) {

                      return glassIcon(

                        context:
                        context,

                        icon:
                        Icons.menu,

                        onTap:
                            () {

                          Scaffold.of(
                              context)
                              .openDrawer();
                        },
                      );
                    },
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  Text(

                    "Faculty Hub",

                    style: TextStyle(

                      fontSize: 30,

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

              const SizedBox(
                height: 25,
              ),

              glassCard(

                context: context,

                child:

                StreamBuilder<
                    DocumentSnapshot>(

                  stream:

                  FirebaseFirestore
                      .instance

                      .collection(
                    "teachers",
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

                    if (!snapshot
                        .hasData ||

                        !snapshot
                            .data!
                            .exists) {

                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final data = snapshot.data!;
                    final teacher = data.data() as Map<String, dynamic>;

                    return Row(

                      children: [



                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue,
                      backgroundImage:
                      teacher.containsKey("photoUrl") &&
                          teacher["photoUrl"] != null &&
                          teacher["photoUrl"] != ""
                          ? NetworkImage(teacher["photoUrl"])
                          : null,
                      child:
                      !teacher.containsKey("photoUrl") ||
                          teacher["photoUrl"] == null ||
                          teacher["photoUrl"] == ""
                          ? Text(
                        teacher["name"]
                            .substring(0, 2)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      )
                          : null,
                    ),

                        const SizedBox(
                          width: 18,
                        ),

                        Expanded(

                          child:
                          Column(

                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children: [

                              Text(
                          teacher["name"].toString(),

                                style:
                                TextStyle(

                                  fontSize:
                                  22,

                                  fontWeight:
                                  FontWeight.bold,

                                  color:
                                  isDark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),

                              Text(
                                teacher.containsKey("designation")
                                    ? teacher["designation"].toString()
                                    : "Teacher",
                              ),

                              Text(
                                "${teacher["department"]} Department",
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              Row(

                children: [

                  Expanded(
                    child:
                    statCard(
                      context,
                      "Classes",
                      "12",
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(

                    child:

                    StreamBuilder<QuerySnapshot>(

                      stream:

                      FirebaseFirestore
                          .instance

                          .collection(
                        "users",
                      )
                          .where("role", isEqualTo: "student")

                          .snapshots(),

                      builder:
                          (
                          context,
                          snapshot,
                          ){

                        if(
                        !snapshot.hasData
                        ){

                          return statCard(

                            context,

                            "Students",

                            "...",
                          );
                        }

                        int totalStudents =

                            snapshot.data!.docs.length;

                        return statCard(

                          context,

                          "Students",

                          totalStudents
                              .toString(),
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child:
                    statCard(
                      context,
                      "Subjects",
                      "4",
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 30,
              ),

              Text(

                "Common Features",

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

              GridView.count(

                shrinkWrap: true,

                physics:
                const NeverScrollableScrollPhysics(),

                crossAxisCount: 2,

                crossAxisSpacing: 16,

                mainAxisSpacing: 16,

                childAspectRatio: 1,

                children: [

                  GestureDetector(

                    onTap:(){

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:
                              (_)=>

                          const TeacherAttendancePage(),
                        ),
                      );
                    },

                    child:

                    toolCard(

                      context,

                      "Attendance",

                      Icons.fact_check,

                      Colors.blue,
                    ),
                  ),

                  GestureDetector(

                    onTap:(){

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:
                              (_)=>

                              const TeacherNoticePage(),
                        ),
                      );
                    },

                    child:

                    toolCard(

                      context,

                      "Notices",

                      Icons.campaign,

                      Colors.orange,
                    ),
                  ),

                  GestureDetector(

                    onTap:(){

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:
                              (_)=>

                              const TeacherMaterialUploadPage(),
                        ),
                      );
                    },

                    child:

                    toolCard(

                      context,

                      "Materials",

                      Icons.upload,

                      Colors.green,
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TimetableUploadPage(),
                        ),
                      );
                    },
                    child: toolCard(
                      context,
                      "Timetable",
                      Icons.calendar_month,
                      Colors.indigo,
                    ),
                  ),

                  GestureDetector(

                    onTap:(){

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:
                              (_)=>

                          const TeacherMarksPage(),
                        ),
                      );
                    },

                    child:

                    toolCard(

                      context,

                      "Marks",

                      Icons.school,

                      Colors.red,
                    ),
                  ),

                  GestureDetector(

                    onTap:(){

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:
                              (_)=>


                              const AnalyticsPage(),
                        ),
                      );
                    },

                    child:

                    toolCard(

                      context,

                      "Analytics",

                      Icons.analytics,

                      Colors.teal,
                    ),
                  ),
                ],

              ),
              const SizedBox(
                height:20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget statCard(
      BuildContext context,
      String title,
      String value) {

    return glassCard(

      context: context,

      child: Column(

        children: [

          Text(title),

          const SizedBox(
            height: 10,
          ),

          Text(value),
        ],
      ),
    );
  }

  Widget toolCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color) {

    return glassCard(

      context: context,

      child: Column(

        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          CircleAvatar(

            radius: 30,

            backgroundColor:
            color.withOpacity(
              .15,
            ),

            child:
            Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Text(title),
        ],
      ),
    );
  }

  Widget glassCard({
    required BuildContext context,
    required Widget child,
  }) {

    return Container(

      padding:
      const EdgeInsets.all(
        20,
      ),

      decoration:
      BoxDecoration(

        color:
        Theme.of(context)
            .brightness ==
            Brightness.dark

            ? Colors.white
            .withOpacity(.06)

            : Colors.white,

        borderRadius:
        BorderRadius.circular(
          30,
        ),
      ),

      child: child,
    );
  }

  Widget glassIcon({
    required BuildContext context,
    required IconData icon,
    VoidCallback? onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: CircleAvatar(

        child:
        Icon(icon),
      ),
    );
  }

  Widget drawerTile(
      BuildContext context,
      IconData icon,
      String title,
      Widget page) {

    return ListTile(

      leading:
      Icon(icon),

      title:
      Text(title),

      onTap: () {

        Navigator.push(

          context,

          MaterialPageRoute(
            builder:
                (_) =>
            page,
          ),
        );
      },
    );
  }
}

