import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/excel_service.dart';
import 'excel_preview_page.dart';
class TeacherMarksPage extends StatefulWidget {

  const TeacherMarksPage({super.key});

  @override
  State<TeacherMarksPage> createState() =>
      _TeacherMarksPageState();
}

class _TeacherMarksPageState extends State<TeacherMarksPage> {

  String year = "1st";

  String department = "CSE";

  String section = "A";

  String semester = "1";

  String exam = "Mid 1";

  String subject = "";

  bool loading = false;

  List<DocumentSnapshot> students = [];

  final subjectController =
  TextEditingController();
  final ExcelService excelService = ExcelService();

  Map<String,
      TextEditingController>
  marksControllers = {};

  final exams = [

    "Mid 1",
    "Mid 2",
    "Sem External 1",
    "Sem External 2",
    "Lab Internal 1",
    "Lab Internal 2",
    "Lab External",
  ];

  Future<void>
  searchStudents() async {
    setState(() {
      loading = true;
    });

    final data =

    await FirebaseFirestore
        .instance
        .collection(
      "users",
    )

        .where(
      "role",
      isEqualTo:
      "student",
    )

        .where(
      "year",
      isEqualTo:
      year,
    )

        .where(
      "department",
      isEqualTo:
      department,
    )

        .where(
      "section",
      isEqualTo:
      section,
    )

        .where(
      "semester",
      isEqualTo:
      int.parse(
        semester,
      ),
    )

        .get();

    setState(() {
      students =
          data.docs;

      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark =

        Theme
            .of(context)
            .brightness ==

            Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      backgroundColor:

      isDark

          ? const Color(
        0xFF07111F,
      )

          : const Color(
        0xFFF4F8FC,
      ),

      appBar: AppBar(

        backgroundColor:
        Colors.transparent,

        elevation: 0,

        title: const Text(
          "Student Marks Management",
        ),
      ),

      body:

      Padding(

        padding:
        const EdgeInsets.all(
          18,
        ),

        child:
        Column(

          children: [

            glass(
              isDark,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Academic Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [

                      drop(
                          year,
                          [
                            "1st", "2nd", "3rd", "4th"
                          ],

                              (v) {
                            setState(() {
                              year = v!;
                            });
                          }
                      ),

                      drop(
                          department,

                          [

                            "CSE",
                            "CSM",
                            "AIML",
                            "ECE",
                            "EEE"
                          ],

                              (v) {
                            setState(() {
                              department = v!;
                            });
                          }
                      ),

                      drop(
                          section,

                          [

                            "A",
                            "B",
                            "C",
                            "D"
                          ],

                              (v) {
                            setState(() {
                              section = v!;
                            });
                          }
                      ),

                      drop(
                          semester,

                          [

                            "1", "2", "3", "4",
                            "5", "6", "7", "8"
                          ],

                              (v) {
                            setState(() {
                              semester = v!;
                            });
                          }
                      ),
                    ],
                  ),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(
                      hintText: "Subject Code (Example: CS501)",
                      prefixIcon: Icon(Icons.book),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField(
                    value: exam,
                    items: exams.map(
                          (e) =>
                          DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ),
                    ).toList(),
                    onChanged: (v) {
                      setState(() {
                        exam = v!;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),

                ],
              ),

            ),

            const SizedBox(
              height: 15,
            ),

            glass(
              isDark,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Excel Upload",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text("Download Excel Template"),
                    subtitle: const Text("Upload marks for the selected class"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {},
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text("Upload Excel"),
                    subtitle: const Text("Upload marks using Excel"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {

                        final rows = await excelService.pickExcel();

                        if (rows.isEmpty) return;

                        if (!context.mounted) return;

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExcelPreviewPage(rows: rows),
                          ),
                        );

                      }
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            glass(
              isDark,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Manual Entry",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Search students and enter marks manually.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text("Search Students"),
                      onPressed: loading
                          ? null
                          : () {
                        if (subjectController.text
                            .trim()
                            .isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please enter subject code"),
                            ),
                          );

                          return;
                        }

                        searchStudents();
                      },
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Expanded(
              child: loading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : students.isEmpty
                  ? const Center(
                child: Text("No Students Found"),
              )
                  : ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student =
                  students[index].data() as Map<String, dynamic>;

                  final uid = students[index].id;

                  marksControllers.putIfAbsent(
                    uid,
                        () => TextEditingController(),
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: studentCard(
                      student,
                      uid,
                      isDark,
                    ),
                  );
                },
              ),
            ),

          ], // closes children
        ), // closes Column
      ),
      // closes Padding

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF1976D2),
          icon: const Icon(Icons.save),
          label: const Text("Save Manual Marks"),
          onPressed: students.isEmpty
              ? null
              : () async {
            for (var e in marksControllers.entries) {
              final marks = int.tryParse(e.value.text);

              if (marks == null) continue;

              if (marks < 0 || marks > 100) continue;

              await FirebaseFirestore.instance
                  .collection("student_marks")
                  .doc("${e.key}_${subjectController.text.trim()}")
                  .set({
                "studentId": e.key,
                "year": year,
                "department": department,
                "section": section,
                "semester": int.parse(semester),
                "subject": subjectController.text.trim(),
                exam: e.value.text.trim(),
              }, SetOptions(merge: true));
            }

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text("Marks Uploaded Successfully"),
              ),
            );

            for (final controller in marksControllers.values) {
              controller.clear();
            }

            subjectController.clear();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    subjectController.dispose();

    for (final controller in marksControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Widget glass(bool dark,
      Widget child) {
    return ClipRRect(

      borderRadius:
      BorderRadius.circular(
        25,
      ),

      child:
      BackdropFilter(

        filter:
        ImageFilter.blur(

          sigmaX: 20,

          sigmaY: 20,
        ),

        child:
        Container(

          padding:
          const EdgeInsets.all(
            15,
          ),

          decoration:
          BoxDecoration(

            color:

            dark

                ?

            Colors.white
                .withOpacity(
              .08,
            )

                :

            Colors.white
                .withOpacity(
              .7,
            ),
          ),

          child:
          child,
        ),
      ),
    );
  }

  Widget studentCard(Map s,
      String uid,
      bool dark) {
    return glass(

      dark,

      ListTile(

        leading:

        CircleAvatar(

          child:
          Text(
            (s["name"] ?? "S").toString().substring(0, 1),
          ),
        ),

        title: Text(
          s["name"] ?? "Unknown Student",
        ),

        subtitle: Text(
      s["rollNumber"]?.toString() ?? "",
    ),

        trailing:

        SizedBox(

          width: 90,

          child:
          TextField(
            controller: marksControllers[uid],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: "0",
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),

      ),
    );

  }
  Widget drop(
      String value,
      List<String> items,
      Function(String?) f,
      ) {
    return SizedBox(
      width: 150,
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
        items: items
            .map(
              (e) => DropdownMenuItem<String>(
            value: e,
            child: Text(e),
          ),
        )
            .toList(),
        onChanged: f,
      ),
    );
  }

}



