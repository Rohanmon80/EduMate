import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/memo_service.dart';
class MemoSubjectTable extends StatefulWidget {
  const MemoSubjectTable({super.key});

  @override
  State<MemoSubjectTable> createState() => _MemoSubjectTableState();
}


class _MemoSubjectTableState extends State<MemoSubjectTable> {
  Future<void> loadSubjects() async {

    final snapshot = await FirebaseFirestore.instance
        .collection("subjects")
        .get();

    subjectsMap.clear();

    for (final doc in snapshot.docs) {

      final data = doc.data();

      subjectsMap[data["subjectCode"]] = data;

    }

    if (mounted) {

      setState(() {

        subjectsLoaded = true;

      });

    }

  }
  @override
  void initState() {
    super.initState();
    loadSubjects();
  }
  Map<String, Map<String, dynamic>> subjectsMap = {};
  bool subjectsLoaded = false;

  Future<QuerySnapshot> loadResults() {
    return FirebaseFirestore.instance
        .collection("student_marks")
        .where(
      "studentId",
      isEqualTo: FirebaseAuth.instance.currentUser!.uid,
    )
        .where(
      "released",
      isEqualTo: true,
    )
        .get();
  }

  @override
  Widget build(BuildContext context) {

    if (!subjectsLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return FutureBuilder<QuerySnapshot>(

      future: loadResults(),


      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("No Results Available"),
          );
        }

        List<TableRow> rows = [];

        for (final doc in snapshot.data!.docs) {

          final data = doc.data() as Map<String, dynamic>;
          final subject =
          subjectsMap[data["subjectCode"]];

          final credits =
              subject?["credits"]?.toString() ?? "-";

          final type =
              subject?["type"] ?? "";

          rows.add(

            buildRow(

              data["subjectCode"] ?? "",

              data["subjectName"] ?? "",

              credits,

              calculateGrade(data),

              data["released"] == true
                  ? "PASS"
                  : "FAIL",

            ),

          );

        }

        return Table(

          border: TableBorder.all(
            color: Colors.black,
          ),

          columnWidths: const {

            0: FlexColumnWidth(1.5),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1.2),

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

        );

      },

    );

  }
  String calculateGrade(Map<String, dynamic> data) {

    final exam = data["exam"] ?? "";
    final marks = (data["marks"] ?? 0).toDouble();

    if (exam == "Mid 1" || exam == "Mid 2") {

      if (marks >= 27) return "O";
      if (marks >= 24) return "A+";
      if (marks >= 21) return "A";
      if (marks >= 18) return "B+";
      if (marks >= 15) return "B";

      return "F";
    }

    if (marks >= 90) return "O";
    if (marks >= 80) return "A+";
    if (marks >= 70) return "A";
    if (marks >= 60) return "B+";
    if (marks >= 50) return "B";
    if (marks >= 40) return "C";

    return "F";
  }

  static TableRow buildRow(
      String code,
      String subject,
      String credits,
      String grade,
      String result,
      ) {

    return TableRow(

      children: [

        cell(code),

        cell(subject),

        cell(credits),

        cell(grade),

        cell(result),

      ],

    );

  }

  static Widget cell(String text) {

    return Padding(

      padding: const EdgeInsets.all(10),

      child: Text(
        text,
        textAlign: TextAlign.center,
      ),

    );

  }

}

class HeaderCell extends StatelessWidget {

  final String text;

  const HeaderCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.all(10),

      child: Text(

        text,

        textAlign: TextAlign.center,

        style: const TextStyle(

          fontWeight: FontWeight.bold,

          fontSize: 15,

        ),

      ),

    );

  }

}