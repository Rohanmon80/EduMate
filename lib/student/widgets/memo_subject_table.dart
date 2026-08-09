import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoSubjectTable extends StatefulWidget {
  final int semester;
  final String examType;

  const MemoSubjectTable({
    super.key,
    required this.semester,
    required this.examType,
  });

  @override
  State<MemoSubjectTable> createState() =>
      _MemoSubjectTableState();
}

class _MemoSubjectTableState
    extends State<MemoSubjectTable> {

  Future<QuerySnapshot> loadResults() {
    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    return FirebaseFirestore.instance
        .collection("student_marks")
        .where(
      "studentId",
      isEqualTo: uid,
    )
        .where(
      "semester",
      isEqualTo: widget.semester,
    )
        .where(
      "released",
      isEqualTo: true,
    )
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: loadResults(),

      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Unable to load memo marks.\n${snapshot.error}",
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No Results Available",
            ),
          );
        }

        final docs = snapshot.data!.docs;

        // ======================================================
        // FILTER SELECTED REGULAR / SUPPLY
        // ======================================================

        final filteredDocs = docs.where((doc) {
          final data =
          doc.data() as Map<String, dynamic>;

          final category =
              data["examCategory"]
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
                  "regular";

          return category ==
              widget.examType
                  .trim()
                  .toLowerCase();
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: Text(
              "No marks available for the selected exam.",
            ),
          );
        }

        // ======================================================
        // GROUP BY SUBJECT
        // ======================================================

        final Map<
            String,
            List<Map<String, dynamic>>>
        subjectGroups = {};

        for (final doc in filteredDocs) {
          final data =
          doc.data() as Map<String, dynamic>;

          final subjectCode =
              data["subjectCode"]
                  ?.toString()
                  .trim() ??
                  "";

          if (subjectCode.isEmpty) {
            continue;
          }

          subjectGroups
              .putIfAbsent(
            subjectCode,
                () => [],
          )
              .add(data);
        }

        final rows = <TableRow>[];

        for (final entry
        in subjectGroups.entries) {
          final result =
          calculateSubjectResult(
            entry.value,
          );

          rows.add(
            buildRow(
              entry.key,
              result["subjectName"] ?? "",
              result["credits"] ?? "-",
              result["grade"] ?? "F",
              result["result"] ?? "FAIL",
            ),
          );
        }

        if (rows.isEmpty) {
          return const Center(
            child: Text(
              "No subject results available.",
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,

          child: Table(
            border: TableBorder.all(
              color: Colors.black,
            ),

            columnWidths: const {
              0: FixedColumnWidth(120),
              1: FixedColumnWidth(180),
              2: FixedColumnWidth(80),
              3: FixedColumnWidth(80),
              4: FixedColumnWidth(90),
            },

            children: [
              const TableRow(
                decoration: BoxDecoration(
                  color: Color(0xFFE8E8E8),
                ),

                children: [
                  HeaderCell("Subject Code"),
                  HeaderCell("Subject Name"),
                  HeaderCell("Credits"),
                  HeaderCell("Grade"),
                  HeaderCell("Result"),
                ],
              ),

              ...rows,
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CALCULATE SUBJECT RESULT
  // ============================================================

  Map<String, dynamic> calculateSubjectResult(
      List<Map<String, dynamic>> marks,
      ) {
    double? mid1;
    double? mid2;
    double? external;

    String subjectName = "";
    double credits = 0;

    bool isLab = false;

    for (final data in marks) {
      subjectName =
          data["subjectName"]
              ?.toString() ??
              subjectName;

      final type =
          data["type"]
              ?.toString()
              .toLowerCase() ??
              "";

      isLab = type == "lab";

      final value =
      (data["marks"] as num?)
          ?.toDouble();

      if (value == null) {
        continue;
      }

      final exam =
          data["exam"]
              ?.toString()
              .trim() ??
              "";

      if (exam == "Mid 1") {
        mid1 = value;
      } else if (exam == "Mid 2") {
        mid2 = value;
      } else if (
      exam == "Sem External" ||
          exam == "Lab External" ||
          exam == "External") {
        external = value;
      }

      final c =
      (data["credits"] as num?)
          ?.toDouble();

      if (c != null) {
        credits = c;
      }
    }

    // ==========================================================
    // LAB
    // ==========================================================

    if (isLab) {
      final internal1 =
          marks
              .where(
                (e) =>
            e["exam"] ==
                "Lab Internal 1",
          )
              .map(
                (e) =>
                (e["marks"] as num?)
                    ?.toDouble(),
          )
              .whereType<double>()
              .firstOrNull;

      final internal2 =
          marks
              .where(
                (e) =>
            e["exam"] ==
                "Lab Internal 2",
          )
              .map(
                (e) =>
                (e["marks"] as num?)
                    ?.toDouble(),
          )
              .whereType<double>()
              .firstOrNull;

      final labExternal =
          marks
              .where(
                (e) =>
            e["exam"] ==
                "Lab External",
          )
              .map(
                (e) =>
                (e["marks"] as num?)
                    ?.toDouble(),
          )
              .whereType<double>()
              .firstOrNull;

      if (internal1 == null ||
          internal2 == null ||
          labExternal == null) {
        return {
          "subjectName": subjectName,
          "credits": credits,
          "grade": "F",
          "result": "PENDING",
        };
      }

      final average =
          (internal1 + internal2) / 2;

      final total =
          average + labExternal;

      final passed =
          average >= 14 &&
              total >= 40;

      return {
        "subjectName": subjectName,
        "credits": credits,
        "grade": passed
            ? gradeFromMarks(total)
            : "F",
        "result":
        passed ? "PASS" : "FAIL",
      };
    }

    // ==========================================================
    // THEORY
    // ==========================================================

    if (mid1 == null ||
        mid2 == null ||
        external == null) {
      return {
        "subjectName": subjectName,
        "credits": credits,
        "grade": "F",
        "result": "PENDING",
      };
    }

    // Your rule:
    //
    // Mid 1 + Mid 2
    //       ↓
    // Average
    //
    // Average < 14 → FAIL
    //
    // Average + External < 40 → FAIL

    final average =
        (mid1 + mid2) / 2;

    final total =
        average + external;

    final passed =
        average >= 14 &&
            total >= 40;

    return {
      "subjectName": subjectName,
      "credits": credits,
      "grade": passed
          ? gradeFromMarks(total)
          : "F",
      "result":
      passed ? "PASS" : "FAIL",
    };
  }

  // ============================================================
  // GRADE
  // ============================================================

  String gradeFromMarks(
      double total,
      ) {
    if (total >= 90) return "O";
    if (total >= 80) return "A+";
    if (total >= 70) return "A";
    if (total >= 60) return "B+";
    if (total >= 50) return "B";
    if (total >= 40) return "C";

    return "F";
  }

  // ============================================================
  // TABLE ROW
  // ============================================================

  static TableRow buildRow(
      String code,
      String subject,
      dynamic credits,
      String grade,
      String result,
      ) {
    return TableRow(
      children: [
        cell(code),
        cell(subject),
        cell(
          credits.toString(),
        ),
        cell(grade),
        cell(result),
      ],
    );
  }

  static Widget cell(
      String text,
      ) {
    return Padding(
      padding:
      const EdgeInsets.all(10),

      child: Text(
        text,
        textAlign:
        TextAlign.center,
      ),
    );
  }
}

// ==============================================================
// HEADER
// ==============================================================

class HeaderCell
    extends StatelessWidget {
  final String text;

  const HeaderCell(
      this.text, {
        super.key,
      });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.all(10),

      child: Text(
        text,
        textAlign:
        TextAlign.center,

        style:
        const TextStyle(
          fontWeight:
          FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ==============================================================
// FIRST-OR-NULL EXTENSION
// ==============================================================

extension FirstOrNullExtension<T>
on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) {
      return null;
    }

    return first;
  }
}