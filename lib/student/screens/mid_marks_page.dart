import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MidMarksPage extends StatefulWidget {
  const MidMarksPage({super.key});

  @override
  State<MidMarksPage> createState() => _MidMarksPageState();
}

class _MidMarksPageState extends State<MidMarksPage> {

  int? selectedSemester;
  String? selectedExam;

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Mid Exam Marks"),
        centerTitle: true,
      ),

      body: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          children: [

            DropdownButtonFormField<int>(

              decoration: const InputDecoration(

                labelText: "Select Semester",

                border: OutlineInputBorder(),

              ),

              value: selectedSemester,

              items: List.generate(
                8,
                    (index) => DropdownMenuItem(
                  value: index + 1,
                  child: Text(
                    "Semester ${index + 1}",
                  ),
                ),
              ),

              onChanged: (value) {

                setState(() {

                  selectedSemester = value;

                });

              },

            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(

              decoration: const InputDecoration(

                labelText: "Select Mid Exam",

                border: OutlineInputBorder(),

              ),

              value: selectedExam,

              items: const [

                DropdownMenuItem(
                  value: "Mid 1",
                  child: Text("Mid 1"),
                ),

                DropdownMenuItem(
                  value: "Mid 2",
                  child: Text("Mid 2"),
                ),

              ],

              onChanged: (value) {

                setState(() {

                  selectedExam = value;

                });

              },

            ),

            const SizedBox(height: 20),

            if (selectedSemester == null ||
                selectedExam == null)

              const Expanded(

                child: Center(

                  child: Text(

                    "Select Semester and Mid Exam",

                    style: TextStyle(
                      fontSize: 18,
                    ),

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
                    isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                  )

                      .where(
                    "semester",
                    isEqualTo: selectedSemester,
                  )

                      .where(
                    "exam",
                    isEqualTo: selectedExam,
                  )

                      .where(
                    "released",
                    isEqualTo: true,
                  )

                      .snapshots(),

                  builder: (context, snapshot) {

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {

                      return const Center(
                        child: CircularProgressIndicator(),
                      );

                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {

                      return const Center(

                        child: Text(

                          "No Marks Released Yet",

                          style: TextStyle(
                            fontSize: 18,
                          ),

                        ),

                      );

                    }

                    return ListView.builder(

                      itemCount:
                      snapshot.data!.docs.length,

                      itemBuilder: (context, index) {

                        final data =
                        snapshot.data!.docs[index].data()
                        as Map<String, dynamic>;

                        return Card(

                          margin:
                          const EdgeInsets.only(bottom: 15),

                          elevation: 4,

                          shape: RoundedRectangleBorder(

                            borderRadius:
                            BorderRadius.circular(15),

                          ),

                          child: Padding(

                            padding:
                            const EdgeInsets.all(16),

                            child: Column(

                              crossAxisAlignment:
                              CrossAxisAlignment.start,

                              children: [

                                Text(

                                  data["subjectName"],

                                  style: const TextStyle(

                                    fontSize: 20,

                                    fontWeight:
                                    FontWeight.bold,

                                  ),

                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "Subject Code : ${data["subjectCode"]}",
                                ),

                                Text(
                                  "Marks : ${data["marks"]}",
                                ),

                                Text(
                                  "Teacher : ${data["teacherName"]}",
                                ),

                                const SizedBox(height: 10),

                                Row(

                                  children: const [

                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),

                                    SizedBox(width: 8),

                                    Text(
                                      "Released",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                  ],

                                ),

                              ],

                            ),

                          ),

                        );

                      },

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