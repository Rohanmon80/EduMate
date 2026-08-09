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
    double? internal1;
    double? internal2;
    double? external;

    bool isLab = false;

    String subjectCode = "";
    String subjectName = "";
    String subjectType = "";

    double credits = 0;

    String examCategory = "Regular";

    for (final item in marks) {
      subjectCode =
          item["subjectCode"]?.toString() ??
              subjectCode;

      subjectName =
          item["subjectName"]?.toString() ??
              subjectName;

      subjectType =
          item["type"]?.toString() ??
              subjectType;

      final type =
          item["type"]?.toString().toLowerCase() ??
              "";

      if (type == "lab") {
        isLab = true;
      }

      final category =
          item["examCategory"]
              ?.toString()
              .trim()
              .toLowerCase() ??
              "regular";

      if (category == "supply") {
        examCategory = "Supply";
      }

      final value =
      (item["marks"] as num?)?.toDouble();

      if (value == null) {
        continue;
      }

      final exam =
          item["exam"]?.toString().trim() ??
              "";

      // THEORY
      if (!isLab) {
        if (exam == "Mid 1") {
          internal1 = value;
        } else if (exam == "Mid 2") {
          internal2 = value;
        } else if (exam == "Sem External" ||
            exam == "External") {
          external = value;
        }
      }

      // LAB
      else {
        if (exam == "Lab Internal 1") {
          internal1 = value;
        } else if (exam == "Lab Internal 2") {
          internal2 = value;
        } else if (exam == "Lab External") {
          external = value;
        }
      }

      final creditValue =
      (item["credits"] as num?)?.toDouble();

      if (creditValue != null) {
        credits = creditValue;
      }
    }

    // ============================================================
    // MISSING MARKS
    // ============================================================

    if (internal1 == null ||
        internal2 == null ||
        external == null) {
      return {
        "subjectCode": subjectCode,
        "subjectName": subjectName,
        "type": subjectType,
        "credits": credits,
        "average": null,
        "external": external,
        "total": null,
        "grade": "-",
        "gradePoint": 0,
        "pass": false,
        "pending": true,
        "semester": selectedSemester,
        "examCategory": examCategory,
      };
    }

    // ============================================================
    // INTERNAL / MID AVERAGE
    // ============================================================

    final average =
        (internal1 + internal2) / 2;

    // ============================================================
    // FINAL TOTAL
    // ============================================================

    final total =
        average + external;

    // ============================================================
    // PASS RULE
    //
    // Average Mid/Internal >= 14
    // AND
    // Average + External >= 40
    // ============================================================

    final passed =
        average >= 14 &&
            total >= 40;

    // ============================================================
    // GRADE
    // ============================================================

    String grade = "F";
    int gradePoint = 0;

    if (passed) {
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
      "subjectCode": subjectCode,
      "subjectName": subjectName,
      "type": subjectType,
      "credits": credits,
      "average": average,
      "external": external,
      "total": total,
      "grade": grade,
      "gradePoint": gradePoint,
      "pass": passed,
      "pending": false,
      "semester": selectedSemester,
      "examCategory": examCategory,
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
  Future<List<double>> getCompletedSemesterGPAs() async {
    final uid = studentId;

    if (uid == null) {
      return [];
    }

    final snapshot =
    await FirebaseFirestore.instance
        .collection("student_marks")
        .where(
      "studentId",
      isEqualTo: uid,
    )
        .where(
      "released",
      isEqualTo: true,
    )
        .get();

    final Map<int, List<Map<String, dynamic>>>
    semesterMarks = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final semester =
      (data["semester"] as num?)?.toInt();

      if (semester == null) {
        continue;
      }

      semesterMarks
          .putIfAbsent(
        semester,
            () => [],
      )
          .add(data);
    }

    final completedCGPAs = <double>[];

    double cumulativeCreditPoints = 0;
    double cumulativeCredits = 0;

    final sortedSemesters =
    semesterMarks.keys.toList()..sort();

    for (final semester
    in sortedSemesters) {
      final Map<String,
          List<Map<String, dynamic>>>
      subjects = {};

      for (final mark
      in semesterMarks[semester]!) {
        final code =
            mark["subjectCode"]
                ?.toString()
                .trim() ??
                "";

        if (code.isEmpty) {
          continue;
        }

        final category =
            mark["examCategory"]
                ?.toString()
                .trim()
                .toLowerCase() ??
                "regular";

        final key =
            "${code}_$category";

        subjects
            .putIfAbsent(
          key,
              () => [],
        )
            .add(mark);
      }

      final results =
      <Map<String, dynamic>>[];

      for (final subject
      in subjects.values) {
        results.add(
          buildSubjectResult(
            subject,
          ),
        );
      }

      if (results.isEmpty) {
        continue;
      }

      // A semester is completed only when
      // every subject is fully marked and passed.
      final semesterCompleted =
      results.every(
            (result) =>
        result["pending"] != true &&
            result["pass"] == true,
      );

      if (!semesterCompleted) {
        continue;
      }

      double semesterCredits = 0;
      double semesterCreditPoints = 0;

      for (final result in results) {
        final credits =
            (result["credits"] as num?)
                ?.toDouble() ??
                0;

        final gradePoint =
            (result["gradePoint"] as num?)
                ?.toDouble() ??
                0;

        semesterCredits += credits;

        semesterCreditPoints +=
            credits * gradePoint;
      }

      if (semesterCredits <= 0) {
        continue;
      }

      cumulativeCredits +=
          semesterCredits;

      cumulativeCreditPoints +=
          semesterCreditPoints;

      final cumulativeCGPA =
          cumulativeCreditPoints /
              cumulativeCredits;

      completedCGPAs.add(
        cumulativeCGPA,
      );
    }

    return completedCGPAs;
  }
  double calculateFGPA(
      List<double> completedCGPAs,
      )
  {
    if (completedCGPAs.isEmpty) {
      return 0;
    }

    final sum =
    completedCGPAs.reduce(
          (a, b) => a + b,
    );

    return sum /
        completedCGPAs.length;
  }
  Future<double?> calculateCurrentCGPA(
      int currentSemester,
      ) async {
    final uid = studentId;

    if (uid == null) {
      return null;
    }

    final snapshot =
    await FirebaseFirestore.instance
        .collection("student_marks")
        .where(
      "studentId",
      isEqualTo: uid,
    )
        .where(
      "released",
      isEqualTo: true,
    )
        .get();

    final Map<int, List<Map<String, dynamic>>>
    semesterMarks = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final semester =
      (data["semester"] as num?)?.toInt();

      if (semester == null ||
          semester > currentSemester) {
        continue;
      }

      semesterMarks
          .putIfAbsent(
        semester,
            () => [],
      )
          .add(data);
    }

    double totalCreditPoints = 0;
    double totalCredits = 0;

    for (final entry in semesterMarks.entries) {
      final Map<String, List<Map<String, dynamic>>>
      subjects = {};

      for (final mark in entry.value) {
        final code =
            mark["subjectCode"]
                ?.toString()
                .trim() ??
                "";

        if (code.isEmpty) {
          continue;
        }

        final category =
            mark["examCategory"]
                ?.toString()
                .trim()
                .toLowerCase() ??
                "regular";

        final key =
            "${code}_$category";

        subjects
            .putIfAbsent(
          key,
              () => [],
        )
            .add(mark);
      }

      final results =
      <Map<String, dynamic>>[];

      for (final subject
      in subjects.values) {
        results.add(
          buildSubjectResult(subject),
        );
      }

      if (results.isEmpty) {
        continue;
      }

      // If ANY subject in this semester
      // is failed or pending, this semester
      // cannot contribute to CGPA.
      final semesterCompleted =
      results.every(
            (result) =>
        result["pending"] != true &&
            result["pass"] == true,
      );

      if (!semesterCompleted) {
        continue;
      }

      for (final result in results) {
        final credits =
            (result["credits"] as num?)
                ?.toDouble() ??
                0;

        final gradePoint =
            (result["gradePoint"] as num?)
                ?.toDouble() ??
                0;

        totalCredits += credits;

        totalCreditPoints +=
            credits * gradePoint;
      }
    }

    if (totalCredits == 0) {
      return null;
    }

    return totalCreditPoints /
        totalCredits;
  }
  Widget _buildCGPAFGPACard({
    required bool isDark,
    required bool semesterCompleted,
    required double sgpa,
  }) {
    if (selectedSemester == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<double?>(
      future: calculateCurrentCGPA(
        selectedSemester!,
      ),

      builder: (context, snapshot) {
        final cgpa = snapshot.data;

        return FutureBuilder<List<double>>(
          future: getCompletedSemesterGPAs(),

          builder: (context, fgpaSnapshot) {
            final completedCGPAs =
                fgpaSnapshot.data ?? [];

            final fgpa =
            completedCGPAs.isNotEmpty
                ? calculateFGPA(
              completedCGPAs,
            )
                : null;

            return Card(
              margin: const EdgeInsets.only(
                bottom: 20,
              ),

              color: isDark
                  ? const Color(0xFF1E293B)
                  : Colors.white,

              child: Padding(
                padding:
                const EdgeInsets.all(20),

                child: Column(
                  children: [
                    const Text(
                      "Academic Summary",

                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _summaryValue(
                      "SGPA",
                      sgpa.toStringAsFixed(2),
                    ),

                    const SizedBox(height: 12),

                    _summaryValue(
                      "CGPA",
                      cgpa == null
                          ? "Not Available"
                          : cgpa.toStringAsFixed(2),
                    ),

                    const SizedBox(height: 12),

                    _summaryValue(
                      "FGPA",
                      fgpa == null
                          ? "Not Available"
                          : fgpa.toStringAsFixed(2),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  Widget _summaryValue(
      String title,
      String value,
      ) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
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
                              ?.toString()
                              .trim() ??
                              "";

                      if (code.isEmpty) {
                        continue;
                      }

                      final category =
                          data["examCategory"]
                              ?.toString()
                              .trim()
                              .toLowerCase() ??
                              "regular";

                      final key =
                          "${code}_${category}";

                      grouped.putIfAbsent(
                        key,
                            () => [],
                      );

                      grouped[key]!.add(data);
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

                    final completedSubjects =
                    subjectResults.where(
                          (result) =>
                      result["pending"] != true,
                    );
                    final semesterPending =
                    subjectResults.any(
                          (result) =>
                      result["pending"] == true,
                    );

                    final sgpa =
                    calculateSGPA(
                      completedSubjects.toList(),
                    );

                    double totalCredits = 0;

                    bool semesterPassed = true;
                    bool semesterCompleted =
                        subjectResults.isNotEmpty;

                    for (final result in subjectResults) {
                      final credits =
                          (result["credits"] as num?)
                              ?.toDouble() ??
                              0;

                      totalCredits += credits;

                      if (result["pending"] == true ||
                          result["pass"] != true) {
                        semesterPassed = false;
                        semesterCompleted = false;
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
                                  semesterPending
                                      ? "Semester Result: PENDING"
                                      : semesterPassed
                                      ? "Semester Result: PASS"
                                      : "Semester Result: FAIL",

                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: semesterPending
                                        ? Colors.orange
                                        : semesterPassed
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _buildCGPAFGPACard(
                          isDark: isDark,
                          semesterCompleted: semesterCompleted,
                          sgpa: sgpa,
                        ),

                        // ==================================================
                        // SUBJECT CARDS
                        // ==================================================

                        ...subjectResults.map(
                              (result) {
                                final pass =
                                    result["pass"] == true;

                                final pending =
                                    result["pending"] == true;

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
                                          "${average == null ? '--' : (average as num).toStringAsFixed(1)}"
                                          : "Average Mid: "
                                          "${average == null ? '--' : (average as num).toStringAsFixed(1)}",
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      type
                                          .toString()
                                          .toLowerCase() ==
                                          "lab"
                                          ? "Lab External: ${external ?? '--'}"
                                          : "Semester External: ${external ?? '--'}",
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      "Total: "
                                          "${total == null ? '--' : (total as num).toStringAsFixed(1)}",
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
                                        color: pending
                                            ? Colors.orange
                                            : pass
                                            ? Colors.green
                                            : Colors.red,

                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                          20,
                                        ),
                                      ),

                                      child:
                                      Text(
                                        pending
                                            ? "PENDING"
                                            : pass
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