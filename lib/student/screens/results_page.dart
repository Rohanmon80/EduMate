import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultsPage extends StatelessWidget {

  const ResultsPage({
    super.key,
  });

  @override
  Widget build(
      BuildContext context){

    final isDark=

        Theme.of(context)
            .brightness==

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

      appBar: AppBar(

        backgroundColor:
        Colors.transparent,

        elevation:0,

        title:
        const Text(
          "Results",
        ),
      ),

      body:

      StreamBuilder<
          QuerySnapshot>(

        stream: FirebaseFirestore.instance
            .collection("student_marks")
            .where(
          "studentId",
          isEqualTo: FirebaseAuth.instance.currentUser!.uid,
        )
            .limit(1)
            .snapshots(),

        builder:
            (
            context,
            snapshot
            ){

          if(
          !snapshot.hasData
          ){

            return const Center(

              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.docs.isEmpty){

            return const Center(

              child:
              Text(
                "No Marks Uploaded",
              ),
            );
          }

          final marks=

          snapshot
              .data!
              .docs.first.data()

          as Map<
              String,
              dynamic>;

          return ListView(

            padding:
            const EdgeInsets.all(
              20,
            ),

            children:[

              markCard(

                context,

                "Mid 1",

                marks[
                "Mid 1"
                ] ??

                    "--",
              ),

              markCard(

                context,

                "Mid 2",

                marks[
                "Mid 2"
                ] ??

                    "--",
              ),

              markCard(

                context,

                "Sem External 1",

                marks[
                "Sem External 1"
                ] ??

                    "--",
              ),

              markCard(

                context,

                "Sem External 2",

                marks[
                "Sem External 2"
                ] ??

                    "--",
              ),

              markCard(

                context,

                "Lab Internal 1",

                marks[
                "Lab Internal 1"
                ] ??

                    "--",
              ),

              markCard(

                context,

                "Lab Internal 2",

                marks[
                "Lab Internal 2"
                ] ??

                    "--",
              ),

              markCard(

                context,

                "Lab External",

                marks[
                "Lab External"
                ] ??

                    "--",
              ),
            ],
          );
        },
      ),
    );
  }

  Widget markCard(

      BuildContext context,

      String title,

      dynamic value){

    final isDark=

        Theme.of(context)
            .brightness==

            Brightness.dark;

    return Container(

      margin:
      const EdgeInsets.only(
        bottom:20,
      ),

      padding:
      const EdgeInsets.all(
        20,
      ),

      decoration:
      BoxDecoration(

        color:

        isDark

            ? Colors.white
            .withOpacity(
          .06,
        )

            : Colors.white,

        borderRadius:
        BorderRadius.circular(
          30,
        ),
      ),

      child:
      Row(

        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,

        children:[

          Text(

            title,

            style:
            const TextStyle(

              fontSize:18,

              fontWeight:
              FontWeight.bold,
            ),
          ),

          Text(

            value.toString(),

            style:
            const TextStyle(

              fontSize:22,

              color:
              Colors.blue,

              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}