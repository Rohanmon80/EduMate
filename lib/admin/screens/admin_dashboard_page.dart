import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../../services/firestore_service.dart';

import '../../timetables/timetable_upload_page.dart';
import 'admin_analytics_page.dart';
import 'admin_pending_fees_page.dart';

import 'admin_notices_page.dart';

class AdminDashboardPage extends StatelessWidget {

  AdminDashboardPage({
    super.key,
  });

  final FirestoreService service =
  FirestoreService();

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

                "Admin Console",

                style: TextStyle(

                  fontSize: 28,

                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),

            drawerTile(
              context,
              Icons.route,
              "Bus Tracking",
            ),

            drawerTile(
              context,
              Icons.map,
              "Campus Map",
            ),

            drawerTile(
              context,
              Icons.event,
              "Events",
            ),

            drawerTile(
              context,
              Icons.psychology,
              "AI Assistant",
            ),

            drawerTile(
              context,
              Icons.settings,
              "Settings",
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

              /// TOP BAR

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
                    width: 12,
                  ),

                  Expanded(

                    child: Column(

                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        Text(

                          "Admin Console",

                          overflow:
                          TextOverflow.ellipsis,

                          style:
                          TextStyle(

                            fontSize:
                            28,

                            fontWeight:
                            FontWeight.bold,

                            color:
                            isDark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),

                        Text(

                          "Admin Control Center",

                          overflow:
                          TextOverflow.ellipsis,

                          style:
                          TextStyle(

                            fontSize:
                            12,

                            color:
                            isDark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  glassIcon(

                    context:
                    context,

                    icon:
                    isDark
                        ? Icons.light_mode
                        : Icons.dark_mode,

                    onTap:
                        () {

                      EduMateApp.of(
                          context)
                          ?.toggleTheme();
                    },
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  glassIcon(

                    context:
                    context,

                    icon:
                    Icons.notifications_none,
                  ),
                ],
              ),

              const SizedBox(
                height:20,
              ),

              StreamBuilder<
                  DocumentSnapshot>(

                stream:

                FirebaseFirestore
                    .instance

                    .collection(
                  "admins",
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
                    ){

                  if(
                  !snapshot.hasData
                      ||

                      !snapshot.data!.exists
                  ){

                    return const SizedBox();
                  }

                  final data =

                  snapshot.data!;

                  return Container(

                    padding:

                    const EdgeInsets.all(
                      20,
                    ),

                    decoration:

                    BoxDecoration(

                      color:

                      isDark

                          ?

                      Colors.white
                          .withOpacity(
                        0.06,
                      )

                          :

                      Colors.white,

                      borderRadius:

                      BorderRadius.circular(
                        28,
                      ),
                    ),

                    child:

                    Row(

                      children:[

                        CircleAvatar(

                          radius:35,

                          backgroundColor:
                          Colors.blue,

                          backgroundImage:

                          data.data()
                              .toString()
                              .contains(
                              "photoUrl"
                          )

                              &&

                              data["photoUrl"] != null

                              &&

                              data["photoUrl"] != ""

                              ?

                          NetworkImage(
                            data["photoUrl"],
                          )

                              : null,

                          child:

                          data["photoUrl"] == null

                              ||

                              data["photoUrl"] == ""

                              ?

                          Text(

                            (
                                data["name"]

                                    ??

                                    "AD"

                            )

                                .toString()

                                .length >= 2

                                ?

                            data["name"]
                                .toString()
                                .substring(
                              0,
                              2,
                            )

                                :

                            "AD"

                                .toUpperCase(),
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

                                data["name"]

                                    ??

                                    "Admin",

                                style:

                                TextStyle(

                                  fontSize:22,

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

                              Text(

                                data.data()
                                    .toString()
                                    .contains(
                                    "designation"
                                )

                                    ?

                                data["designation"]

                                    :

                                "Administrator",
                              ),

                              Text(

                                "Office : ${

                                    data.data()
                                        .toString()
                                        .contains(
                                        "office"
                                    )

                                        ?

                                    data["office"]

                                        :

                                    "-"

                                }",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(
                height:30,
              ),

              /// OVERVIEW

              StreamBuilder<
                  QuerySnapshot>(

                stream:

                FirebaseFirestore
                    .instance

                    .collection(
                  "users",
                )

                    .snapshots(),

                builder:
                    (
                    context,
                    snapshot,
                    ){

                  if(
                  !snapshot.hasData
                  ){

                    return const Center(

                      child:
                      CircularProgressIndicator(),
                    );
                  }

                  int students = 0;

                  for(
                  var doc
                  in snapshot.data!.docs
                  ){

                    final data =

                    doc.data()

                    as Map<
                        String,
                        dynamic>;

                    if(
                    data["role"]

                        ==

                        "student"
                    ){

                      students++;
                    }
                  }

                  return StreamBuilder<
                      QuerySnapshot>(

                    stream:

                    FirebaseFirestore
                        .instance

                        .collection(
                      "teachers",
                    )

                        .snapshots(),

                    builder:
                        (
                        context,
                        teacherSnapshot,
                        ){

                      if(
                      !teacherSnapshot
                          .hasData
                      ){

                        return const SizedBox();
                      }

                      int teachers =

                          teacherSnapshot
                              .data!
                              .docs
                              .length;

                      return StreamBuilder<
                          QuerySnapshot>(

                        stream:

                        FirebaseFirestore
                            .instance

                            .collection(
                          "admins",
                        )

                            .snapshots(),

                        builder:
                            (
                            context,
                            adminSnapshot,
                            ){

                          if(
                          !adminSnapshot
                              .hasData
                          ){

                            return const SizedBox();
                          }

                          int admins =

                              adminSnapshot
                                  .data!
                                  .docs
                                  .length;

                          return Row(

                            children:[

                              Expanded(

                                child:

                                overviewCard(

                                  context,

                                  "Students",

                                  students
                                      .toString(),

                                  "Active",

                                  Colors.green,
                                ),
                              ),

                              const SizedBox(
                                width:12,
                              ),

                              Expanded(

                                child:

                                overviewCard(

                                  context,

                                  "Teachers",

                                  teachers
                                      .toString(),

                                  "Faculty",

                                  Colors.blue,
                                ),
                              ),

                              const SizedBox(
                                width:12,
                              ),

                              Expanded(

                                child:

                                overviewCard(

                                  context,

                                  "Admins",

                                  admins
                                      .toString(),

                                  "Control",

                                  Colors.red,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
              ),

              const SizedBox(
                height: 30,
              ),

              Text(

                "Admin Modules",

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

                crossAxisCount:
                2,

                childAspectRatio:
                1,

                crossAxisSpacing:
                16,

                mainAxisSpacing:
                16,

                children:[

                  moduleCard(
                    context,
                    "Timetable",
                    Icons.calendar_month,
                    Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TimetableUploadPage(
                            isAdmin: true,
                          ),
                        ),
                      );
                    },
                  ),

                  moduleCard(

                    context,

                    "Fee Collect",

                    Icons.currency_rupee,

                    Colors.green,

                    onTap:(){

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:
                              (_)=>

                          const AdminAnalyticsPage(),
                        ),
                      );
                    },
                  ),

                  moduleCard(

                    context,

                    "Pending",

                    Icons.pending_actions,

                    Colors.red,

                    onTap:(){

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:
                              (_)=>

                          const AdminPendingFeesPage(),
                        ),
                      );
                    },
                  ),

                  moduleCard(

                    context,

                    "Notices",

                    Icons.notifications_active,

                    Colors.orange,

                    onTap:(){

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:
                              (_)=>

                          const AdminNoticesPage(),
                        ),
                      );
                    },
                  ),

                  moduleCard(

                    context,

                    "Verify Docs",

                    Icons.verified_user,

                    Colors.teal,
                  ),
                ],
              ),

              const SizedBox(
                height: 120,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget moduleCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      {
        VoidCallback? onTap,
      }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        decoration:
        BoxDecoration(

          color:
          Theme.of(context)
              .brightness ==
              Brightness.dark
              ? Colors.white
              .withOpacity(.05)
              : Colors.white,

          borderRadius:
          BorderRadius.circular(
            28,
          ),
        ),

        child: Column(

          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            CircleAvatar(

              radius: 34,

              backgroundColor:
              color.withOpacity(.15),

              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Text(title),
          ],
        ),
      ),
    );
  }

  Widget overviewCard(
      BuildContext context,
      String title,
      String value,
      String sub,
      Color color) {

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
            .withOpacity(.05)
            : Colors.white,

        borderRadius:
        BorderRadius.circular(
          28,
        ),
      ),

      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(title),

          const SizedBox(
            height: 10,
          ),

          Text(

            value,

            style: TextStyle(

              fontSize: 28,

              fontWeight:
              FontWeight.bold,

              color: color,
            ),
          ),

          Text(sub),
        ],
      ),
    );
  }

  Widget glassIcon({

    required BuildContext context,

    required IconData icon,

    VoidCallback? onTap,

  }) {

    final isDark =
        Theme.of(context)
            .brightness ==
            Brightness.dark;

    return GestureDetector(

      onTap: onTap,

      child: CircleAvatar(

        radius: 20,

        backgroundColor:
        isDark
            ? Colors.white
            .withOpacity(.08)
            : Colors.white,

        child: Icon(

          icon,

          size: 18,

          color:
          isDark
              ? Colors.white
              : Colors.black,
        ),
      ),
    );
  }

  Widget drawerTile(
      BuildContext context,
      IconData icon,
      String title) {

    return ListTile(

      leading: Icon(icon),

      title: Text(title),

      onTap: () {},
    );
  }
}