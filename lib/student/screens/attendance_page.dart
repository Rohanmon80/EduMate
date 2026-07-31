import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AttendancePage
    extends StatefulWidget {

  const AttendancePage({
    super.key,
  });

  @override
  State<AttendancePage>
  createState() =>
      _AttendancePageState();
}

class _AttendancePageState
    extends State<AttendancePage>{

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

      body: SingleChildScrollView(

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

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

                  final data =

                  snapshot.data!
                      .data()

                  as Map<
                      String,
                      dynamic>;

                  double attendance =

                  (data[
                  "attendance"
                  ] ??
                      0)

                      .toDouble();

                  return Container(

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

                          ? const Color(
                        0xFF16213E,
                      )

                          : Colors.white,

                      borderRadius:
                      BorderRadius.circular(
                        30,
                      ),

                      boxShadow:[

                        BoxShadow(

                          color:
                          Colors.black
                              .withOpacity(
                            0.05,
                          ),

                          blurRadius:
                          20,

                          offset:
                          const Offset(
                            0,
                            10,
                          ),
                        ),
                      ],
                    ),

                    child:
                    Column(

                      children:[

                        Text(

                          "Overall Attendance",

                          style:
                          TextStyle(

                            fontSize:22,

                            color:

                            isDark

                                ? Colors.white70

                                : Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          height:15,
                        ),

                        StreamBuilder<QuerySnapshot>(

                          stream:

                          FirebaseFirestore
                              .instance

                              .collection(
                              "attendance_history")

                              .where(

                              "studentId",

                              isEqualTo:

                              FirebaseAuth
                                  .instance
                                  .currentUser!
                                  .uid)

                              .orderBy(
                              "date",
                              descending:true)

                              .limit(1)

                              .snapshots(),

                          builder:
                              (
                              context,
                              snapshot
                              ){

                            if(
                            !snapshot.hasData ||

                                snapshot
                                    .data!
                                    .docs
                                    .isEmpty
                            ){

                              return const SizedBox();
                            }

                            final data=

                            snapshot
                                .data!
                                .docs
                                .first
                                .data()

                            as Map<
                                String,
                                dynamic>;

                            return Card(

                              child:
                              Padding(

                                padding:
                                const EdgeInsets
                                    .all(
                                    15),

                                child:
                                Text(

                                  "${data["subject"]} attendance marked",

                                ),
                              ),
                            );
                          },
                        ),

                        Text(

                          "${attendance.toStringAsFixed(1)}%",

                          style:
                          TextStyle(

                            fontSize:48,

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
                          height:10,
                        ),

                        ClipRRect(

                          borderRadius:
                          BorderRadius.circular(
                            20,
                          ),

                          child:
                          LinearProgressIndicator(

                            value:
                            attendance / 100,

                            minHeight:
                            14,

                            backgroundColor:
                            Colors.grey
                                .shade300,

                            color:
                            Colors.green,
                          ),
                        ),

                        const SizedBox(
                          height:15,
                        ),

                        Text(

                          attendance >= 75

                              ? "Great! Your attendance is above target."

                              : "Attendance below target",

                          style:
                          const TextStyle(

                            color:
                            Colors.green,

                            fontSize:16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              /// GRAPH CARD
              Container(

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(

                  color:
                  isDark
                      ? const Color(0xFF16213E)
                      : Colors.white,

                  borderRadius:
                  BorderRadius.circular(30),

                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.black.withOpacity(0.05),

                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      "Weekly Attendance",

                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,

                        color:
                        isDark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 25),

                    StreamBuilder<QuerySnapshot>(

                      stream:

                      FirebaseFirestore
                          .instance

                          .collection(
                          "attendance_history")

                          .where(

                          "studentId",

                          isEqualTo:

                          FirebaseAuth
                              .instance
                              .currentUser!
                              .uid)

                          .snapshots(),

                      builder:
                          (
                          context,
                          snapshot
                          ){

                        if(
                        !snapshot.hasData
                        ){

                          return const SizedBox();
                        }

                        List<double>
                        present=

                        List.filled(
                            5,
                            0);

                        List<int>
                        total=

                        List.filled(
                            5,
                            0);

                        for(

                        var d

                        in snapshot
                            .data!
                            .docs

                        ){

                          final data=

                          d.data()

                          as Map<
                              String,
                              dynamic>;

                          int day=

                              data[
                              "day"
                              ] - 1;

                          if(
                          day < 5
                          ){

                            total[
                            day
                            ]++;

                            if(
                            data[
                            "present"
                            ] ==
                                true
                            ){

                              present[
                              day
                              ]++;
                            }
                          }
                        }

                        return Row(

                          mainAxisAlignment:

                          MainAxisAlignment
                              .spaceAround,

                          crossAxisAlignment:

                          CrossAxisAlignment
                              .end,

                          children:[

                            graphBar(

                                "Mon",

                                total[0]==0

                                    ?0

                                    :

                                present[0]
                                    /

                                    total[0]),

                            graphBar(

                                "Tue",

                                total[1]==0

                                    ?0

                                    :

                                present[1]
                                    /

                                    total[1]),

                            graphBar(

                                "Wed",

                                total[2]==0

                                    ?0

                                    :

                                present[2]
                                    /

                                    total[2]),

                            graphBar(

                                "Thu",

                                total[3]==0

                                    ?0

                                    :

                                present[3]
                                    /

                                    total[3]),

                            graphBar(

                                "Fri",

                                total[4]==0

                                    ?0

                                    :

                                present[4]
                                    /

                                    total[4]),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Text(
                "Subject Attendance",

                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,

                  color:
                  isDark
                      ? Colors.white
                      : const Color(0xFF0B1736),
                ),
              ),

              const SizedBox(height: 20),

              StreamBuilder<QuerySnapshot>(

                stream:

                FirebaseFirestore
                    .instance

                    .collection(
                    "attendance_history")

                    .where(

                    "studentId",

                    isEqualTo:

                    FirebaseAuth
                        .instance
                        .currentUser!
                        .uid)

                    .snapshots(),

                builder:
                    (
                    context,
                    snapshot
                    ){

                  if(
                  !snapshot.hasData
                  ){

                    return const SizedBox();
                  }

                  Map<String,int>
                  total={};

                  Map<String,int>
                  present={};

                  for(

                  var d

                  in snapshot
                      .data!
                      .docs

                  ){

                    final data=

                    d.data()

                    as Map<
                        String,
                        dynamic>;

                    String subject=

                        data[
                        "subject"
                        ] ??
                            "Unknown";

                    total[
                    subject
                    ]=

                        (
                            total[
                            subject
                            ] ??
                                0
                        ) +1;

                    if(
                    data[
                    "present"
                    ]==
                        true
                    ){

                      present[
                      subject
                      ]=

                          (
                              present[
                              subject
                              ] ??
                                  0
                          ) +1;
                    }
                  }

                  return Column(

                    children:

                    total.keys.map(

                          (s){

                        double p=

                        total[s]==0

                            ?0

                            :

                        (
                            present[s]
                                ??

                                0
                        )

                            /

                            total[s]!

                            *100;

                        return attendanceTile(

                          isDark:
                          isDark,

                          subject:
                          s,

                          percent:

                          "${p.toStringAsFixed(1)}%",

                          color:
                          Colors.blue,
                        );
                      },
                    ).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget graphBar(String day, double value) {

    return Column(

      children: [

        Container(
          width: 30,
          height: 140 * value,

          decoration: BoxDecoration(
            color: Colors.blue,

            borderRadius:
            BorderRadius.circular(20),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          day,

          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget attendanceTile({
    required bool isDark,
    required String subject,
    required String percent,
    required Color color,
  }) {

    return Container(

      margin: const EdgeInsets.only(bottom: 18),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color:
        isDark
            ? const Color(0xFF16213E)
            : Colors.white,

        borderRadius:
        BorderRadius.circular(25),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceBetween,

        children: [

          Text(
            subject,

            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,

              color:
              isDark
                  ? Colors.white
                  : Colors.black,
            ),
          ),

          Container(

            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),

            decoration: BoxDecoration(
              color: color.withOpacity(0.12),

              borderRadius:
              BorderRadius.circular(20),
            ),

            child: Text(
              percent,

              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}