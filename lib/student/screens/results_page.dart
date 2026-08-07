import 'dart:ui';
import '../../services/subject_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  Map<String, double> subjectCredits = {};
  bool creditsLoaded = false;
  final SubjectService subjectService = SubjectService();
  int? selectedSemester;
  @override
  void initState() {
    super.initState();
    loadCredits();
  }
  Future<void> loadCredits() async {

    final snapshot = await FirebaseFirestore.instance
        .collection("subjects")
        .get();

    subjectCredits.clear();

    for (final doc in snapshot.docs) {

      final data = doc.data();

      subjectCredits[data["subjectCode"]] =
          (data["credits"] as num).toDouble();
    }

    if (mounted) {
      setState(() {
        creditsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark =

        Theme
            .of(context)
            .brightness ==

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

      appBar: AppBar(

        backgroundColor:
        Colors.transparent,

        elevation: 0,

        title:
        const Text(
          "Results",
        ),
      ),

      body: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            DropdownButtonFormField<int>(

              value: selectedSemester,

              decoration: const InputDecoration(

                labelText: "Semester",

                border: OutlineInputBorder(),

              ),

              items: List.generate(

                8,

                    (i) =>
                    DropdownMenuItem(

                      value: i + 1,

                      child: Text(
                        "Semester ${i + 1}",
                      ),

                    ),

              ),

              onChanged: (value) {
                setState(() {
                  selectedSemester = value;
                });
              },

            ),

            const SizedBox(height: 20),

            if(selectedSemester == null)

              const Expanded(

                child: Center(

                  child: Text(
                    "Select Semester",
                  ),

                ),

              )

            else
              Expanded(

                child: StreamBuilder<QuerySnapshot>(

                  stream: FirebaseFirestore.instance

                      .collection("student_marks")

                      .where(
                    "studentId",
                    isEqualTo:
                    FirebaseAuth.instance.currentUser!.uid,
                  )

                      .where(
                    "semester",
                    isEqualTo: selectedSemester,
                  )

                      .where(
                    "released",
                    isEqualTo: true,
                  )

                      .snapshots(),

                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child:
                        Text(
                          "No Results Released",
                        ),
                      );
                    }
                    final docs = snapshot.data!.docs;

                    Map<String, List<Map<String, dynamic>>> grouped = {};

                    for (final doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;

                      grouped.putIfAbsent(
                        data["subjectCode"],
                            () => [],
                      );

                      grouped[data["subjectCode"]]!.add(data);
                    }
                    double totalCreditPoints = 0;
                    double totalCredits = 0;
                    return ListView(

                      children: grouped.entries.map((entry) {
                        final list = entry.value;
                        final first = list.first;
                        double internal1 = 0;
                        double internal2 = 0;
                        double external = 0;

                        bool isTheory = true;

                        for (final item in list) {

                          if (item["type"] == "Lab") {
                            isTheory = false;
                          }

                          switch (item["exam"]) {

                            case "Mid 1":
                              internal1 = (item["marks"] as num).toDouble();
                              break;

                            case "Mid 2":
                              internal2 = (item["marks"] as num).toDouble();
                              break;

                            case "Sem External":
                              external = (item["marks"] as num).toDouble();
                              break;

                            case "Lab Internal 1":
                              internal1 = (item["marks"] as num).toDouble();
                              break;

                            case "Lab Internal 2":
                              internal2 = (item["marks"] as num).toDouble();
                              break;

                            case "Lab External":
                              external = (item["marks"] as num).toDouble();
                              break;
                          }
                        }

                        final average = (internal1 + internal2) / 2;
                        final total = average + external;
                        final pass = average >= 14 && total >= 40;
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

                        return Card(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          margin: const EdgeInsets.only(bottom: 15),

                          child: Padding(

                            padding: const EdgeInsets.all(16),

                            child: Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Text(
                                  first["subjectName"],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "Subject Code : ${first["subjectCode"]}",
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  isTheory
                                      ? "Average Mid : ${average.toStringAsFixed(1)}"
                                      : "Average Internal : ${average.toStringAsFixed(1)}",
                                ),

                                Text(
                                  isTheory
                                      ? "Semester External : $external"
                                      : "Lab External : $external",
                                ),

                                Text(
                                  "Total : ${total.toStringAsFixed(1)}",
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "Grade : $grade",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                Text(
                                  "Grade Point : $gradePoint",
                                ),

                                Builder(
                                  builder: (context) {

                                    final credits =
                                        subjectCredits[first["subjectCode"]] ?? 0;

                                    totalCredits += credits;
                                    totalCreditPoints += credits * gradePoint;

                                    return Text(
                                      "Credits : $credits",
                                    );
                                  },
                                ),



                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: pass ? Colors.green : Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    pass ? "PASS" : "FAIL",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                              ],

                            ),

                          ),

                        );
                      }).toList(),

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
