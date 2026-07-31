import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPendingFeesPage
    extends StatefulWidget {

  const AdminPendingFeesPage({
    super.key,
  });

  @override
  State<AdminPendingFeesPage>
  createState()

  =>

      _AdminPendingFeesPageState();
}

class _AdminPendingFeesPageState

    extends State<
        AdminPendingFeesPage>{

  final TextEditingController
  searchController=

  TextEditingController();

  String searchText="";

  @override
  Widget build(
      BuildContext context){

    final bool isDark=

        Theme.of(context)
            .brightness

            ==

            Brightness.dark;

    return Scaffold(

      backgroundColor:

      isDark

          ?

      const Color(
        0xFF081120,
      )

          :

      const Color(
        0xFFF4F8FC,
      ),

      body:

      SafeArea(

        child:

        Padding(

          padding:

          const EdgeInsets.all(
            20,
          ),

          child:

          Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,

            children:[

              Text(

                "Pending Fees",

                style:

                TextStyle(

                  fontSize:30,

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

              ClipRRect(

                borderRadius:

                BorderRadius.circular(
                  24,
                ),

                child:

                BackdropFilter(

                  filter:

                  ImageFilter.blur(

                    sigmaX:10,

                    sigmaY:10,
                  ),

                  child:

                  Container(

                    padding:

                    const EdgeInsets.symmetric(
                      horizontal:18,
                    ),

                    decoration:

                    BoxDecoration(

                      color:

                      isDark

                          ?

                      Colors.white
                          .withOpacity(
                        0.08,
                      )

                          :

                      Colors.white
                          .withOpacity(
                        0.7,
                      ),

                      borderRadius:

                      BorderRadius.circular(
                        24,
                      ),
                    ),

                    child:

                    TextField(

                      controller:
                      searchController,

                      onChanged:(v){

                        setState(() {

                          searchText=

                              v
                                  .toLowerCase();
                        });
                      },

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

                      const InputDecoration(

                        border:
                        InputBorder.none,

                        hintText:
                        "Search Roll Number",

                        prefixIcon:

                        Icon(
                          Icons.search,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height:20,
              ),

              Expanded(

                child:

                StreamBuilder<
                    QuerySnapshot>(

                  stream:

                  FirebaseFirestore
                      .instance

                      .collection(
                    "users",
                  )

                      .where(

                    "feeDue",

                    isGreaterThan:0,
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

                    final students=

                    snapshot.data!.docs

                        .where(
                          (doc){

                        final data=

                        doc.data()

                        as Map<
                            String,
                            dynamic>;

                        return

                          (
                              data[
                              "rollNumber"
                              ]

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

                    if(
                    students.isEmpty
                    ){

                      return const Center(

                        child:

                        Text(
                          "No Pending Fees",
                        ),
                      );
                    }

                    return ListView.builder(

                      itemCount:
                      students.length,

                      itemBuilder:
                          (
                          context,
                          index,
                          ){

                        final data=

                        students[index]
                            .data()

                        as Map<
                            String,
                            dynamic>;

                        return Container(

                          margin:

                          const EdgeInsets.only(
                            bottom:14,
                          ),

                          padding:

                          const EdgeInsets.all(
                            18,
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
                              22,
                            ),
                          ),

                          child:

                          Column(

                            crossAxisAlignment:
                            CrossAxisAlignment.start,

                            children:[

                              Text(

                                data["name"]

                                    ??

                                    "Student",

                                style:

                                TextStyle(

                                  fontSize:18,

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
                                height:8,
                              ),

                              Text(

                                "Roll No : ${data["rollNumber"]}",
                              ),

                              Text(

                                "Department : ${data["department"]}",
                              ),

                              Text(

                                "Pending : ₹${data["feeDue"]}",

                                style:

                                const TextStyle(

                                  color:
                                  Colors.red,

                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}