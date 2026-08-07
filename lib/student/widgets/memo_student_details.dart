import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/memo_service.dart';
class MemoStudentDetails extends StatelessWidget {
  const MemoStudentDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(

      future: FirebaseFirestore.instance
          .collection("students")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),

      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final student =
        snapshot.data!.data() as Map<String, dynamic>;

        return Row(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Container(

              width: 130,
              height: 160,

              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
              ),

              child: student["photoUrl"] == null ||
                  student["photoUrl"].toString().isEmpty

                  ? const Icon(
                Icons.person,
                size: 80,
              )

                  : Image.network(
                student["photoUrl"],
                fit: BoxFit.cover,
              ),

            ),

            // Student Details

          ],

        );

      },

    );


    return Row(


      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Container(

          width: 130,
          height: 160,

          decoration: BoxDecoration(

            border: Border.all(
              color: Colors.black,
            ),

          ),

          child: const Icon(

            Icons.person,

            size: 80,

            color: Colors.grey,

          ),

        ),

        const SizedBox(width: 30),

        Expanded(

          child: Column(

            children: [

              detailRow(
                "Student Name",
                student["name"] ?? "",
              ),

              detailRow(
                "Roll Number",
                student["rollNumber"] ?? "",
              ),

              detailRow(
                "Department",
                student["department"] ?? "",
              ),

              detailRow(
                "Semester",
                student["semester"].toString(),
              ),
              detailRow(
                "Year",
                student["year"] ?? "",
              ),

              detailRow(
                "Section",
                student["section"] ?? "",
              ),

            ],

          ),

        ),

      ],

    );

  }

  Widget detailRow(String title, String value) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 10),

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

          Expanded(

            child: Text(value),

          ),

        ],

      ),

    );

  }

}