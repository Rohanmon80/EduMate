import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsPage extends StatelessWidget {

  const AnalyticsPage({
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

      appBar: AppBar(

        backgroundColor:
        Colors.transparent,

        elevation: 0,

        title:
        const Text(
          "Analytics",
        ),
      ),

      body:

      StreamBuilder<
          QuerySnapshot>(

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

          int students =

              snapshot
                  .data!
                  .docs
                  .length;

          return Padding(

            padding:
            const EdgeInsets.all(
              20,
            ),

            child: Column(

              children: [

                statCard(

                  context,

                  "Students",

                  students
                      .toString(),

                  Colors.blue,
                ),

                const SizedBox(
                  height:20,
                ),

                statCard(

                  context,

                  "Teachers",

                  "--",

                  Colors.green,
                ),

                const SizedBox(
                  height:20,
                ),

                statCard(

                  context,

                  "Attendance",

                  "Live",

                  Colors.orange,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget statCard(

      BuildContext context,

      String title,

      String value,

      Color color){

    final bool isDark =

        Theme.of(context)
            .brightness ==

            Brightness.dark;

    return ClipRRect(

      borderRadius:
      BorderRadius.circular(
        30,
      ),

      child: BackdropFilter(

        filter:
        ImageFilter.blur(

          sigmaX:20,

          sigmaY:20,
        ),

        child: Container(

          width:
          double.infinity,

          padding:
          const EdgeInsets.all(
            25,
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

          child: Column(

            children:[

              Text(

                title,

                style:
                TextStyle(

                  fontSize:20,

                  color:

                  isDark

                      ? Colors.white

                      : Colors.black,
                ),
              ),

              const SizedBox(
                height:15,
              ),

              Text(

                value,

                style:
                TextStyle(

                  fontSize:40,

                  fontWeight:
                  FontWeight.bold,

                  color:color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}