import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class AdminStudentManagementPage
    extends StatefulWidget {

  const AdminStudentManagementPage({
    super.key,
  });

  @override
  State<AdminStudentManagementPage>
  createState() =>
      _AdminStudentManagementPageState();
}

class _AdminStudentManagementPageState
    extends State<
        AdminStudentManagementPage> {

  final TextEditingController
  searchController =
  TextEditingController();



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

      floatingActionButton:

      Padding(

        padding:
        const EdgeInsets.only(
          bottom: 75,
        ),

        child:

        FloatingActionButton(

          backgroundColor:
          const Color(
            0xFF008CFF,
          ),

          onPressed: () {},

          child:
          const Icon(

            Icons.add,

            color:
            Colors.white,
          ),
        ),
      ),

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
                        "Students",

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
                        "Manage student records",

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

              /// SEARCH
              TextField(

                controller:
                searchController,

                style: TextStyle(
                  color:
                  isDark
                      ? Colors.white
                      : Colors.black,
                ),

                decoration:
                InputDecoration(

                  filled: true,

                  fillColor:
                  isDark
                      ? Colors.white
                      .withOpacity(
                    0.08,
                  )
                      : Colors.white
                      .withOpacity(
                    0.35,
                  ),

                  hintText:
                  "Search student...",

                  hintStyle: TextStyle(
                    color:
                    isDark
                        ? Colors.white70
                        : Colors.grey,
                  ),

                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.blue,
                  ),

                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      22,
                    ),

                    borderSide:
                    BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              /// STUDENTS LIST

              StreamBuilder<QuerySnapshot>(

                stream:

                FirebaseFirestore
                    .instance

                    .collection(
                  "users",
                )

                    .where(
                  "role",
                  isEqualTo:
                  "student",
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

                  return Column(

                    children:

                    snapshot
                        .data!
                        .docs

                        .map(
                          (doc){

                        final student =

                        doc.data()
                        as Map<String,dynamic>;

                        return studentTile(

                          isDark:isDark,

                          student:{

                            "name":
                            student["name"]
                                ?? "",

                            "roll":
                            student["rollNumber"]
                                ?? "",

                            "branch":
                            student["department"]
                                ?? "",

                            "cgpa":

                            student["cgpa"]
                                .toString(),

                            "attendance":

                            student["attendance"]
                                .toString(),
                          },
                        );
                      },
                    )

                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget studentTile({
    required bool isDark,
    required Map<String, dynamic>
    student,
  }) {

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 18,
      ),

      child: glassCard(

        isDark: isDark,

        child: Column(
          children: [

            Row(

              children: [

                Container(
                  width: 62,
                  height: 62,

                  decoration:
                  BoxDecoration(
                    color:
                    Colors.blue
                        .withOpacity(
                      0.15,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),

                  child: const Icon(
                    Icons.person,
                    color: Colors.blue,
                    size: 32,
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
                        student["name"],

                        style: TextStyle(
                          fontSize: 20,
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
                        student["roll"],

                        style: TextStyle(
                          color:
                          isDark
                              ? Colors
                              .white70
                              : Colors.grey,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        student["branch"],

                        style: const TextStyle(
                          color:
                          Colors.blue,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(

                  children: [

                    Icon(
                      Icons.edit,
                      color:
                      Colors.orange,
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    const Icon(
                      Icons.delete,
                      color:
                      Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 22),

            Row(

              children: [

                Expanded(
                  child: infoCard(
                    title:
                    "Attendance",
                    value:
                    student[
                    "attendance"],
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
                    student[
                    "cgpa"],
                    color:
                    Colors.blue,
                  ),
                ),
              ],
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

            style: TextStyle(
              fontSize: 24,
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
          const EdgeInsets.all(24),

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
                color:
                Colors.white24,
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