import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';

class ReceiptsPage extends StatelessWidget {
  const ReceiptsPage({super.key});

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
                        "Fee Receipts",

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
                        "Payments & transactions",

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

              /// SUMMARY CARD
              glassCard(

                isDark: isDark,

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,


                ),
              ),

              const SizedBox(height: 35),

              Text(
                "Payment History",

                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,

                  color:
                  isDark
                      ? Colors.white
                      : Colors.black,
                ),
              ),

              StreamBuilder<
                  DocumentSnapshot>(

                stream:

                FirebaseFirestore
                    .instance

                    .collection(
                    "users")

                    .doc(

                    FirebaseAuth
                        .instance
                        .currentUser!
                        .uid)

                    .snapshots(),

                builder:
                    (context,userSnap){

                  if(
                  !userSnap.hasData
                  ){

                    return const SizedBox();
                  }

                  final student=

                  userSnap.data!
                      .data()

                  as Map<
                      String,
                      dynamic>;

                  return StreamBuilder<
                      QuerySnapshot>(

                    stream:

                    FirebaseFirestore
                        .instance

                        .collection(
                        "fee_receipts")

                        .where(

                        "rollNumber",

                        isEqualTo:

                        student[
                        "rollNumber"
                        ])

                        .snapshots(),

                    builder:
                        (context,snapshot){

                      if(
                      !snapshot.hasData
                      ){

                        return const SizedBox();
                      }

                      final receipts=

                          snapshot
                              .data!
                              .docs;

                      return Column(

                        children:

                        receipts.map(

                              (e){

                            final r=

                            e.data()

                            as Map<
                                String,
                                dynamic>;

                            return receiptTile(

                              isDark:
                              isDark,

                              receiptUrl:

                              r[
                              "receiptUrl"
                              ] ?? "",

                              title:

                              r[
                              "title"
                              ],

                              amount:

                              "₹${r["amount"]}",

                              status:

                              r[
                              "status"
                              ],

                              date:

                              r[
                              "date"
                              ],

                              paymentMode:
                              r["paymentMode"],

                              transactionId:

                              r[
                              "transactionId"
                              ],

                              color:

                              r[
                              "status"
                              ]

                                  =="PAID"

                                  ?

                              Colors.green

                                  :

                              Colors.redAccent,
                            );
                          },
                        ).toList(),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              StreamBuilder<DocumentSnapshot>(

                stream:

                FirebaseFirestore
                    .instance

                    .collection(
                    "users")

                    .doc(

                    FirebaseAuth
                        .instance
                        .currentUser!
                        .uid)

                    .snapshots(),

                builder:
                    (context,userSnap){

                  if(
                  !userSnap.hasData ||

                      !userSnap.data!
                          .exists
                  ){

                    return const SizedBox();
                  }

                  final student=

                  userSnap.data!
                      .data()

                  as Map<
                      String,
                      dynamic>;

                  return StreamBuilder<
                      QuerySnapshot>(

                    stream:

                    FirebaseFirestore
                        .instance

                        .collection(
                        "fee_receipts")

                        .where(

                        "rollNumber",

                        isEqualTo:

                        student[
                        "rollNumber"
                        ])

                        .snapshots(),

                    builder:
                        (context,snapshot){

                      if(
                      !snapshot.hasData
                      ){

                        return const SizedBox();
                      }

                      double paid=0;

                      double pending=0;

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

                        paid +=

                            (data[
                            "amount"
                            ] ??0)

                                .toDouble();

                        pending =

                            (data[
                            "pending"
                            ]

                                ??

                                0)
                                .toDouble();
                      }

                      return Row(

                        children:[

                          Expanded(

                            child:

                            amountBox(

                              title:
                              "Paid",

                              value:
                              "₹${paid.toStringAsFixed(0)}",

                              color:
                              Colors.green,
                            ),
                          ),

                          const SizedBox(
                            width:16,
                          ),

                          Expanded(

                            child:

                            amountBox(

                              title:
                              "Pending",

                              value:
                              "₹${pending.toStringAsFixed(0)}",

                              color:
                              Colors.redAccent,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 35),

              /// PAY BUTTON
              SizedBox(
                width: double.infinity,
                height: 62,

                child: ElevatedButton(

                  onPressed: () {},

                  style: ElevatedButton.styleFrom(

                    backgroundColor:
                    const Color(0xFF008CFF),

                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(22),
                    ),
                  ),

                  child: const Text(
                    "Pay Pending Fees",

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
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

  Widget amountBox({
    required String title,
    required String value,
    required Color color,
  }) {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color:
        color.withOpacity(0.15),

        borderRadius:
        BorderRadius.circular(22),
      ),

      child: Column(

        children: [

          Text(
            title,

            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            value,

            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget receiptTile({
    required bool isDark,
    required String receiptUrl,
    required String title,
    required String amount,
    required String status,
    required String date,
    required String paymentMode,
    required String transactionId,
    required Color color,
  }) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),

      child: glassCard(

        isDark: isDark,

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            Row(

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
                    Icons.receipt_long,
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
                        date,

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

                Container(

                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),

                  decoration: BoxDecoration(
                    color:
                    color.withOpacity(0.15),

                    borderRadius:
                    BorderRadius.circular(18),
                  ),

                  child: Text(
                    status,

                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,

              children: [

                Text(
                  amount,

                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,

                    color:
                    isDark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),

                GestureDetector(

                  onTap: () async {

                    await launchUrl(

                      Uri.parse(
                        receiptUrl,
                      ),
                    );
                  },

                  child:

                  Container(

                    padding:

                    const EdgeInsets
                        .symmetric(

                      horizontal:16,

                      vertical:10,
                    ),

                    decoration:
                    BoxDecoration(

                      color:

                      Colors.blue
                          .withOpacity(
                          0.15),

                      borderRadius:

                      BorderRadius.circular(
                          18),
                    ),

                    child:
                    const Text(

                      "Download",

                      style:
                      TextStyle(

                        color:
                        Colors.blue,
                      ),
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 14),

            Text(
              "Transaction ID: $transactionId",

              style: TextStyle(
                color:
                isDark
                    ? Colors.white54
                    : Colors.grey,
              ),
            ),

            const SizedBox(
              height:6,
            ),

            Text(

              "Mode: $paymentMode",

              style:

              TextStyle(

                color:

                isDark

                    ? Colors.white70

                    : Colors.grey,
              ),
            ),
          ],
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