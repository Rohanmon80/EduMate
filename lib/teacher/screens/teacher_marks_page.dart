import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/excel_service.dart';
import 'excel_preview_page.dart';

import '../../services/excel_subject_service.dart';
class TeacherMarksPage extends StatefulWidget {

  const TeacherMarksPage({super.key});

  @override
  State<TeacherMarksPage> createState() =>
      _TeacherMarksPageState();
}

class _TeacherMarksPageState extends State<TeacherMarksPage> {

  bool loading = false;

  List<DocumentSnapshot> students = [];

  String? selectedSubject;
  String? selectedSubjectName;
  String exam = "Mid 1";
  final rollNumberController = TextEditingController();
  final ExcelService excelService = ExcelService();

  final ExcelSubjectService templateService =
  ExcelSubjectService();

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
  Future<void> searchStudents() async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    final data = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "student")
        .where(
      "rollNumber",
      isEqualTo: rollNumberController.text.trim(),
    )
        .get();

    setState(() {
      students = data.docs;
      loading = false;
    });

    if (data.docs.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Student not found"),
        ),
      );
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
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [

            // Student Details Card

            glass(
              isDark,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Student Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: rollNumberController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) {
                      if (selectedSubject != null) {
                        searchStudents();
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: "Roll Number",
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Subject dropdown will come in Step 2

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("subjects")
                        .snapshots(),
                    builder: (context, snapshot) {

                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedSubject,
                        decoration: const InputDecoration(
                          labelText: "Select Subject",
                          prefixIcon: Icon(Icons.menu_book),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),

                        items: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          return DropdownMenuItem<String>(
                            value: data["subjectCode"],
                            child: Text(
                              "${data["subjectCode"]} - ${data["subjectName"]}",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),

                        selectedItemBuilder: (context) {
                          return snapshot.data!.docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;

                            return Text(
                              data["subjectCode"],
                              overflow: TextOverflow.ellipsis,
                            );
                          }).toList();
                        },

                        onChanged: (value) {
                          final doc = snapshot.data!.docs.firstWhere(
                                (e) =>
                            (e.data() as Map<String, dynamic>)["subjectCode"] == value,
                          );

                          final subject = doc.data() as Map<String, dynamic>;

                          setState(() {
                            selectedSubject = subject["subjectCode"];
                            selectedSubjectName = subject["subjectName"];
                            students.clear();

                            for (final controller in marksControllers.values) {
                              controller.dispose();
                            }

                            marksControllers.clear();
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: exam,
                    decoration: const InputDecoration(
                      labelText: "Exam",
                      prefixIcon: Icon(Icons.assignment),
                      border: OutlineInputBorder(),
                    ),
                    items: exams
                        .map(
                          (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        exam = v!;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text("Search Student"),
                      onPressed: () {

                        if (rollNumberController.text.trim().isEmpty ||
                            selectedSubject == null) {

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Enter Roll Number and Select Subject",
                              ),
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

            const SizedBox(height: 20),

            // Excel Card

            glass(
              isDark,
              Column(
                children: [

                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text("Download Excel Template"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await templateService.downloadTemplate();
                    },
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(Icons.upload_file),
                    title: const Text("Upload Excel"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {

                      final rows = await excelService.pickExcel();

                      if (rows.isEmpty) return;

                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExcelPreviewPage(
                            rows: rows,
                          ),
                        ),
                      );

                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: loading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : students.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school,
                      size: 70,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Search a student to enter marks",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {

                  final student =
                  students[index].data()
                  as Map<String, dynamic>;

                  final uid =
                      students[index].id;

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

          ],
        ),
      ),

    floatingActionButton: Padding(
    padding: const EdgeInsets.only(bottom: 80),
    child: FloatingActionButton.extended(
    backgroundColor: const Color(0xFF1976D2),
    icon: const Icon(Icons.save),
    label: const Text("Save Manual Marks"),
      onPressed: students.isEmpty || selectedSubject == null
    ? null
        : () async {
    for (var e in marksControllers.entries) {
    final marks = int.tryParse(e.value.text);

    if (marks == null) continue;

    if (marks < 0 || marks > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Marks must be between 0 and 100"),
        ),
      );
      return;
    }
    final student =
    students.firstWhere((s) => s.id == e.key);

    final data =
    student.data() as Map<String, dynamic>;

    await FirebaseFirestore.instance
        .collection("student_marks")
        .doc("${e.key}_${selectedSubject}_$exam")
        .set({
      "studentId": e.key,
      "rollNumber": data["rollNumber"],
      "studentName": data["name"],
      "year": data["year"],
      "department": data["department"],
      "section": data["section"],
      "semester": data["semester"],
      "subjectCode": selectedSubject,
      "subjectName": selectedSubjectName,
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

    setState(() {
      selectedSubject = null;
      selectedSubjectName = null;
      students.clear();
    });

    rollNumberController.clear();
    },
    ),
    ),
    );
  }

  @override
  void dispose() {
    rollNumberController.dispose();

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
          padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
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

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              s["rollNumber"]?.toString() ?? "",
            ),

            const SizedBox(height: 3),

            Text(
              "${s["department"]} | ${s["year"]} Year | Semester ${s["semester"]}",
              style: const TextStyle(
                fontSize: 12,
              ),
            ),

          ],
        ),

        trailing:

        SizedBox(
          width: 85,
          child: TextField(
            controller: marksControllers[uid],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              labelText: "Marks",
              isDense: true,
              border: OutlineInputBorder(),
            ),
          ),
        ),



      ),
    );

  }
}





