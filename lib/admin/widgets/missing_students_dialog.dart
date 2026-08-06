import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MissingStudentsDialog extends StatelessWidget {

  final String subjectCode;
  final String exam;
  final String department;
  final String year;
  final int semester;
  final String section;

  const MissingStudentsDialog({
    super.key,
    required this.subjectCode,
    required this.exam,
    required this.department,
    required this.year,
    required this.semester,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {

    return AlertDialog(

      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            subjectCode,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            exam,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),

        ],
      ),

      content: SizedBox(

        width: 700,
        height: 500,

        child: FutureBuilder(

          future: Future.wait([

            FirebaseFirestore.instance
                .collection("users")
                .where("role", isEqualTo: "student")
                .where("department", isEqualTo: department)
                .where("year", isEqualTo: year)
                .where("semester", isEqualTo: semester)
                .where("section", isEqualTo: section)
                .get(),

            FirebaseFirestore.instance
                .collection("student_marks")
                .where("subjectCode", isEqualTo: subjectCode)
                .where("exam", isEqualTo: exam)
                .where("department", isEqualTo: department)
                .where("year", isEqualTo: year)
                .where("semester", isEqualTo: semester)
                .where("section", isEqualTo: section)
                .get(),

          ]),

          builder: (context, snapshot) {

            if (!snapshot.hasData) {

              return const Center(
                child: CircularProgressIndicator(),
              );

            }

            final students =
            snapshot.data![0] as QuerySnapshot;

            final marks =
            snapshot.data![1] as QuerySnapshot;

            final uploaded = marks.docs
                .map((e) =>
            (e.data()
            as Map<String,dynamic>)["rollNumber"])
                .toSet();

            final uploadedCount =
                uploaded.length;

            final missingCount =
                students.docs.length -
                    uploadedCount;

            return Column(

              children: [

                Container(

                  padding: const EdgeInsets.all(10),

                  decoration: BoxDecoration(

                    color: Colors.blue.shade50,

                    borderRadius:
                    BorderRadius.circular(10),

                  ),

                  child: Row(

                    mainAxisAlignment:
                    MainAxisAlignment.spaceAround,

                    children: [

                      Text(
                        "Uploaded : $uploadedCount",
                      ),

                      Text(
                        "Missing : $missingCount",
                      ),

                    ],

                  ),

                ),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    itemCount: students.docs.length,
                    itemBuilder: (context, index) {

                      final s =
                      students.docs[index].data()
                      as Map<String, dynamic>;

                      final done =
                      uploaded.contains(s["rollNumber"]);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          done ? Colors.green : Colors.red,
                          child: Icon(
                            done ? Icons.check : Icons.close,
                            color: Colors.white,
                          ),
                        ),

                        title: Text(s["name"]),

                        subtitle: Text(s["rollNumber"]),

                        trailing: Text(
                          done
                              ? "✓ Uploaded"
                              : "❌ Missing",
                          style: TextStyle(
                            color:
                            done ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),

              ],

            );


          },

        ),

      ),

      actions: [

        TextButton(

          onPressed: (){
            Navigator.pop(context);
          },

          child: const Text("Close"),

        ),

      ],

    );

  }

}