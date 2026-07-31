import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherCertificateReviewPage
    extends StatefulWidget{

  const TeacherCertificateReviewPage({
    super.key,
  });

  @override
  State<TeacherCertificateReviewPage>
  createState()=>

      _TeacherCertificateReviewPageState();
}

class _TeacherCertificateReviewPageState
    extends State<TeacherCertificateReviewPage>{

  final commentController=
  TextEditingController();

  @override
  Widget build(
      BuildContext context){

    final isDark =

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

      appBar:AppBar(

        backgroundColor:
        Colors.transparent,

        title:

        const Text(
          "Student Certificates",
        ),
      ),

      body:

      StreamBuilder<QuerySnapshot>(

        stream:

        FirebaseFirestore
            .instance

            .collection(
          "certificates",
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

          if(
          !snapshot.hasData
          ){

            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          final certificates=

              snapshot.data!.docs;

          if(
          certificates.isEmpty
          ){

            return const Center(

              child:
              Text(
                "No certificates uploaded",
              ),
            );
          }

          return ListView.builder(

            padding:
            const EdgeInsets.all(
              20,
            ),

            itemCount:
            certificates.length,

            itemBuilder:
                (
                context,
                index,
                ){

              final cert=

              certificates[index];

              final data=

              cert.data()

              as Map<
                  String,
                  dynamic>;

              return Padding(

                padding:

                const EdgeInsets.only(
                  bottom:20,
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

                          Container(

                            width:72,

                            height:72,

                            decoration:

                            BoxDecoration(

                              color:

                              Colors.blue
                                  .withOpacity(
                                0.15,
                              ),

                              borderRadius:

                              BorderRadius.circular(
                                22,
                              ),
                            ),

                            child:

                            const Icon(

                              Icons.workspace_premium,

                              color:
                              Colors.blue,

                              size:40,
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

                                  data["title"],

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

                                const SizedBox(
                                  height:5,
                                ),

                                Text(

                                  data["organization"],

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
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:18,
                      ),

                      Text(

                        data["description"],

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

                      const SizedBox(
                        height:20,
                      ),

                      Row(

                        children:[

                          GestureDetector(

                            onTap:
                                () async {

                              await FirebaseFirestore
                                  .instance

                                  .collection(
                                "certificates",
                              )

                                  .doc(
                                cert.id,
                              )

                                  .update({

                                "likes":

                                FieldValue.increment(
                                  1,
                                ),
                              });
                            },

                            child:

                            Container(

                              padding:

                              const EdgeInsets.symmetric(

                                horizontal:18,

                                vertical:10,
                              ),

                              decoration:

                              BoxDecoration(

                                color:

                                Colors.red
                                    .withOpacity(
                                  0.12,
                                ),

                                borderRadius:

                                BorderRadius.circular(
                                  16,
                                ),
                              ),

                              child:

                              Row(

                                children:[

                                  const Icon(

                                    Icons.favorite,

                                    color:
                                    Colors.red,
                                  ),

                                  const SizedBox(
                                    width:8,
                                  ),

                                  Text(

                                    "${data["likes"]}",

                                    style:

                                    const TextStyle(

                                      fontWeight:
                                      FontWeight.bold,

                                      color:
                                      Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            width:16,
                          ),

                          Expanded(

                            child:

                            TextField(

                              controller:
                              commentController,

                              decoration:

                              InputDecoration(

                                hintText:
                                "Add comment",

                                filled:true,

                                fillColor:

                                isDark

                                    ?

                                Colors.white
                                    .withOpacity(
                                  0.08,
                                )

                                    :

                                Colors.white,

                                border:

                                OutlineInputBorder(

                                  borderRadius:

                                  BorderRadius.circular(
                                    16,
                                  ),

                                  borderSide:
                                  BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:18,
                      ),

                      SizedBox(

                        width:
                        double.infinity,

                        height:50,

                        child:

                        ElevatedButton(

                          onPressed:
                              () async {

                            if(
                            commentController
                                .text
                                .isEmpty
                            ){

                              return;
                            }

                            await FirebaseFirestore
                                .instance

                                .collection(
                              "certificate_comments",
                            )

                                .add({

                              "certificateId":
                              cert.id,

                              "teacherId":

                              FirebaseAuth
                                  .instance
                                  .currentUser!
                                  .uid,

                              "comment":

                              commentController.text,

                              "date":

                              Timestamp.now(),
                            });

                            commentController.clear();
                          },

                          style:

                          ElevatedButton.styleFrom(

                            backgroundColor:

                            const Color(
                              0xFF008CFF,
                            ),

                            shape:

                            RoundedRectangleBorder(

                              borderRadius:

                              BorderRadius.circular(
                                18,
                              ),
                            ),
                          ),

                          child:

                          const Text(

                            "Send Comment",

                            style:

                            TextStyle(
                              color:
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
              0.4,
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
}