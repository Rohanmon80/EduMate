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

      title: Text("$subjectCode - $exam"),

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

            return ListView.builder(

              itemCount: students.docs.length,

              itemBuilder: (context,index){

                final s =
                students.docs[index].data()
                as Map<String,dynamic>;

                final done =
                uploaded.contains(
                    s["rollNumber"]);

                return ListTile(

                  leading:

                  CircleAvatar(

                    backgroundColor:
                    done
                        ? Colors.green
                        : Colors.red,

                    child: Icon(

                      done
                          ? Icons.check
                          : Icons.close,

                      color: Colors.white,

                    ),

                  ),

                  title: Text(
                    s["name"],
                  ),

                  subtitle: Text(
                    s["rollNumber"],
                  ),

                  trailing: Text(

                    done
                        ? "Uploaded"
                        : "Missing",

                    style: TextStyle(

                      color:
                      done
                          ? Colors.green
                          : Colors.red,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),

                );

              },

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