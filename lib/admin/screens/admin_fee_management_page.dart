import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../main.dart';

class AdminFeeManagementPage extends StatefulWidget {
  const AdminFeeManagementPage({super.key});

  @override
  State<AdminFeeManagementPage> createState() =>
      _AdminFeeManagementPageState();
}

class _AdminFeeManagementPageState
    extends State<AdminFeeManagementPage> {

  final searchController =
  TextEditingController();

  final amountController =
  TextEditingController();

  final modeController =
  TextEditingController();

  final transactionController =
  TextEditingController();

  final titleController =
  TextEditingController(
    text:"Semester Fee",
  );

  @override
  Widget build(
      BuildContext context
      ){

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
          0xFF081120)

          :

      const Color(
          0xFFF4F8FC),

      body:

      SafeArea(

        child:

        SingleChildScrollView(

          padding:

          const EdgeInsets.all(
              20),

          child:

          Column(

            crossAxisAlignment:
            CrossAxisAlignment.start,

            children:[

              Row(

                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

                children:[

                  Column(

                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children:[

                      Text(

                        "Fee Management",

                        style:

                        TextStyle(

                          fontSize:34,

                          fontWeight:
                          FontWeight.bold,

                          color:

                          isDark

                              ?

                          Colors.white

                              :

                          const Color(
                              0xFF0B1736),
                        ),
                      ),

                      const SizedBox(
                          height:6),

                      Text(

                        "Manage fee collections",

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

                  glassIcon(

                    icon:

                    isDark

                        ?

                    Icons.light_mode

                        :

                    Icons.dark_mode,

                    onTap:(){

                      EduMateApp.of(
                          context)

                          ?.toggleTheme();
                    },
                  ),
                ],
              ),

              const SizedBox(
                  height:35),

              TextField(

                controller:
                searchController,

                onChanged:
                    (_){

                  setState(() {});
                },

                decoration:
                InputDecoration(

                  hintText:
                  "Search student...",

                  prefixIcon:
                  const Icon(
                    Icons.search,
                  ),

                  border:

                  OutlineInputBorder(

                    borderRadius:

                    BorderRadius.circular(
                        22),

                    borderSide:
                    BorderSide.none,
                  ),

                  filled:true,
                ),
              ),

              const SizedBox(
                  height:30),

              Text(

                "Student Fee Records",

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
                  height:20),

              StreamBuilder<
                  QuerySnapshot>(

                stream:

                FirebaseFirestore
                    .instance

                    .collection(
                    "users")

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

                    return
                      const Center(

                        child:

                        CircularProgressIndicator(),
                      );
                  }

                  final students =

                  snapshot.data!.docs

                      .where(

                        (doc){

                      final student =

                      doc.data()

                      as Map<
                          String,
                          dynamic>;

                      return student[
                      "rollNumber"]

                          .toString()

                          .toLowerCase()

                          .contains(

                          searchController
                              .text

                              .toLowerCase());
                    },
                  )

                      .toList();

                  return Column(

                    children:

                    students.map(
                          (doc){

                        final student =

                        doc.data()

                        as Map<
                            String,
                            dynamic>;

                        return feeTile(

                          isDark:
                          isDark,

                          student:{

                            "name":

                            student[
                            "name"]

                                ??

                                "",

                            "roll":

                            student[
                            "rollNumber"]

                                ??

                                "",

                            "paid":

                            student[
                            "paidFee"]

                                ??

                                0,

                            "total":

                            student[
                            "totalFee"]

                                ??

                                0,

                            "feesDue":

                            student[
                            "feesDue"]

                                ??

                                0,
                          },
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

  Widget feeTile({

    required bool isDark,

    required Map<
        String,
        dynamic>
    student,

  }){

    return Padding(

      padding:

      const EdgeInsets.only(
          bottom:18),

      child:

      glassCard(

        isDark:isDark,

        child:

        Row(

          children:[

            const Icon(
              Icons.person,
            ),

            const SizedBox(
                width:18),

            Expanded(

              child:

              Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                children:[

                  Text(

                    student[
                    "name"],

                    maxLines:1,

                    overflow:

                    TextOverflow
                        .ellipsis,
                  ),

                  Text(
                    student[
                    "roll"],
                  ),

                  Text(

                    "Paid : ₹${student["paid"]}",

                    style:

                    const TextStyle(
                      color:
                      Colors.green,
                    ),
                  ),

                  Text(

                    "Remaining : ₹${student["feesDue"]}",

                    style:

                    const TextStyle(
                      color:
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ),

            Column(

              children:[

                ElevatedButton(

                  onPressed:(){

                    showSetFeeDialog(
                        student);
                  },

                  child:

                  const Text(
                      "Set Fee"),
                ),

                const SizedBox(
                    height:8),

                ElevatedButton(

                  onPressed:(){

                    showReceiptDialog(
                        student);
                  },

                  child:

                  const Text(
                      "Receipt"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void showSetFeeDialog(
      Map student){

    final feeController =
    TextEditingController();

    showDialog(

      context:context,

      builder:(_){

        return AlertDialog(

          title:
          const Text(
              "Set Total Fee"),

          content:

          TextField(

            controller:
            feeController,

            keyboardType:
            TextInputType.number,
          ),

          actions:[

            TextButton(

              onPressed:
                  () async {

                double total =

                double.parse(
                    feeController.text);

                await FirebaseFirestore
                    .instance

                    .collection(
                    "users")

                    .where(

                    "rollNumber",

                    isEqualTo:

                    student[
                    "roll"])

                    .get()

                    .then(
                      (v){

                    if(
                    v.docs
                        .isNotEmpty
                    ){

                      double currentPaid =

                          (v.docs.first.data()

                          as Map<
                              String,
                              dynamic>)

                          ["paidFee"]

                              ??

                              0;

                      double remaining =

                          total -
                              currentPaid;

                      if(
                      remaining < 0
                      ){

                        remaining = 0;
                      }

                      v.docs.first.reference.update({

                        "totalFee":
                        total,

                        "feesDue":
                        remaining,
                      });

                          if(
                          remaining < 0
                      ){

                        remaining = 0;
                      }

                      v.docs.first.reference.update({

                        "totalFee":
                        total,

                        "feesDue":
                        remaining,
                      });

                    }
                  },
                );

                Navigator.pop(
                    context);
              },

              child:
              const Text(
                  "SAVE"),
            ),
          ],
        );
      },
    );
  }

  void showReceiptDialog(
      Map student
      ){

    amountController.clear();

    modeController.clear();

    showDialog(

      context:context,

      builder:(_){

        return Dialog(

          shape:

          RoundedRectangleBorder(

            borderRadius:

            BorderRadius.circular(
              28,
            ),
          ),

          child:

          Padding(

            padding:

            const EdgeInsets.all(
              24,
            ),

            child:

            Column(

              mainAxisSize:
              MainAxisSize.min,

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children:[

                Center(

                  child:

                  Text(

                    student["name"],

                    style:

                    const TextStyle(

                      fontSize:22,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  height:24,
                ),

                TextField(

                  controller:
                  amountController,

                  keyboardType:
                  TextInputType.number,

                  decoration:

                  InputDecoration(

                    labelText:
                    "Paid Amount",

                    prefixIcon:

                    const Icon(
                      Icons.currency_rupee,
                    ),

                    border:

                    OutlineInputBorder(

                      borderRadius:

                      BorderRadius.circular(
                        18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height:18,
                ),

                TextField(

                  controller:
                  modeController,

                  decoration:

                  InputDecoration(

                    labelText:
                    "Transaction Mode",

                    hintText:

                    "UPI / Cash / Card",

                    prefixIcon:

                    const Icon(
                      Icons.payments,
                    ),

                    border:

                    OutlineInputBorder(

                      borderRadius:

                      BorderRadius.circular(
                        18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height:28,
                ),

                SizedBox(

                  width:
                  double.infinity,

                  height:55,

                  child:

                  ElevatedButton(

                    onPressed:
                        () async {

                      try{

                        if(
                        amountController.text
                            .isEmpty
                        ){

                          ScaffoldMessenger.of(
                            context,
                          )

                              .showSnackBar(

                            const SnackBar(

                              content:
                              Text(
                                "Enter amount",
                              ),
                            ),
                          );

                          return;
                        }

                        double paidNow =

                        double.parse(
                          amountController.text,
                        );

                        var v =

                        await FirebaseFirestore
                            .instance

                            .collection(
                          "users",
                        )

                            .where(

                          "rollNumber",

                          isEqualTo:

                          student[
                          "roll"
                          ],

                        )

                            .get();

                        if(
                        v.docs.isEmpty
                        ){

                          Navigator.pop(
                            context,
                          );

                          return;
                        }

                        var data =

                        v.docs.first
                            .data();

                        double currentPaid =

                        (data[
                        "paidFee"
                        ]

                            ??

                            0)

                            .toDouble();

                        double total =

                        (data[
                        "totalFee"
                        ]

                            ??

                            0)

                            .toDouble();

                        double newPaid =

                            currentPaid
                                +
                                paidNow;

                        if(
                        newPaid > total
                        ){

                          newPaid = total;
                        }

                        double remaining =

                            total
                                -
                                newPaid;

                        if(
                        remaining < 0
                        ){

                          remaining = 0;
                        }

                        await v.docs.first
                            .reference

                            .update({

                          "paidFee":
                          newPaid,

                          "feesDue":
                          remaining,
                        });

                        await FirebaseFirestore
                            .instance

                            .collection(
                          "fee_receipts",
                        )

                            .add({

                          "rollNumber":

                          student[
                          "roll"
                          ],

                          "title":

                          titleController
                              .text,

                          "amount":
                          paidNow,

                          "status":

                          remaining <= 0

                              ?

                          "PAID"

                              :

                          "PENDING",

                          "date":

                          DateTime.now()

                              .toString()

                              .substring(
                            0,
                            10,
                          ),

                          "paymentMode":

                          modeController
                              .text,

                          "transactionId":

                          transactionController
                              .text,

                          "receiptUrl":"",

                          "pending":
                          remaining,
                        });

                        await FirebaseFirestore
                            .instance

                            .collection(
                          "notifications",
                        )

                            .add({

                          "rollNumber":

                          student[
                          "roll"
                          ],

                          "title":
                          "Fee Payment",

                          "message":

                          "Fees amount ₹$paidNow paid successfully",

                          "date":
                          Timestamp.now(),

                          "type":
                          "fee",
                        });

                        amountController.clear();

                        modeController.clear();

                        if(
                        mounted
                        ){

                          Navigator.of(
                            context,
                          ).pop();
                        }

                        setState((){});

                      }

                      catch(e){

                        ScaffoldMessenger.of(
                          context,
                        )

                            .showSnackBar(

                          SnackBar(

                            content:
                            Text(
                              e.toString(),
                            ),
                          ),
                        );
                      }
                    },

                    child:

                    const Text(
                      "SEND",
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget glassCard({

    required bool isDark,

    required Widget child,

  }){

    return Container(
      padding:
      const EdgeInsets.all(
          24),

      child: child,
    );
  }

  Widget glassIcon({

    required IconData icon,

    VoidCallback?
    onTap,

  }){

    return GestureDetector(

      onTap:onTap,

      child:

      Icon(icon),
    );
  }
}