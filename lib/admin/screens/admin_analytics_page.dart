import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../main.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {

    final isDark =
        Theme.of(context).brightness ==
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

      body: SafeArea(

        child:

        StreamBuilder<QuerySnapshot>(

          stream:

          FirebaseFirestore
              .instance

              .collection(
            "fee_receipts",
          )

              .where(
            "status",
            isEqualTo:
            "paid",
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
                snapshot.data!.docs;

            DateTime now =
            DateTime.now();

            double todayAmount = 0;

            double weekAmount = 0;

            double monthAmount = 0;

            int todayStudents = 0;

            int weekStudents = 0;

            int monthStudents = 0;

            for(
            var doc
            in docs
            ){

              final data =

              doc.data()

              as Map<
                  String,
                  dynamic>;

              if(
              data[
              "timestamp"
              ] == null
              ) continue;

              DateTime date =

              (
                  data[
                  "timestamp"
                  ]

                  as Timestamp

              )

                  .toDate();

              double amount =

              (
                  data[
                  "amount"
                  ]

                      ?? 0

              )

                  .toDouble();

              if(

              date.year
                  ==
                  now.year

                  &&

                  date.month
                      ==
                      now.month

                  &&

                  date.day
                      ==
                      now.day

              ){

                todayAmount +=
                    amount;

                todayStudents++;
              }

              if(

              now
                  .difference(
                date,
              )

                  .inDays

                  <= 7

              ){

                weekAmount +=
                    amount;

                weekStudents++;
              }

              if(

              date.year
                  ==
                  now.year

                  &&

                  date.month
                      ==
                      now.month

              ){

                monthAmount +=
                    amount;

                monthStudents++;
              }
            }

            return SingleChildScrollView(

              padding:

              const EdgeInsets.all(
                20,
              ),

              child:

              Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children:[

                  Row(

                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,

                    children:[

                      glassIcon(

                        isDark:isDark,

                        icon:
                        Icons.arrow_back,

                        onTap:(){

                          Navigator.pop(
                            context,
                          );
                        },
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

                              "Fee Analytics",

                              style:

                              TextStyle(

                                fontSize:32,

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

                            const Text(
                              "Live payment overview",
                            ),
                          ],
                        ),
                      ),

                      glassIcon(

                        isDark:isDark,

                        icon:

                        isDark

                            ?

                        Icons.light_mode

                            :

                        Icons.dark_mode,

                        onTap:(){

                          EduMateApp
                              .of(
                            context,
                          )

                              ?.toggleTheme();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(
                    height:30,
                  ),

                  GridView.count(

                    shrinkWrap:true,

                    physics:

                    const NeverScrollableScrollPhysics(),

                    crossAxisCount:2,

                    crossAxisSpacing:16,

                    mainAxisSpacing:16,

                    children:[

                      analyticsCard(

                        isDark,

                        "Today Fees",

                        "₹${todayAmount.toInt()}",

                        Icons.today,

                        Colors.green,
                      ),

                      analyticsCard(

                        isDark,

                        "Week Fees",

                        "₹${weekAmount.toInt()}",

                        Icons.calendar_view_week,

                        Colors.blue,
                      ),

                      analyticsCard(

                        isDark,

                        "Month Fees",

                        "₹${monthAmount.toInt()}",

                        Icons.calendar_month,

                        Colors.orange,
                      ),

                      analyticsCard(

                        isDark,

                        "Paid Students",

                        monthStudents
                            .toString(),

                        Icons.people,

                        Colors.purple,
                      ),
                    ],
                  ),

                  const SizedBox(
                    height:30,
                  ),

                  glassCard(

                    isDark,

                    Column(

                      children:[

                        summaryRow(

                          isDark,

                          "Today Paid Students",

                          todayStudents
                              .toString(),
                        ),

                        summaryRow(

                          isDark,

                          "Week Paid Students",

                          weekStudents
                              .toString(),
                        ),

                        summaryRow(

                          isDark,

                          "Month Paid Students",

                          monthStudents
                              .toString(),
                        ),

                        summaryRow(

                          isDark,

                          "Month Collection",

                          "₹${monthAmount.toInt()}",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height:100,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

// keep your old analyticsCard()
// keep glassCard()
// keep summaryRow()
// keep glassIcon()

}
  Widget analyticsCard(
      bool isDark,
      String titleText,
      String value,
      IconData icon,
      Color color,
      ) {

    return glassCard(

      isDark,

      SizedBox(

        height: 110,

        child: Column(

          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            CircleAvatar(

              radius: 22,

              backgroundColor:
              color.withOpacity(.15),

              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(

              value,

              style: TextStyle(

                fontSize: 22,

                fontWeight:
                FontWeight.bold,

                color: color,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Flexible(

              child: Text(

                titleText,

                textAlign:
                TextAlign.center,

                maxLines: 2,

                overflow:
                TextOverflow.ellipsis,

                style: TextStyle(

                  fontSize: 10,

                  color:
                  isDark
                      ? Colors.white70
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget departmentTile(
      bool isDark,
      String dep,
      String per,
      Color color,
      ) {

    return Padding(

      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),

      child: glassCard(

        isDark,

        Row(

          children: [

            CircleAvatar(

              backgroundColor:
              color.withOpacity(.15),

              child: Icon(
                Icons.analytics,
                color: color,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(

              child: Text(

                dep,

                style: TextStyle(

                  fontWeight:
                  FontWeight.bold,

                  color:
                  isDark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),

            Text(

              per,

              style: TextStyle(
                color: color,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget summaryRow(
      bool isDark,
      String t,
      String v,
      ) {

    return Padding(

      padding:
      const EdgeInsets.only(
        bottom: 14,
      ),

      child: Row(

        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,

        children: [

          Text(
            t,
            style: TextStyle(
              color:
              isDark
                  ? Colors.white
                  : Colors.black,
            ),
          ),

          Text(
            v,
            style: TextStyle(
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
    );
  }

  Widget title(
      bool isDark,
      String text,
      ) {

    return Text(

      text,

      style: TextStyle(

        fontSize: 24,

        fontWeight:
        FontWeight.bold,

        color:
        isDark
            ? Colors.white
            : Colors.black,
      ),
    );
  }

  Widget glassCard(
      bool isDark,
      Widget child,
      ) {

    return Container(

      padding:
      const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color:
        isDark
            ? Colors.white
            .withOpacity(.06)
            : Colors.white,

        borderRadius:
        BorderRadius.circular(
          24,
        ),
      ),

      child: child,
    );
  }

  Widget glassIcon({

    required bool isDark,
    required IconData icon,
    VoidCallback? onTap,

  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        width: 52,
        height: 52,

        decoration:
        BoxDecoration(

          color:
          isDark
              ? Colors.white
              .withOpacity(.08)
              : Colors.white,

          borderRadius:
          BorderRadius.circular(
            16,
          ),
        ),

        child: Icon(

          icon,

          color:
          isDark
              ? Colors.white
              : Colors.black,
        ),
      ),
    );
  }
