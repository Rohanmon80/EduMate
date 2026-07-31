import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';

class AdminNoticesPage extends StatefulWidget {
  const AdminNoticesPage({super.key});

  @override
  State<AdminNoticesPage> createState() =>
      _AdminNoticesPageState();
}

class _AdminNoticesPageState
    extends State<AdminNoticesPage> {

  final TextEditingController searchController =
  TextEditingController();

  final TextEditingController messageController =
  TextEditingController();

  String selectedType =
      "Students";

  String searchText = "";

  List<String> selectedUserIds = [];

  List<String> selectedUserNames = [];



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
                        "Manage Notices",

                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,

                          color:
                          isDark
                              ? Colors.white
                              : const Color(0xFF0B1736),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Create & manage announcements",

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

                      EduMateApp.of(context)
                          ?.toggleTheme();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 35),

              /// CREATE NOTICE
              glassCard(

                isDark:isDark,

                child:

                Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children:[

                  Text(

                  "Direct Message",

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
                  height:20,
                ),

                Row(

                  children:[

                    Expanded(

                      child:

                      ChoiceChip(

                        label:
                        const Text(
                          "Students",
                        ),

                        selected:

                        selectedType
                            ==

                            "Students",

                        onSelected:
                            (_){

                          setState(() {

                            selectedType=
                            "Students";
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      width:10,
                    ),

                    Expanded(

                      child:

                      ChoiceChip(

                        label:
                        const Text(
                          "Teachers",
                        ),

                        selected:

                        selectedType
                            ==

                            "Teachers",

                        onSelected:
                            (_){

                          setState(() {

                            selectedType=
                            "Teachers";
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:20,
                ),

                    TextField(

                      controller:
                      searchController,

                      style:

                      TextStyle(

                        color:

                        isDark

                            ?

                        Colors.white

                            :

                        Colors.black,
                      ),

                      onChanged:(v){

                        setState(() {

                          searchText=

                              v.toLowerCase();
                        });
                      },

                      decoration:

                      InputDecoration(

                        filled:true,

                        fillColor:

                        isDark

                            ?

                        Colors.white
                            .withOpacity(
                          0.08,
                        )

                            :

                        Colors.white
                            .withOpacity(
                          0.25,
                        ),

                        hintText:
                        "Search student / teacher",

                        prefixIcon:

                        const Icon(
                          Icons.search,
                        ),

                        border:

                        OutlineInputBorder(

                          borderRadius:

                          BorderRadius.circular(
                            20,
                          ),

                          borderSide:
                          BorderSide.none,
                        ),
                      ),
                    ),

                const SizedBox(
                  height:20,
                ),

                SizedBox(

                  height:220,

                  child:

                  StreamBuilder<
                      QuerySnapshot>(

                    stream:

                    selectedType
                        ==

                        "Students"

                        ?

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

                        .snapshots()

                        :

                    FirebaseFirestore
                        .instance

                        .collection(
                      "teachers",
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

                      final users =

                      snapshot.data!.docs

                          .where(
                            (e){

                          final data=

                          e.data()

                          as Map<
                              String,
                              dynamic>;

                          return

                            (
                                data["name"]

                                    ??

                                    ""

                            )

                                .toString()

                                .toLowerCase()

                                .contains(
                              searchText,
                            );
                        },
                      )

                          .toList();

                      return ListView.builder(

                        itemCount:
                        users.length,

                        itemBuilder:
                            (
                            context,
                            index,
                            ){

                          final data=

                          users[index]
                              .data()

                          as Map<
                              String,
                              dynamic>;

                          return Container(

                            margin:
                            const EdgeInsets.only(
                              bottom:10,
                            ),

                            decoration:

                            BoxDecoration(

                              color:

                              selectedUserIds
                                  .contains(
                                users[index].id,
                              )

                                  ?

                              Colors.blue
                                  .withOpacity(
                                0.15,
                              )

                                  :

                              Colors.white
                                  .withOpacity(
                                0.05,
                              ),

                              borderRadius:

                              BorderRadius.circular(
                                18,
                              ),
                            ),

                            child:

                            ListTile(

                              leading:

                              CircleAvatar(

                                backgroundColor:
                                Colors.blue
                                    .withOpacity(
                                  0.2,
                                ),

                                child:

                                const Icon(
                                  Icons.person,
                                ),
                              ),

                              title:

                              Text(

                                data["name"]

                                    ??

                                    "User",
                              ),

                              subtitle:

                              Text(

                                data["department"]

                                    ??

                                    "",
                              ),

                              selected:

                              selectedUserIds
                                  .contains(

                                users[index].id,
                              ),

                              onTap:(){

                                setState(() {

                                  if(

                                  selectedUserIds
                                      .contains(

                                    users[index].id,
                                  )

                                  ){

                                    selectedUserIds
                                        .remove(

                                      users[index].id,
                                    );

                                    selectedUserNames
                                        .remove(

                                      data["name"],
                                    );

                                  }

                                  else{

                                    selectedUserIds
                                        .add(

                                      users[index].id,
                                    );

                                    selectedUserNames
                                        .add(

                                      data["name"],
                                    );
                                  }
                                });
                              },
                            ),
                          );


                        },
                      );
                    },
                  ),
                ),

                const SizedBox(
                  height:20,
                ),

                    TextField(

                      controller:
                      messageController,

                      maxLines:4,

                      style:

                      TextStyle(

                        color:

                        isDark

                            ?

                        Colors.white

                            :

                        Colors.black,
                      ),

                      decoration:

                      InputDecoration(

                        filled:true,

                        fillColor:

                        isDark

                            ?

                        Colors.white
                            .withOpacity(
                          0.08,
                        )

                            :

                        Colors.white
                            .withOpacity(
                          0.25,
                        ),

                        hintText:

                        selectedUserNames
                            .isEmpty

                            ?

                        "Select users"

                            :

                        "Message to ${selectedUserNames.length} users",

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

                const SizedBox(
                  height:20,
                ),

                SizedBox(

                  width:
                  double.infinity,

                  height:60,

                  child:

                  ElevatedButton(

                    onPressed:
                        () async {

                          if(
                          selectedUserIds
                              .isEmpty
                          )return;

                          for(
                          int i=0;

                          i<
                              selectedUserIds.length;

                          i++
                          ){

                            await FirebaseFirestore
                                .instance

                                .collection(
                              "direct_messages",
                            )

                                .add({

                              "receiverId":

                              selectedUserIds[i],

                              "receiverName":

                              selectedUserNames[i],

                              "senderId":

                              FirebaseAuth
                                  .instance
                                  .currentUser!
                                  .uid,

                              "message":

                              messageController
                                  .text,

                              "type":
                              selectedType,

                              "isDelivered":
                              true,

                              "isRead":
                              false,

                              "timestamp":

                              FieldValue
                                  .serverTimestamp(),
                            });
                          }

                          messageController.clear();

                          selectedUserIds.clear();

                          selectedUserNames.clear();

                          setState(() {});

                      messageController.clear();

                      ScaffoldMessenger.of(
                        context,
                      )

                          .showSnackBar(

                        const SnackBar(

                          content:
                          Text(
                            "Message Sent",
                          ),
                        ),
                      );
                    },

                    child:

                    const Text(
                      "SEND MESSAGE",
                    ),
                  ),
                ),
                  ],
                ),
              ),

    const SizedBox(
    height:35,
    ),

    Text(

    "Sent Messages",

    style:

    TextStyle(

    fontSize:28,

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
    height:20,
    ),

    StreamBuilder<
    QuerySnapshot>(

    stream:

    FirebaseFirestore
        .instance

        .collection(
    "direct_messages",
    )

        .orderBy(
    "timestamp",

    descending:true,
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

    return const SizedBox();
    }

    return Column(

    children:

    snapshot.data!.docs.map(
    (doc){

    final data=

    doc.data()

    as Map<
    String,
    dynamic>;

    return Padding(

    padding:

    const EdgeInsets.only(
    bottom:14,
    ),

    child:

    noticeTile(

    isDark:isDark,

    notice:{

    "title":

    data[
    "receiverName"
    ]

    ??

    "User",

    "desc":

    data[
    "message"
    ]

    ??

    "",

    "priority":

    data[
    "type"
    ]

    ??

    "",
    },
    ),
    );
    },
    )

        .toList(),
    );
    },
    ),


            ],
          ),
        ),
      ),
    );
  }



  Widget noticeTile({
    required bool isDark,
    required Map<String, dynamic> notice,
  }) {
    Color color = Colors.green;

    if (notice["priority"] == "High") {
      color = Colors.redAccent;
    }

    else if (notice["priority"] ==
        "Medium") {
      color = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: glassCard(

        isDark: isDark,

        child: Row(

          children: [

            Container(
              width: 58,
              height: 58,

              decoration: BoxDecoration(
                color:
                color.withOpacity(0.15),

                borderRadius:
                BorderRadius.circular(18),
              ),

              child: Icon(
                Icons.notifications,
                color: color,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    notice["title"],

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
                    notice["desc"],

                    style: TextStyle(
                      color:
                      isDark
                          ? Colors.white70
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            Column(

              children: [

                Icon(
                  Icons.edit,
                  color: color,
                ),

                const SizedBox(height: 14),

                const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }




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

          padding: const EdgeInsets.all(24),

          decoration: BoxDecoration(

            color:
            isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.35),

            borderRadius:
            BorderRadius.circular(30),

            border: Border.all(
              color:
              Colors.white.withOpacity(0.2),
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
