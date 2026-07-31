import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabasePage extends StatefulWidget {
  const DatabasePage({super.key});

  @override
  State<DatabasePage> createState() =>
      _DatabasePageState();
}

class _DatabasePageState
    extends State<DatabasePage> {

  String selectedRole =
      "Students";

  String selectedDepartment =
      "All";

  final searchController =
  TextEditingController();

  String searchText = "";

  final departments = [

    "All",

    "CSE",

    "ECE",

    "EEE",

    "CSM",

    "AIML",

    "MBA",

    "BBA",

    "MCA",
  ];

  @override
  Widget build(
      BuildContext context){

    final isDark =

        Theme.of(context)
            .brightness ==

            Brightness.dark;

    return PopScope(

      canPop:false,

      onPopInvoked:(didPop){

        if(
        didPop
        )return;

        Navigator.pop(
          context,
        );
      },

      child:

      Scaffold(

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

        appBar: AppBar(

          automaticallyImplyLeading:
          false,

          elevation:0,

          backgroundColor:
          Colors.transparent,

          title:

          const Text(
            "Database",
          ),
        ),

        body:

        Padding(

          padding:

          const EdgeInsets.all(
            20,
          ),

          child:

          Column(

            children:[

              glassCard(

                isDark:isDark,

                child:

                Row(

                  children:[

                    Expanded(

                      child:

                      DropdownButtonFormField(

                        value:
                        selectedRole,

                        decoration:

                        const InputDecoration(

                          labelText:
                          "Type",

                          border:
                          InputBorder.none,
                        ),

                        items:[

                          "Students",

                          "Teachers",
                        ]

                            .map(

                              (e)=>

                              DropdownMenuItem(

                                value:e,

                                child:
                                Text(e),
                              ),
                        )

                            .toList(),

                        onChanged:(v){

                          setState(() {

                            selectedRole=v!;
                          });
                        },
                      ),
                    ),

                    const SizedBox(
                      width:14,
                    ),

                    Expanded(

                      child:

                      DropdownButtonFormField(

                        value:
                        selectedDepartment,

                        decoration:

                        const InputDecoration(

                          labelText:
                          "Department",

                          border:
                          InputBorder.none,
                        ),

                        items:

                        departments.map(

                              (e)=>

                              DropdownMenuItem(

                                value:e,

                                child:
                                Text(e),
                              ),
                        )

                            .toList(),

                        onChanged:(v){

                          setState(() {

                            selectedDepartment=v!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height:14,
              ),

              glassCard(

                isDark:isDark,

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

                  decoration:

                  const InputDecoration(

                    hintText:
                    "Search name",

                    prefixIcon:

                    Icon(
                      Icons.search,
                    ),

                    border:
                    InputBorder.none,
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

                  selectedRole
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

                    final docs =

                    snapshot
                        .data!
                        .docs

                        .where(
                          (e){

                        final data =

                        e.data()

                        as Map<
                            String,
                            dynamic>;

                        bool depMatch=

                        selectedDepartment
                            ==

                            "All"

                            ?

                        true

                            :

                        data[
                        "department"
                        ]

                            ==

                            selectedDepartment;

                        bool searchMatch=

                        (
                            data[
                            "name"
                            ]

                                ??

                                ""

                        )

                            .toString()

                            .toLowerCase()

                            .contains(
                          searchText,
                        );

                        return

                          depMatch

                              &&

                              searchMatch;
                      },
                    )

                        .toList();

                    if(
                    docs.isEmpty
                    ){

                      return const Center(

                        child:
                        Text(
                          "No Data Found",
                        ),
                      );
                    }

                    return Column(

                      children:[

                        glassCard(

                          isDark:isDark,

                          child:

                          Text(

                            "Total Records : ${docs.length}",

                            style:

                            const TextStyle(

                              fontSize:18,

                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height:14,
                        ),

                        Expanded(

                          child:

                          ListView.builder(

                            itemCount:
                            docs.length,

                            itemBuilder:
                                (
                                context,
                                index,
                                ){

                              final data =

                              docs[index]
                                  .data()

                              as Map<
                                  String,
                                  dynamic>;

                              return Padding(

                                padding:

                                const EdgeInsets.only(
                                  bottom:18,
                                ),

                                child:

                                glassCard(

                                  isDark:isDark,

                                  child:

                                  Column(

                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,

                                    children:[

                                      Row(

                                        children:[

                                          CircleAvatar(

                                            radius:30,

                                            backgroundColor:
                                            Colors.blue,

                                            child:

                                            Text(

                                              (
                                                  data[
                                                  "name"
                                                  ]

                                                      ??

                                                      "U"
                                              )

                                                  .toString()

                                                  .substring(
                                                0,
                                                1,
                                              )

                                                  .toUpperCase(),
                                            ),
                                          ),

                                          const SizedBox(
                                            width:16,
                                          ),

                                          Expanded(

                                            child:

                                            Column(

                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,

                                              children:[

                                                Text(

                                                  data[
                                                  "name"
                                                  ]

                                                      ??

                                                      "-",

                                                  style:

                                                  const TextStyle(

                                                    fontSize:20,

                                                    fontWeight:
                                                    FontWeight.bold,
                                                  ),
                                                ),

                                                Text(

                                                  data[
                                                  "department"
                                                  ]

                                                      ??

                                                      "-",
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height:18,
                                      ),

                                      Wrap(

                                        spacing:10,

                                        runSpacing:10,

                                        children:[

                                          infoChip(

                                            "Phone",

                                            data[
                                            "phone"
                                            ]

                                                ?.toString()

                                                ??

                                                "-",
                                          ),

                                          infoChip(

                                            "Email",

                                            data[
                                            "email"
                                            ]

                                                ??

                                                "-",
                                          ),

                                          if(
                                          selectedRole
                                              ==

                                              "Students"
                                          )

                                            infoChip(

                                              "Year",

                                              (
                                                  data[
                                                  "year"
                                                  ]

                                                      ??

                                                      "-"
                                              )

                                                  .toString(),
                                            ),

                                          if(
                                          selectedRole
                                              ==

                                              "Students"
                                          )

                                            infoChip(

                                              "Section",

                                              data[
                                              "section"
                                              ]

                                                  ??

                                                  "-",
                                            ),

                                          if(
                                          selectedRole
                                              ==

                                              "Students"
                                          )

                                            infoChip(

                                              "Roll",

                                              data[
                                              "rollNumber"
                                              ]

                                                  ??

                                                  "-",
                                            ),

                                          if(
                                          selectedRole
                                              ==

                                              "Teachers"
                                          )

                                            infoChip(

                                              "Qualification",

                                              data[
                                              "qualification"
                                              ]

                                                  ??

                                                  "-",
                                            ),

                                          if(
                                          selectedRole
                                              ==

                                              "Teachers"
                                          )

                                            infoChip(

                                              "Experience",

                                              data[
                                              "experience"
                                              ]

                                                  ?.toString()

                                                  ??

                                                  "-",
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

  Widget glassCard({

    required bool isDark,

    required Widget child,
  }){

    return ClipRRect(

      borderRadius:
      BorderRadius.circular(
        28,
      ),

      child:

      BackdropFilter(

        filter:

        ImageFilter.blur(
          sigmaX:20,
          sigmaY:20,
        ),

        child:

        Container(

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
              0.08,
            )

                :

            Colors.white
                .withOpacity(
              0.5,
            ),

            borderRadius:

            BorderRadius.circular(
              28,
            ),

            border:

            Border.all(
              color:
              Colors.white24,
            ),
          ),

          child:
          child,
        ),
      ),
    );
  }

  Widget infoChip(
      String title,
      String value){

    return Container(

      padding:

      const EdgeInsets.symmetric(

        horizontal:12,
        vertical:8,
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
          16,
        ),
      ),

      child:

      Text(
        "$title : $value",
      ),
    );
  }
}