import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPendingFeesPage extends StatefulWidget {
  const AdminPendingFeesPage({
    super.key,
  });

  @override
  State<AdminPendingFeesPage> createState() =>
      _AdminPendingFeesPageState();
}

class _AdminPendingFeesPageState
    extends State<AdminPendingFeesPage> {
  final TextEditingController searchController =
  TextEditingController();

  String searchText = "";

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? "",
    ) ??
        0.0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final textColor =
    isDark ? Colors.white : Colors.black;

    final secondaryTextColor =
    isDark
        ? Colors.white70
        : Colors.black54;

    return Scaffold(
      backgroundColor:
      isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [

              // =========================================================
              // BACK BUTTON + TITLE
              // =========================================================

              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color:
                        isDark
                            ? Colors.white
                            .withOpacity(.08)
                            : Colors.white,
                        borderRadius:
                        BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: textColor,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Text(
                    "Pending Fees",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight:
                      FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =========================================================
              // SEARCH
              // =========================================================

              ClipRRect(
                borderRadius:
                BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10,
                    sigmaY: 10,
                  ),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      isDark
                          ? Colors.white
                          .withOpacity(.08)
                          : Colors.white
                          .withOpacity(.7),
                      borderRadius:
                      BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller:
                      searchController,

                      onChanged: (value) {
                        setState(() {
                          searchText =
                              value
                                  .trim()
                                  .toLowerCase();
                        });
                      },

                      style: TextStyle(
                        color: textColor,
                      ),

                      decoration:
                      InputDecoration(
                        border:
                        InputBorder.none,

                        hintText:
                        "Search Roll Number or Name",

                        hintStyle:
                        TextStyle(
                          color:
                          secondaryTextColor,
                        ),

                        prefixIcon:
                        Icon(
                          Icons.search,
                          color:
                          secondaryTextColor,
                        ),

                        suffixIcon:
                        searchText.isNotEmpty
                            ? IconButton(
                          icon:
                          Icon(
                            Icons.clear,
                            color:
                            secondaryTextColor,
                          ),
                          onPressed: () {
                            searchController
                                .clear();

                            setState(() {
                              searchText =
                              "";
                            });
                          },
                        )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =========================================================
              // FIREBASE
              // =========================================================

              Expanded(
                child:
                StreamBuilder<QuerySnapshot>(
                  stream:
                  FirebaseFirestore
                      .instance
                      .collection("users")
                      .snapshots(),

                  builder:
                      (
                      context,
                      snapshot,
                      ) {
                    if (snapshot
                        .connectionState ==
                        ConnectionState
                            .waiting) {
                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error loading fee data:\n${snapshot.error}",
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );
                    }

                    // =================================================
                    // ALL STUDENTS
                    // =================================================

                    final allStudents =
                    snapshot.data!.docs
                        .where((doc) {
                      final data =
                      doc.data()
                      as Map<String, dynamic>;

                      return data["role"] ==
                          "student";
                    }).toList();

                    // =================================================
                    // OVERALL SUMMARY
                    // =================================================

                    int pendingStudents = 0;
                    int notSetStudents = 0;

                    double totalPending = 0;

                    for (final doc
                    in allStudents) {
                      final data =
                      doc.data()
                      as Map<String, dynamic>;

                      final total =
                      _toDouble(
                        data["totalFee"],
                      );

                      final due =
                      _toDouble(
                        data["feesDue"],
                      );

                      final feeNotSet =
                          total <= 0;

                      final hasPending =
                          due > 0;

                      if (feeNotSet) {
                        notSetStudents++;
                      } else if (hasPending) {
                        pendingStudents++;
                        totalPending += due;
                      }
                    }

                    // =================================================
                    // SEARCH FILTER
                    // =================================================

                    final students =
                    allStudents.where((doc) {
                      final data =
                      doc.data()
                      as Map<String, dynamic>;

                      final total =
                      _toDouble(
                        data["totalFee"],
                      );

                      final due =
                      _toDouble(
                        data["feesDue"],
                      );

                      final feeNotSet =
                          total <= 0;

                      final hasPending =
                          due > 0;

                      // Show only students who:
                      // 1. Have pending fees
                      // OR
                      // 2. Have not had fees set

                      if (!feeNotSet &&
                          !hasPending) {
                        return false;
                      }

                      final roll =
                      (data["rollNumber"] ??
                          "")
                          .toString()
                          .toLowerCase();

                      final name =
                      (data["name"] ?? "")
                          .toString()
                          .toLowerCase();

                      return roll.contains(
                        searchText,
                      ) ||
                          name.contains(
                            searchText,
                          );
                    }).toList();

                    // =================================================
                    // SUMMARY CARD
                    // =================================================

                    final summaryCard =
                    Container(
                      margin:
                      const EdgeInsets.only(
                        bottom: 16,
                      ),
                      padding:
                      const EdgeInsets.all(
                        18,
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
                          22,
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [

                          Row(
                            children: [

                              // Pending students
                              Expanded(
                                child:
                                _summaryItem(
                                  title:
                                  "Pending Students",
                                  value:
                                  pendingStudents
                                      .toString(),
                                  color:
                                  Colors.red,
                                  isDark:
                                  isDark,
                                ),
                              ),

                              const SizedBox(
                                width: 16,
                              ),

                              // Fees not set
                              Expanded(
                                child:
                                _summaryItem(
                                  title:
                                  "Fees Not Set",
                                  value:
                                  notSetStudents
                                      .toString(),
                                  color:
                                  Colors.orange,
                                  isDark:
                                  isDark,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          Divider(
                            color:
                            isDark
                                ? Colors.white
                                .withOpacity(
                              .1,
                            )
                                : Colors.black
                                .withOpacity(
                              .08,
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          Row(
                            children: [
                              Icon(
                                Icons
                                    .account_balance_wallet,
                                color:
                                Colors.red,
                                size: 20,
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              Text(
                                "Total Pending:",
                                style:
                                TextStyle(
                                  color:
                                  secondaryTextColor,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              Text(
                                "₹${totalPending.toInt()}",
                                style:
                                const TextStyle(
                                  color:
                                  Colors.red,
                                  fontSize: 18,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    // =================================================
                    // NO RESULTS
                    // =================================================

                    if (students.isEmpty) {
                      return Column(
                        children: [

                          summaryCard,

                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .center,

                                children: [
                                  Icon(
                                    searchText
                                        .isNotEmpty
                                        ? Icons.search_off
                                        : Icons
                                        .check_circle_outline,
                                    size: 60,
                                    color:
                                    searchText
                                        .isNotEmpty
                                        ? Colors
                                        .grey
                                        : Colors
                                        .green,
                                  ),

                                  const SizedBox(
                                    height: 14,
                                  ),

                                  Text(
                                    searchText
                                        .isNotEmpty
                                        ? "No matching students"
                                        : "No Pending Fees",
                                    style:
                                    TextStyle(
                                      fontSize:
                                      17,
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                      color:
                                      secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // =================================================
                    // LIST
                    // =================================================

                    return Column(
                      children: [

                        summaryCard,

                        Expanded(
                          child:
                          ListView.builder(
                            itemCount:
                            students.length,

                            itemBuilder:
                                (
                                context,
                                index,
                                ) {
                              final data =
                              students[index]
                                  .data()
                              as Map<String,
                                  dynamic>;

                              final total =
                              _toDouble(
                                data["totalFee"],
                              );

                              final due =
                              _toDouble(
                                data["feesDue"],
                              );

                              final feeNotSet =
                                  total <= 0;

                              return Container(
                                margin:
                                const EdgeInsets
                                    .only(
                                  bottom: 14,
                                ),

                                padding:
                                const EdgeInsets
                                    .all(
                                  18,
                                ),

                                decoration:
                                BoxDecoration(
                                  color:
                                  isDark
                                      ? Colors
                                      .white
                                      .withOpacity(
                                    .06,
                                  )
                                      : Colors
                                      .white,

                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    22,
                                  ),
                                ),

                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                                  children: [

                                    // Student name
                                    Text(
                                      data["name"] ??
                                          "Student",
                                      style:
                                      TextStyle(
                                        fontSize:
                                        18,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                        color:
                                        textColor,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 8,
                                    ),

                                    // Roll number
                                    Text(
                                      "Roll No : ${data["rollNumber"] ?? "-"}",
                                      style:
                                      TextStyle(
                                        color:
                                        secondaryTextColor,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    // Department
                                    Text(
                                      "Department : ${data["department"] ?? "-"}",
                                      style:
                                      TextStyle(
                                        color:
                                        secondaryTextColor,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 12,
                                    ),

                                    // Fee status
                                    Container(
                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                        horizontal:
                                        12,
                                        vertical: 8,
                                      ),

                                      decoration:
                                      BoxDecoration(
                                        color:
                                        feeNotSet
                                            ? Colors
                                            .orange
                                            .withOpacity(
                                          .12,
                                        )
                                            : Colors
                                            .red
                                            .withOpacity(
                                          .12,
                                        ),

                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                          12,
                                        ),
                                      ),

                                      child: Text(
                                        feeNotSet
                                            ? "Fees : Not Set"
                                            : "Pending : ₹${due.toInt()}",
                                        style:
                                        TextStyle(
                                          color:
                                          feeNotSet
                                              ? Colors
                                              .orange
                                              : Colors
                                              .red,
                                          fontWeight:
                                          FontWeight
                                              .bold,
                                        ),
                                      ),
                                    ),

                                    // Show total fee
                                    // when fees are set
                                    if (!feeNotSet) ...[
                                      const SizedBox(
                                        height: 8,
                                      ),

                                      Text(
                                        "Total Fee : ₹${total.toInt()}",
                                        style:
                                        TextStyle(
                                          color:
                                          secondaryTextColor,
                                          fontSize:
                                          13,
                                        ),
                                      ),
                                    ],
                                  ],
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

  // ===============================================================
  // SUMMARY ITEM
  // ===============================================================

  Widget _summaryItem({
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color:
            isDark
                ? Colors.white70
                : Colors.black54,
            fontSize: 13,
            fontWeight:
            FontWeight.w500,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ],
    );
  }
}