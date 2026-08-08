import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoSummaryCard extends StatelessWidget {
  const MemoSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Text("Student not logged in");
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("students")
          .doc(uid)
          .get(),
      builder: (context, studentSnapshot) {
        if (studentSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!studentSnapshot.hasData ||
            !studentSnapshot.data!.exists) {
          return const Text("Student details not found");
        }

        final studentData =
        studentSnapshot.data!.data()
        as Map<String, dynamic>;

        final cgpa =
            (studentData["cgpa"] as num?)?.toDouble() ?? 0.0;

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection("student_marks")
              .where(
            "studentId",
            isEqualTo: uid,
          )
              .where(
            "released",
            isEqualTo: true,
          )
              .get(),
          builder: (context, marksSnapshot) {
            if (marksSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!marksSnapshot.hasData) {
              return const Text(
                "No result data available",
              );
            }

            final docs = marksSnapshot.data!.docs;

            return _buildSummary(
              cgpa,
              docs,
            );
          },
        );
      },
    );
  }

  Widget _buildSummary(
      double cgpa,
      List<QueryDocumentSnapshot> docs,
      ) {
    double totalCredits = 0;

    for (final doc in docs) {
      final data =
      doc.data() as Map<String, dynamic>;

      final credits =
          (data["credits"] as num?)?.toDouble() ?? 0;

      totalCredits += credits;
    }

    final result =
    docs.isEmpty ? "NO RESULT" : "PASS";

    return Column(
      children: [
        const Divider(
          thickness: 2,
        ),

        const SizedBox(height: 20),

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
                    "Calculating...",
                  ),

                  summaryRow(
                    "CGPA",
                    cgpa.toStringAsFixed(2),
                  ),

                  summaryRow(
                    "Overall Result",
                    result,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 40),

            Column(
              children: [
                const SizedBox(height: 60),

                Container(
                  width: 180,
                  height: 1,
                  color: Colors.black,
                ),

                const SizedBox(height: 8),

                const Text(
                  "Controller of Examinations",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget summaryRow(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Text(" : "),

          Text(value),
        ],
      ),
    );
  }
}