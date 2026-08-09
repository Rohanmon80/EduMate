import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoSummaryCard extends StatelessWidget {
  const MemoSummaryCard({super.key});

  // ============================================================
  // GRADE CALCULATION
  // ============================================================

  Map<String, dynamic> calculateGrade({
    required double average,
    required double total,
  }) {
    final pass =
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

    for (final item in marks) {
      final exam =
          item["exam"]?.toString().trim() ?? "";

      final mark =
      (item["marks"] as num?)?.toDouble();

      if (mark == null) {
        continue;
      }

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

    final first = marks.first;

    final type =
        first["type"]?.toString().toLowerCase() ?? "";

    final bool isLab = type == "lab";

    // ----------------------------------------------------------
    // Required exams
    // ----------------------------------------------------------

    final bool complete =
        internal1 != null &&
            internal2 != null &&
            external != null;

    // ----------------------------------------------------------
    // If marks are incomplete, don't mark the subject FAIL.
    // ----------------------------------------------------------

    if (!complete) {
      double credits = 0;

      for (final item in marks) {
        final value =
        (item["credits"] as num?)?.toDouble();

        if (value != null) {
          credits = value;
          break;
        }
      }

      return {
        "subjectCode":
        first["subjectCode"]?.toString() ?? "",

        "subjectName":
        first["subjectName"]?.toString() ?? "",

        "semester":
        (first["semester"] as num?)?.toInt(),

        "credits": credits,

        "pass": false,

        "complete": false,

        "grade": "Pending",

        "gradePoint": 0,

        "average": null,

        "external": external,

        "total": null,

        "type": isLab ? "Lab" : "Theory",
      };
    }

    // ----------------------------------------------------------
    // Your exact calculation
    // ----------------------------------------------------------

    final average =
        (internal1! + internal2!) / 2;

    final total =
        average + external!;

    final gradeData =
    calculateGrade(
      average: average,
      total: total,
    );

    double credits = 0;

    for (final item in marks) {
      final value =
      (item["credits"] as num?)?.toDouble();

      if (value != null) {
        credits = value;
        break;
      }
    }

    return {
      "subjectCode":
      first["subjectCode"]?.toString() ?? "",

      "subjectName":
      first["subjectName"]?.toString() ?? "",

      "semester":
      (first["semester"] as num?)?.toInt(),

      "credits": credits,

      "pass": gradeData["pass"],

      "complete": true,

      "grade": gradeData["grade"],

      "gradePoint":
      gradeData["gradePoint"],

      "average": average,

      "external": external,

      "total": total,

      "type": isLab ? "Lab" : "Theory",
    };
  }
  // ============================================================
  // RESOLVE REGULAR / SUPPLY RESULT
  // ============================================================

  Map<String, dynamic> resolveSubjectResult(
      List<Map<String, dynamic>> marks,
      ) {
    final regularMarks = <Map<String, dynamic>>[];

    final supplyMarks = <Map<String, dynamic>>[];

    for (final mark in marks) {
      final category =
          mark["examCategory"]
              ?.toString()
              .trim()
              .toLowerCase() ??
              "regular";

      if (category == "supply") {
        supplyMarks.add(mark);
      } else {
        regularMarks.add(mark);
      }
    }

    // ----------------------------------------------------------
    // Calculate Regular attempt
    // ----------------------------------------------------------

    Map<String, dynamic>? regularResult;

    if (regularMarks.isNotEmpty) {
      regularResult =
          buildSubjectResult(
            regularMarks,
          );
    }

    // ----------------------------------------------------------
    // Calculate Supply attempt
    //
    // Supply can contain only the exam that was repeated.
    // Therefore, use Regular marks for missing exams.
    // ----------------------------------------------------------

    Map<String, dynamic>? supplyResult;

    if (supplyMarks.isNotEmpty) {
      final mergedSupplyMarks =
      <Map<String, dynamic>>[];

      final supplyExams =
      supplyMarks
          .map(
            (e) =>
            e["exam"]
                ?.toString()
                .trim(),
      )
          .whereType<String>()
          .toSet();

      // Keep Regular marks for exams that
      // were NOT supplied/repeated.
      for (final mark in regularMarks) {
        final exam =
        mark["exam"]
            ?.toString()
            .trim();

        if (exam == null ||
            !supplyExams.contains(exam)) {
          mergedSupplyMarks.add(mark);
        }
      }

      // Supply marks replace the same exam
      // from the Regular attempt.
      mergedSupplyMarks.addAll(
        supplyMarks,
      );

      supplyResult =
          buildSubjectResult(
            mergedSupplyMarks,
          );
    }

    // ----------------------------------------------------------
// FINAL SUBJECT RESULT
// ----------------------------------------------------------

    if (supplyResult != null &&
        supplyResult["complete"] == true &&
        supplyResult["pass"] == true) {
      return supplyResult;
    }

    if (regularResult != null &&
        regularResult["complete"] == true &&
        regularResult["pass"] == true) {
      return regularResult;
    }

// If Supply is complete and failed,
// use Supply result.
    if (supplyResult != null &&
        supplyResult["complete"] == true) {
      return supplyResult;
    }

// If Regular is complete and failed,
// use Regular result.
    if (regularResult != null &&
        regularResult["complete"] == true) {
      return regularResult;
    }

// Otherwise the subject is still pending.
    return supplyResult ??
        regularResult ??
        buildSubjectResult(marks);
  }
  // ============================================================
  // CALCULATE SEMESTER SGPA / CGPA
  // ============================================================

  // ============================================================
  // CALCULATE SEMESTER SGPA / CGPA
  // ============================================================

  Map<String, dynamic> calculateSemesterResult(
      List<Map<String, dynamic>> semesterSubjects,
      ) {
    double totalCredits = 0;
    double totalCreditPoints = 0;

    bool allSubjectsPassed = true;
    bool allSubjectsComplete = true;

    for (final subject in semesterSubjects) {
      final credits =
          (subject["credits"] as num?)?.toDouble() ?? 0;

      final gradePoint =
          (subject["gradePoint"] as num?)?.toDouble() ?? 0;

      totalCredits += credits;

      totalCreditPoints +=
          credits * gradePoint;

      // Marks for the subject are not complete yet.
      if (subject["complete"] != true) {
        allSubjectsComplete = false;
      }

      // Subject failed.
      if (subject["pass"] != true) {
        allSubjectsPassed = false;
      }
    }

    // ----------------------------------------------------------
    // SGPA
    // ----------------------------------------------------------

    final double sgpa =
    totalCredits == 0
        ? 0
        : totalCreditPoints / totalCredits;

    // ----------------------------------------------------------
    // CGPA
    //
    // A semester gets a CGPA only when:
    // 1. All required marks are available
    // 2. Every subject is PASS
    // 3. Credits are available
    // ----------------------------------------------------------

    final bool cgpaAvailable =
        semesterSubjects.isNotEmpty &&
            allSubjectsComplete &&
            allSubjectsPassed &&
            totalCredits > 0;

    return {
      "sgpa": sgpa,
      "cgpa": cgpaAvailable ? sgpa : null,
      "cgpaAvailable": cgpaAvailable,
      "allSubjectsPassed": allSubjectsPassed,
      "allSubjectsComplete": allSubjectsComplete,
      "totalCredits": totalCredits,
    };
  }

  // ============================================================
  // BUILD SUMMARY
  // ============================================================

  Widget _buildSummary(
      List<QueryDocumentSnapshot> docs,
      ) {
    // ----------------------------------------------------------
    // GROUP MARKS BY SUBJECT
    // ----------------------------------------------------------

    final Map<
        String,
        List<Map<String, dynamic>>> groupedSubjects = {};

    for (final doc in docs) {
      final data =
      doc.data() as Map<String, dynamic>;

      final subjectCode =
          data["subjectCode"]?.toString().trim() ?? "";

      final semester =
      (data["semester"] as num?)?.toInt();

      if (subjectCode.isEmpty ||
          semester == null) {
        continue;
      }

      final key =
          "${semester}_$subjectCode";

      groupedSubjects.putIfAbsent(
        key,
            () => [],
      );

      groupedSubjects[key]!.add(data);
    }

    // ----------------------------------------------------------
    // BUILD SUBJECT RESULTS
    // ----------------------------------------------------------

    final List<Map<String, dynamic>> subjects = [];

    for (final entry
    in groupedSubjects.entries) {
      subjects.add(
          resolveSubjectResult(
            entry.value,
          ),

      );
    }

    // ----------------------------------------------------------
    // GROUP SUBJECT RESULTS BY SEMESTER
    // ----------------------------------------------------------

    final Map<
        int,
        List<Map<String, dynamic>>> semesterSubjects = {};

    for (final subject in subjects) {
      final semester =
      (subject["semester"] as num?)?.toInt();

      if (semester == null) {
        continue;
      }

      semesterSubjects.putIfAbsent(
        semester,
            () => [],
      );

      semesterSubjects[semester]!.add(
        subject,
      );
    }

    // ----------------------------------------------------------
    // CALCULATE EVERY SEMESTER
    // ----------------------------------------------------------

    final Map<int, Map<String, dynamic>>
    semesterResults = {};

    for (final entry
    in semesterSubjects.entries) {
      semesterResults[entry.key] =
          calculateSemesterResult(
            entry.value,
          );
    }

    // ----------------------------------------------------------
    // TOTAL CREDITS
    // ----------------------------------------------------------

    double totalCredits = 0;

    for (final subject in subjects) {
      totalCredits +=
          (subject["credits"] as num?)
              ?.toDouble() ??
              0;
    }

    // ----------------------------------------------------------
    // LATEST / CURRENT SGPA
    // ----------------------------------------------------------

    double sgpa = 0;

    if (semesterResults.isNotEmpty) {
      final semesters =
      semesterResults.keys.toList()
        ..sort();

      final latestSemester =
          semesters.last;

      sgpa =
          (semesterResults[
          latestSemester]?["sgpa"]
          as num?)
              ?.toDouble() ??
              0;
    }

    // ----------------------------------------------------------
    // COMPLETED CGPAs
    // ----------------------------------------------------------
    //
    // A semester CGPA is completed ONLY when:
    //
    // 1. It has subjects
    // 2. Every subject is PASS
    // 3. Total credits > 0
    //
    // ----------------------------------------------------------

    final List<double> completedCGPAs = [];

    for (final semesterResult
    in semesterResults.values) {
      final cgpaAvailable =
          semesterResult["cgpaAvailable"] ==
              true;

      if (cgpaAvailable) {
        final semesterCGPA =
        (semesterResult["cgpa"]
        as num?)
            ?.toDouble();

        if (semesterCGPA != null) {
          completedCGPAs.add(
            semesterCGPA,
          );
        }
      }
    }

    // ----------------------------------------------------------
    // CGPA
    // ----------------------------------------------------------
    //
    // IMPORTANT:
    //
    // CGPA is available only for a semester
    // when ALL subjects of that semester pass.
    //
    // If the student has a failed subject in
    // a semester, that semester has no CGPA.
    //
    // ----------------------------------------------------------

    double? cgpa;

    if (semesterResults.isNotEmpty) {
      final semesters =
      semesterResults.keys.toList()
        ..sort();

      final latestSemester =
          semesters.last;

      final latestSemesterResult =
      semesterResults[
      latestSemester];

      if (latestSemesterResult?["cgpaAvailable"] ==
          true) {
        cgpa =
            (latestSemesterResult?["cgpa"]
            as num?)
                ?.toDouble();
      }
    }

    // ----------------------------------------------------------
    // FGPA
    // ----------------------------------------------------------
    //
    // YOUR FORMULA:
    //
    // FGPA =
    // Sum of all completed CGPAs
    // --------------------------------
    // Number of completed CGPAs
    //
    // BUT:
    //
    // If even ONE semester does not
    // have a CGPA, FGPA is NOT AVAILABLE.
    //
    // ----------------------------------------------------------

    double? fgpa;

    final totalSemesters =
        semesterResults.length;

    final completedCGPACount =
        completedCGPAs.length;

    final allSemestersCompleted =
        totalSemesters > 0 &&
            completedCGPACount ==
                totalSemesters;

    if (allSemestersCompleted) {
      final sumOfCGPAs =
      completedCGPAs.fold<double>(
        0,
            (sum, value) => sum + value,
      );

      fgpa =
          sumOfCGPAs /
              completedCGPACount;
    }

    // ----------------------------------------------------------
    // OVERALL RESULT
    // ----------------------------------------------------------

    final bool allSubjectsPassed =
        subjects.isNotEmpty &&
            subjects.every(
                  (subject) =>
              subject["pass"] == true,
            );

    final result =
    docs.isEmpty
        ? "NO RESULT"
        : allSubjectsPassed
        ? "PASS"
        : "FAIL";

    // ----------------------------------------------------------
    // UI
    // ----------------------------------------------------------

    return Column(
      children: [
        const Divider(
          thickness: 2,
        ),

        const SizedBox(
          height: 20,
        ),

        Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  summaryRow(
                    "Total Credits",
                    totalCredits
                        .toStringAsFixed(0),
                  ),

                  summaryRow(
                    "SGPA",
                    sgpa.toStringAsFixed(2),
                  ),

                  summaryRow(
                    "CGPA",
                    cgpa == null
                        ? "Not Available"
                        : cgpa.toStringAsFixed(
                      2,
                    ),
                  ),

                  summaryRow(
                    "FGPA",
                    fgpa == null
                        ? "Not Available"
                        : fgpa.toStringAsFixed(
                      2,
                    ),
                  ),

                  summaryRow(
                    "Overall Result",
                    result,
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 40,
            ),

            Column(
              children: [
                const SizedBox(
                  height: 60,
                ),

                Container(
                  width: 180,
                  height: 1,
                  color: Colors.black,
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  "Controller of Examinations",
                  style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final uid =
        FirebaseAuth
            .instance
            .currentUser
            ?.uid;

    if (uid == null) {
      return const Text(
        "Student not logged in",
      );
    }

    return FutureBuilder<
        QuerySnapshot>(
      future:
      FirebaseFirestore
          .instance
          .collection(
        "student_marks",
      )
          .where(
        "studentId",
        isEqualTo: uid,
      )
          .where(
        "released",
        isEqualTo: true,
      )
          .get(),

      builder:
          (
          context,
          marksSnapshot,
          ) {
        if (marksSnapshot
            .connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
            CircularProgressIndicator(),
          );
        }

        if (marksSnapshot.hasError) {
          return Text(
            "Unable to load result data.\n"
                "${marksSnapshot.error}",
          );
        }

        if (!marksSnapshot.hasData) {
          return const Text(
            "No result data available",
          );
        }

        final docs =
            marksSnapshot.data!.docs;

        return _buildSummary(
          docs,
        );
      },
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget summaryRow(
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 10,
      ),

      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              title,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const Text(" : "),

          Expanded(
            child: Text(
              value,
            ),
          ),
        ],
      ),
    );
  }
}