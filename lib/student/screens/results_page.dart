import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SemesterResultsPage extends StatefulWidget {
  const SemesterResultsPage({super.key});

  @override
  State<SemesterResultsPage> createState() =>
      _SemesterResultsPageState();
}

class _SemesterResultsPageState
    extends State<SemesterResultsPage> {
  int? selectedSemester;

  String? get studentId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // ============================================================
  // GRADE CALCULATION
  // ============================================================

  Map<String, dynamic> calculateGrade({
    required double average,
    required double total,
  }) {
    // Student FAILS if:
    // 1. Average Mid/Internal < 14
    // OR
    // 2. Average + External < 40

    final bool pass =
        average >= 14 && total >= 40;

    String grade = "F";
    int gradePoint = 0;

    if (pass) {
      if (total >= 90) {
        grade = "O";
        gradePoint = 10;
      } else if (total >= 80) {
        grade = "A+";
        gradePoint = 9;
      } else if (total >= 70) {
        grade = "A";
        gradePoint = 8;
      } else if (total >= 60) {
        grade = "B+";
        gradePoint = 7;
      } else if (total >= 50) {
        grade = "B";
        gradePoint = 6;
      } else {
        grade = "C";
        gradePoint = 5;
      }
    }

    return {
      "pass": pass,
      "grade": grade,
      "gradePoint": gradePoint,
    };
  }

  // ============================================================
  // BUILD SUBJECT RESULT
  // ============================================================

  Map<String, dynamic> buildSubjectResult(
      List<Map<String, dynamic>> marks,
      ) {
    double internal1 = 0;
    double internal2 = 0;
    double external = 0;

    bool isLab = false;

    for (final item in marks) {
      final type =
          item["type"]?.toString() ?? "";

      if (type.toLowerCase() == "lab") {
        isLab = true;
      }

      final exam =
          item["exam"]?.toString() ?? "";

      final mark =
          (item["marks"] as num?)
              ?.toDouble() ??
              0;

      switch (exam) {
        case "Mid 1":
        case "Lab Internal 1":
          internal1 = mark;
          break;

        case "Mid 2":
        case "Lab Internal 2":
          internal2 = mark;
          break;

        case "Sem External":
        case "Lab External":
          external = mark;
          break;
      }
    }

    // Same calculation for theory and lab.
    final average =
        (internal1 + internal2) / 2;

    final total =
        average + external;

    final gradeData =
    calculateGrade(
      average: average,
      total: total,
    );

    // Credits are stored in student_marks.
    double credits = 0;

    for (final item in marks) {
      final value =
      (item["credits"] as num?)
          ?.toDouble();

      if (value != null) {
        credits = value;
        break;
      }
    }

    final first = marks.first;

    return {
      "subjectCode":
      first["subjectCode"]?.toString() ?? "",

      "subjectName":
      first["subjectName"]?.toString() ?? "",

      "type":
      first["type"]?.toString() ?? "",

      "credits": credits,

      "average": average,

      "external": external,

      "total": total,

      "grade":
      gradeData["grade"],

      "gradePoint":
      gradeData["gradePoint"],

      "pass":
      gradeData["pass"],

      "semester":
      (first["semester"] as num?)
          ?.toInt(),

      "examCategory":
      first["examCategory"]?.toString() ??
          "Regular",
    };
  }

  // ============================================================
  // BUILD SGPA
  // ============================================================

  double calculateSGPA(
      List<Map<String, dynamic>> subjects,
      ) {
    double totalCredits = 0;
    double totalCreditPoints = 0;

    for (final subject in subjects) {
      final credits =
          (subject["credits"] as num?)
              ?.toDouble() ??
              0;

      final gradePoint =
          (subject["gradePoint"] as num?)
              ?.toDouble() ??
              0;

      totalCredits += credits;

      totalCreditPoints +=
          credits * gradePoint;
    }

    if (totalCredits == 0) {
      return 0;
    }

    return totalCreditPoints /
        totalCredits;
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final uid = studentId;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      appBar: AppBar(
        backgroundColor:
        Colors.transparent,
        elevation: 0,
        title: const Text("Results"),
      ),

      body: uid == null
          ? const Center(
        child: Text(
          "Please login again.",
        ),
      )
          : Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: selectedSemester,

              decoration:
              const InputDecoration(
                labelText: "Semester",
                border:
                OutlineInputBorder(),
              ),

              items: List.generate(
                8,
                    (index) {
                  final semester =
                      index + 1;

                  return DropdownMenuItem(
                    value: semester,
                    child: Text(
                      "Semester $semester",
                    ),
                  );
                },
              ),

              onChanged: (value) {
                setState(() {
                  selectedSemester =
                      value;
                });
              },
            ),

            const SizedBox(
              height: 20,
            ),

            if (selectedSemester ==
                null)
              const Expanded(
                child: Center(
                  child: Text(
                    "Select Semester",
                  ),
                ),
              )
            else
              Expanded(
                child:
                StreamBuilder<
                    QuerySnapshot>(
                  stream:
                  FirebaseFirestore
                      .instance
                      .collection(
                    "student_marks",
                  )
                      .where(
                    "studentId",
                    isEqualTo:
                    uid,
                  )
                      .where(
                    "semester",
                    isEqualTo:
                    selectedSemester,
                  )
                      .where(
                    "released",
                    isEqualTo:
                    true,
                  )
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
                          "Unable to load results.\n${snapshot.error}",
                          textAlign:
                          TextAlign.center,
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );
                    }

                    final docs =
                        snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No Results Released",
                        ),
                      );
                    }

                    // ==================================================
                    // GROUP BY SUBJECT
                    // ==================================================

                    final Map<
                        String,
                        List<
                            Map<
                                String,
                                dynamic>>>
                    grouped = {};

                    for (final doc
                    in docs) {
                      final data =
                      doc.data()
                      as Map<
                          String,
                          dynamic>;

                      final code =
                          data["subjectCode"]
                              ?.toString() ??
                              "";

                      if (code.isEmpty) {
                        continue;
                      }

                      grouped.putIfAbsent(
                        code,
                            () => [],
                      );

                      grouped[code]!
                          .add(data);
                    }

                    // ==================================================
                    // SUBJECT RESULTS
                    // ==================================================

                    final List<
                        Map<String, dynamic>>
                    subjectResults = [];

                    for (final entry
                    in grouped.entries) {
                      final result =
                      buildSubjectResult(
                        entry.value,
                      );

                      subjectResults
                          .add(result);
                    }

                    // ==================================================
                    // SGPA
                    // ==================================================

                    final sgpa =
                    calculateSGPA(
                      subjectResults,
                    );

                    double totalCredits = 0;

                    bool semesterPassed =
                    true;

                    for (final result
                    in subjectResults) {
                      final credits =
                          (result["credits"]
                          as num?)
                              ?.toDouble() ??
                              0;

                      totalCredits +=
                          credits;

                      if (result["pass"] !=
                          true) {
                        semesterPassed =
                        false;
                      }
                    }

                    // ==================================================
                    // SEMESTER SUMMARY
                    // ==================================================

                    return ListView(
                      padding:
                      const EdgeInsets
                          .only(
                        bottom: 30,
                      ),

                      children: [
                        Card(
                          margin:
                          const EdgeInsets
                              .only(
                            bottom: 20,
                          ),

                          color: isDark
                              ? const Color(
                            0xFF1E293B,
                          )
                              : Colors.white,

                          child: Padding(
                            padding:
                            const EdgeInsets
                                .all(
                              20,
                            ),

                            child: Column(
                              children: [
                                const Text(
                                  "Semester GPA",
                                  style:
                                  TextStyle(
                                    fontSize:
                                    18,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  sgpa
                                      .toStringAsFixed(
                                    2,
                                  ),
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    34,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  "Total Credits: "
                                      "${totalCredits.toStringAsFixed(1)}",
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                Text(
                                  semesterPassed
                                      ? "Semester Result: PASS"
                                      : "Semester Result: FAIL",

                                  style:
                                  TextStyle(
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                    color:
                                    semesterPassed
                                        ? Colors
                                        .green
                                        : Colors
                                        .red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ==================================================
                        // SUBJECT CARDS
                        // ==================================================

                        ...subjectResults.map(
                              (result) {
                            final pass =
                                result["pass"] ==
                                    true;

                            final grade =
                            result["grade"];

                            final gradePoint =
                            result[
                            "gradePoint"];

                            final credits =
                            result[
                            "credits"];

                            final average =
                            result[
                            "average"];

                            final external =
                            result[
                            "external"];

                            final total =
                            result["total"];

                            final subjectName =
                            result[
                            "subjectName"];

                            final subjectCode =
                            result[
                            "subjectCode"];

                            final type =
                            result["type"];

                            return Card(
                              margin:
                              const EdgeInsets
                                  .only(
                                bottom: 15,
                              ),

                              color: isDark
                                  ? const Color(
                                0xFF1E293B,
                              )
                                  : Colors.white,

                              child:
                              Padding(
                                padding:
                                const EdgeInsets
                                    .all(
                                  16,
                                ),

                                child:
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                                  children: [
                                    Text(
                                      subjectName
                                          .toString(),
                                      style:
                                      const TextStyle(
                                        fontSize:
                                        18,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 6,
                                    ),

                                    Text(
                                      "Subject Code: "
                                          "$subjectCode",
                                    ),

                                    const SizedBox(
                                      height: 12,
                                    ),

                                    Text(
                                      type
                                          .toString()
                                          .toLowerCase() ==
                                          "lab"
                                          ? "Average Internal: "
                                          "${average.toStringAsFixed(1)}"
                                          : "Average Mid: "
                                          "${average.toStringAsFixed(1)}",
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      type
                                          .toString()
                                          .toLowerCase() ==
                                          "lab"
                                          ? "Lab External: $external"
                                          : "Semester External: $external",
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      "Total: "
                                          "${total.toStringAsFixed(1)}",
                                    ),

                                    const SizedBox(
                                      height: 8,
                                    ),

                                    Text(
                                      "Grade: $grade",
                                      style:
                                      const TextStyle(
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      "Grade Point: "
                                          "$gradePoint",
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      "Credits: "
                                          "$credits",
                                    ),

                                    const SizedBox(
                                      height: 12,
                                    ),

                                    Container(
                                      padding:
                                      const EdgeInsets
                                          .symmetric(
                                        horizontal:
                                        12,
                                        vertical:
                                        6,
                                      ),

                                      decoration:
                                      BoxDecoration(
                                        color: pass
                                            ? Colors
                                            .green
                                            : Colors
                                            .red,

                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                          20,
                                        ),
                                      ),

                                      child:
                                      Text(
                                        pass
                                            ? "PASS"
                                            : "FAIL",
                                        style:
                                        const TextStyle(
                                          color:
                                          Colors.white,
                                          fontWeight:
                                          FontWeight
                                              .bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}