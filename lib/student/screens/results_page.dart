import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  int? selectedSemester;

  @override
  Widget build(
      BuildContext context){

    final isDark=

        Theme.of(context)
            .brightness==

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

        elevation:0,

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

                    (i)=>DropdownMenuItem(

                  value: i+1,

                  child: Text(
                    "Semester ${i+1}",
                  ),

                ),

              ),

              onChanged: (value){

                setState(() {

                  selectedSemester=value;

                });

              },

            ),

            const SizedBox(height:20),

            if(selectedSemester==null)

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

                  builder:(context,snapshot){

                    if(!snapshot.hasData){

                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );

                    }

                    if(snapshot.data!.docs.isEmpty){

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
                    return ListView(

                      children: grouped.entries.map((entry) {

                        final list = entry.value;
                        final first = list.first;

                        return Card(

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

                                const SizedBox(height: 10),

                                const Text(
                                  "Result calculation coming in Part 2",
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

