import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/excel_service.dart';
import 'excel_preview_page.dart';
import 'package:firebase_auth/firebase_auth.dart';


class TeacherMarksPage extends StatefulWidget {

  const TeacherMarksPage({super.key});

  @override
  State<TeacherMarksPage> createState() =>
      _TeacherMarksPageState();
}

class _TeacherMarksPageState extends State<TeacherMarksPage> {


  bool loading = false;

  List<DocumentSnapshot> students = [];
  String teacherUid = "";
  String teacherName = "";
  String teacherDepartment = "";

  String? selectedSubject;
  String? selectedSubjectName;
  String subjectType = "";
  String exam = "Mid 1";
  final rollNumberController = TextEditingController();
  final ExcelService excelService = ExcelService();



  Map<String,
      TextEditingController>
  marksControllers = {};

  List<String> get exams {

    if(subjectType=="Lab"){

      return [

        "Lab Internal 1",

        "Lab Internal 2",

        "Lab External",

      ];

    }

    return [

      "Mid 1",

      "Mid 2",

      "Sem External",

    ];

  }
  Future<void> loadTeacher() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    teacherUid = user.uid;

    final teacher = await FirebaseFirestore.instance
        .collection("teachers")
        .doc(user.uid)
        .get();

    if (teacher.exists) {

      final data = teacher.data()!;

      teacherName = data["name"] ?? "";

      teacherDepartment =
          data["department"] ?? "";

      setState(() {});
    }
  }
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            140,
          ),
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
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

                      final subjects = snapshot.data!.docs;

                      return Autocomplete<Map<String, dynamic>>(

                        optionsBuilder: (TextEditingValue textEditingValue) {

                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<Map<String, dynamic>>.empty();
                          }

                          return subjects
                              .map((e) => e.data() as Map<String, dynamic>)
                              .where((subject) {

                            final code = subject["subjectCode"]
                                .toString()
                                .toLowerCase();

                            final name = subject["subjectName"]
                                .toString()
                                .toLowerCase();

                            final search =
                            textEditingValue.text.toLowerCase();

                            return code.contains(search) ||
                                name.contains(search);

                          });

                        },

                        displayStringForOption: (subject) =>
                        subject["subjectCode"],

                        fieldViewBuilder: (
                            context,
                            controller,
                            focusNode,
                            onFieldSubmitted,
                            ) {

                          return TextField(

                            controller: controller,

                            focusNode: focusNode,

                            decoration: const InputDecoration(

                              labelText: "Subject Code",

                              hintText: "Type Subject Code",

                              prefixIcon: Icon(Icons.search),

                              border: OutlineInputBorder(),

                            ),

                          );

                        },

                        optionsViewBuilder: (
                            context,
                            onSelected,
                            options,
                            ) {

                          return Align(

                            alignment: Alignment.topLeft,

                            child: Material(

                              elevation: 4,

                              child: SizedBox(

                                width: 400,

                                child: ListView.builder(

                                  padding: EdgeInsets.zero,

                                  shrinkWrap: true,

                                  itemCount: options.length,

                                  itemBuilder: (context, index) {

                                    final subject =
                                    options.elementAt(index);

                                    return ListTile(

                                      title: Text(
                                        subject["subjectCode"],
                                      ),

                                      subtitle: Text(
                                        subject["subjectName"],
                                      ),

                                      onTap: () {

                                        onSelected(subject);

                                      },

                                    );

                                  },

                                ),

                              ),

                            ),

                          );

                        },

                        onSelected: (subject) {

                          setState(() {

                            selectedSubject = subject["subjectCode"];
                            selectedSubjectName = subject["subjectName"];
                            subjectType = subject["type"];

                            exam = subjectType == "Lab"
                                ? "Lab Internal 1"
                                : "Mid 1";

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
                    value: exam,
                    decoration: const InputDecoration(
                      labelText: "Exam",
                      prefixIcon: Icon(Icons.assignment),
                      border: OutlineInputBorder(),
                    ),
                    items: exams.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
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
                      await excelService.downloadMarksTemplate();
                    },
                  ),

                  const Divider(),

                  ListTile(
                    leading: const Icon(
                      Icons.upload_file,
                    ),
                    title: const Text(
                      "Upload Excel",
                    ),
                    subtitle: const Text(
                      "Upload marks for multiple students",
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                    ),
                    onTap: () async {
                      try {
                        final rows =
                        await excelService.pickExcel();

                        if (rows.isEmpty) {
                          return;
                        }

                        if (!context.mounted) {
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ExcelPreviewPage(
                                  rows: rows,
                                  teacherId:
                                  teacherUid,
                                  teacherName:
                                  teacherName,
                                ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            backgroundColor:
                            Colors.red,
                            content: Text(
                              "Unable to open Excel file: $e",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

                loading
                    ? const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
                    : students.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school,
                          size: 70,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Text(
                          "Search a student to enter marks",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
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
                      padding:
                      const EdgeInsets.only(bottom: 10),
                      child: studentCard(
                        student,
                        uid,
                        isDark,
                      ),
                    );
                  },
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
          // --------------------------------------------------------
          // 1. Validate that every displayed student has marks
          // --------------------------------------------------------

          for (final student in students) {
            final controller =
            marksControllers[student.id];

            if (controller == null ||
                controller.text.trim().isEmpty) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    "Enter marks for all students before saving.",
                  ),
                ),
              );

              return;
            }

            final marks =
            int.tryParse(controller.text.trim());

            if (marks == null ||
                marks < 0 ||
                marks > 100) {
              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    "Marks must be between 0 and 100.",
                  ),
                ),
              );

              return;
            }
          }

          // --------------------------------------------------------
          // 2. Get subject information ONCE from Firebase
          // --------------------------------------------------------

          final subjectSnapshot =
          await FirebaseFirestore.instance
              .collection("subjects")
              .where(
            "subjectCode",
            isEqualTo: selectedSubject,
          )
              .limit(1)
              .get();

          if (!mounted) return;

          if (subjectSnapshot.docs.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                  "Subject $selectedSubject was not found.",
                ),
              ),
            );

            return;
          }

          final subjectData =
          subjectSnapshot.docs.first.data();

          // --------------------------------------------------------
          // 3. Firebase is the source of truth
          // --------------------------------------------------------

          final firebaseSemester =
          (subjectData["semester"] as num?)
              ?.toInt();

          final credits =
          (subjectData["credits"] as num?)
              ?.toDouble();

          final firebaseSubjectName =
              subjectData["subjectName"]
                  ?.toString() ??
                  "";

          final firebaseSubjectType =
              subjectData["type"]
                  ?.toString() ??
                  "";

          if (firebaseSemester == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.red,
                content: Text(
                  "Selected subject does not have a valid semester.",
                ),
              ),
            );

            return;
          }

          // --------------------------------------------------------
          // 4. Save each student's marks
          // --------------------------------------------------------

          for (final student in students) {
            final uid = student.id;

            final controller =
            marksControllers[uid]!;

            final marks =
            int.parse(
              controller.text.trim(),
            );

            final data =
            student.data()
            as Map<String, dynamic>;

            // Keep manual and Excel document IDs consistent.
            final safeExam =
            exam.replaceAll(
              RegExp(r'[^a-zA-Z0-9]+'),
              '_',
            );

            const safeCategory = "Regular";

            final documentId =
                "${uid}_${selectedSubject}_${safeExam}_$safeCategory";

            await FirebaseFirestore.instance
                .collection("student_marks")
                .doc(documentId)
                .set(
              {
                // Student information
                "studentId": uid,
                "rollNumber": data["rollNumber"],
                "studentName": data["name"],
                "department": data["department"],
                "year": data["year"],
                "section": data["section"],

                // IMPORTANT:
                // Semester comes from Firebase SUBJECT.
                "semester": firebaseSemester,

                // Subject information from Firebase
                "subjectCode": selectedSubject,
                "subjectName": firebaseSubjectName,
                "type": firebaseSubjectType,
                "credits": credits,

                // Exam information
                "exam": exam,
                "examCategory": "Regular",
                "marks": marks,

                // Teacher information
                "teacherId": teacherUid,
                "teacherName": teacherName,

                // Status
                "released": false,
                "uploadedAt":
                FieldValue.serverTimestamp(),
                "uploadedBy": "teacher",
                "uploadMethod": "manual",
              },
              SetOptions(merge: true),
            );
          }

          // --------------------------------------------------------
          // 5. Success
          // --------------------------------------------------------

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.green,
              content: Text(
                "Marks uploaded successfully.",
              ),
            ),
          );

          for (final controller
          in marksControllers.values) {
            controller.dispose();
          }

          marksControllers.clear();

          setState(() {
            selectedSubject = null;
            selectedSubjectName = null;
            subjectType = "";
            exam = "Mid 1";
            students.clear();
          });

          rollNumberController.clear();
        },
    ),
    ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadTeacher();
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

          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: .08)
                : Colors.white.withValues(alpha: .7),
            borderRadius: BorderRadius.circular(25),
          ),
          child: child,
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





