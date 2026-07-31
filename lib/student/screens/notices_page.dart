import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class NoticesPage extends StatelessWidget {
  const NoticesPage({super.key});

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

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
                        "Notices",

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
                        "Latest updates & announcements",

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


                ],
              ),

              const SizedBox(height: 35),

              /// PINNED NOTICE

              StreamBuilder<DocumentSnapshot>(

                stream:

                FirebaseFirestore
                    .instance

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
                    studentSnapshot,
                    ){

                      if(

                      !studentSnapshot.hasData

                          ||

                          studentSnapshot.data!.data()

                              ==

                              null

                      ){

                        return Center(

                          child:

                          Column(

                            children:[

                              const SizedBox(
                                height:80,
                              ),

                              Icon(

                                Icons.notifications_off,

                                size:70,

                                color:
                                Colors.grey,
                              ),

                              const SizedBox(
                                height:10,
                              ),

                              const Text(

                                "No notices available",
                              ),
                            ],
                          ),
                        );
                      }

                  final student =

                  studentSnapshot
                      .data!
                      .data()

                  as Map<
                      String,
                      dynamic>;
                      print(student);

                      print("Year = ${student["year"]}");
                      print("Department = ${student["department"]}");
                      print("Semester = ${student["semester"]}");
                      print("Section = ${student["section"]}");

                  return StreamBuilder<QuerySnapshot>(

                    stream:

                    FirebaseFirestore
                        .instance

                        .collection(
                      "notices",
                    )

                        .where(

                      "year",

                      isEqualTo:

                      student[
                      "year"
                      ],
                    )

                        .where(

                      "department",

                      isEqualTo:

                      student[
                      "department"
                      ],
                    )

                        .where(

                      "semester",

                      isEqualTo:

                      student[
                      "semester"
                      ],
                    )

                        .where(

                      "section",

                      isEqualTo:

                      student[
                      "section"
                      ],
                    )

                        .orderBy(

                      "date",

                      descending:true,
                    )

                        .snapshots(),

                    builder:
                        (
                        context,
                        snapshot,
                        ){
                          print("Notices found: ${snapshot.data?.docs.length}");

                          if(
                          snapshot.connectionState

                              ==

                              ConnectionState.waiting
                          ){

                            return const Center(

                              child:
                              CircularProgressIndicator(),
                            );
                          }

                          if(
                          snapshot.hasError
                          ){

                            return const Center(

                              child:

                              Text(
                                "Failed to load notices",
                              ),
                            );
                          }

                          if(
                          !snapshot.hasData

                              ||

                              snapshot.data!.docs.isEmpty
                          ){

                            return Center(

                              child:

                              Column(

                                mainAxisAlignment:
                                MainAxisAlignment.center,

                                children:[

                                  Icon(

                                    Icons.notifications_off,

                                    size:70,

                                    color:
                                    Colors.grey,
                                  ),

                                  SizedBox(
                                    height:12,
                                  ),

                                  Text(

                                    "No notices available",

                                    style:

                                    TextStyle(

                                      fontSize:18,

                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(
                                    height:6,
                                  ),

                                  Text(

                                    "Teachers have not posted notices yet",
                                  ),
                                ],
                              ),
                            );
                          }

                      final notices =

                          snapshot
                              .data!
                              .docs;



                      return ListView.builder(

                        shrinkWrap:true,

                        physics:

                        const NeverScrollableScrollPhysics(),

                        itemCount:
                        notices.length,

                        itemBuilder:
                            (
                            context,
                            index,
                            ){

                          final notice =

                          notices[
                          index
                          ]

                              .data()

                          as Map<
                              String,
                              dynamic>;

                          return Padding(

                            padding:

                            const EdgeInsets.only(
                              bottom:22,
                            ),

                            child:

                            noticeCard(

                              isDark:isDark,

                              title:

                              notice[
                              "title"
                              ],

                              description:

                              notice[
                              "description"
                              ],

                              date:

                              notice[
                              "date"
                              ]
                                  .toDate()
                                  .toString(),

                              sender:

                              notice[
                              "sender"
                              ],

                              color:
                              Colors.blue,

                              isPinned:

                              notice[
                              "pinned"
                              ] ?? false,
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget noticeCard({
    required bool isDark,
    required String title,
    required String description,
    required String date,
    required String sender,
    required Color color,
    bool isPinned = false,
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

          padding: const EdgeInsets.all(22),

          decoration: BoxDecoration(

            color:
            isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.35),

            borderRadius:
            BorderRadius.circular(30),

            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              /// TOP ROW
              Row(

                children: [

                  Container(
                    width: 52,
                    height: 52,

                    decoration: BoxDecoration(
                      color:
                      color.withOpacity(0.15),

                      borderRadius:
                      BorderRadius.circular(18),
                    ),

                    child: Icon(
                      isPinned
                          ? Icons.push_pin
                          : Icons.notifications,

                      color: color,
                      size: 28,
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
                          sender,

                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              /// DESCRIPTION
              Text(
                description,

                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,

                  color:
                  isDark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              /// BOTTOM ROW
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children: [

                  Row(
                    children: [

                      Icon(
                        Icons.access_time,

                        size: 18,

                        color:
                        isDark
                            ? Colors.white54
                            : Colors.grey,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        date,

                        style: TextStyle(
                          color:
                          isDark
                              ? Colors.white54
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  Container(

                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(
                      color:
                      color.withOpacity(0.15),

                      borderRadius:
                      BorderRadius.circular(18),
                    ),

                    child: Text(
                      "View PDF",

                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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