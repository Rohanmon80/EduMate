import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class TeacherAttendancePage extends StatefulWidget {

  const TeacherAttendancePage({
    super.key,
  });

  @override
  State<TeacherAttendancePage>
  createState() =>
      _TeacherAttendancePageState();
}

class _TeacherAttendancePageState
    extends State<TeacherAttendancePage> {

  String year = "1st";

  String department = "CSE";

  String section = "A";

  final years = [
    "1st",
    "2nd",
    "3rd",
    "4th",
  ];

  final departments = [

    "CSE",

    "ECE",

    "EEE",

    "CSM",

    "AIML",

    "BCA",

    "BBA",

    "MBA",
  ];

  final sections = [

    "A",

    "B",

    "C",

    "D",
  ];

  final TextEditingController subjectController =
  TextEditingController();



  final searchController =
  TextEditingController();
  String teacherName = "";

  Map<String, bool> attendance = {};

  bool loadStudents = false;

  bool isSaving = false;

  @override
  void dispose() {
    subjectController.dispose();
    searchController.dispose();
    super.dispose();
  }
  Future<void> loadTeacherName() async {

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("teachers")
        .doc(uid)
        .get();

    if (!mounted)

      return;

    if (doc.exists) {
      setState(() {
        teacherName = doc.data()?["name"] ?? "Teacher";
      });
    }
  }
  @override
  void initState() {
    super.initState();
    loadTeacherName();
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

        leading:

        IconButton(

          icon:
          const Icon(
            Icons.arrow_back,
          ),

          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),

        title:
        const Text(
          "Mark Attendance",
        ),

        actions: [

          IconButton(

            onPressed: () {},

            icon:
            const Icon(
              Icons.notifications_none,
            ),
          ),
        ],
      ),

      body:

      Padding(

        padding:
        const EdgeInsets.all(
          20,
        ),

        child:
        Column(

          children: [

            Row(

              children: [

                Expanded(

                  child:

                  DropdownButtonFormField(

                    value:
                    year,

                    decoration:

                    const InputDecoration(

                      labelText:
                      "Year",
                    ),

                    items:

                    years.map(

                          (e) =>

                          DropdownMenuItem(

                            value: e,

                            child:
                            Text(e),
                          ),
                    )

                        .toList(),

                    onChanged:
                        (v) {
                      setState(() {
                        year = v!;
                        loadStudents = false;
                      });
                    },
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(

                  child:

                  DropdownButtonFormField(

                    value:
                    department,

                    decoration:

                    const InputDecoration(

                      labelText:
                      "Department",
                    ),

                    items:

                    departments.map(

                          (e) =>

                          DropdownMenuItem(

                            value: e,

                            child:
                            Text(e),
                          ),
                    )

                        .toList(),

                    onChanged:
                        (v) {
                      setState(() {
                        department = v!;
                        loadStudents = false;
                      });
                    },
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(

                  child:

                  DropdownButtonFormField(

                    value:
                    section,

                    decoration:

                    const InputDecoration(

                      labelText:
                      "Section",
                    ),

                    items:

                    sections.map(

                          (e) =>

                          DropdownMenuItem(

                            value: e,

                            child:
                            Text(e),
                          ),
                    )

                        .toList(),

                    onChanged:
                        (v) {
                      setState(() {
                        section = v!;
                        loadStudents = false;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),
            SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                attendance.clear();

                setState(() {
                  loadStudents = true;
                });
              },
            icon: const Icon(Icons.search),
            label: const Text("Load Class"),
            ),
            ),

            const SizedBox(height: 20),


            TextField(
              controller: subjectController,

              decoration: InputDecoration(
                labelText: "Subject Name",
                hintText: "Enter Subject (Example: DBMS)",

                prefixIcon: const Icon(Icons.menu_book),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),


            const SizedBox(
              height: 20,
            ),

            TextField(

              controller:
              searchController,

              decoration:
              InputDecoration(

                hintText:
                "Search student",

                prefixIcon:
                const Icon(
                  Icons.search,
                ),

                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(
                    30,
                  ),
                ),
              ),

              onChanged: (_) {
                setState(() {});
              },
            ),

            const SizedBox(
              height: 20,
            ),

            Expanded(

              child: !loadStudents

                  ? const Center(
                child: Text(
                  "Select Year, Department, Section\nand press Load Students",
                  textAlign: TextAlign.center,
                ),
              )

                  : FutureBuilder<QuerySnapshot>(

                future:

                FirebaseFirestore
                    .instance

        .collection("users")
        .where("role", isEqualTo: "student")
        .where("year", isEqualTo: year)
        .where("department", isEqualTo: department)
        .where("section", isEqualTo: section)
        .orderBy("rollNumber")
        .get(),

                builder:
                    (context,
                    snapshot,) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Error: ${snapshot.error}",
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text("No data found"),
                        );
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            "No students found for selected class",
                          ),
                        );
                      }

    List<QueryDocumentSnapshot> students =
    snapshot.data!.docs;

    students = students.where((doc) {

    final student =
    doc.data() as Map<String, dynamic>;

    final search =
    searchController.text.toLowerCase();

    return (student["name"] ?? "")
        .toString()
        .toLowerCase()
        .contains(search) ||

    (student["rollNumber"] ?? "")
        .toString()
        .toLowerCase()
        .contains(search);

    }).toList();
                      if (students.isEmpty) {
                        return const Center(
                          child: Text(
                            "No matching student found",
                          ),
                        );
                      }

                  return ListView.builder(

                    itemCount:
                    students.length,

                    itemBuilder:
                        (context,
                        index,) {
                      final student =

                      students[
                      index
                      ]
                          .data()

                      as Map<
                          String,
                          dynamic>;

                      final id =

                          students[
                          index
                          ].id;

                      attendance
                          .putIfAbsent(

                        id,

                            () => false,
                      );

                      return Card(

                        child:
                        ListTile(

                          leading:
                          CircleAvatar(

                            child:
                            Text(

                              student[
                              "name"
                              ] == null

                                  ? "S"

                                  : student[
                              "name"]
                                  .substring(
                                0,
                                1,
                              ),
                            ),
                          ),



                                title:
                                Text(
    "${student["rollNumber"]} - ${student["name"]}",
    ),

                          trailing:

                          Switch(

                            value:

                            attendance[
                            id] ??
                                false,

                            onChanged:
                                (v) {
                              setState(() {
                                attendance[
                                id] = v;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            SizedBox(

              width: double.infinity,

              height: 60,

              child: ElevatedButton(

                onPressed: () async {

                  if (isSaving) return;

                  setState(() {
                    isSaving = true;
                  });
                  int present = 0;

                  int absent = 0;
                  if (subjectController.text
                      .trim()
                      .isEmpty) {
                    setState(() {
                      isSaving = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter subject name"),
                      ),
                    );
                    return;
                  }
                  if (attendance.isEmpty) {

                    setState(() {
                      isSaving = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(

                      const SnackBar(
                        content: Text("Load students first"),
                      ),
                    );

                    return;
                  }

                  for (
                  var e
                  in attendance.entries
                  ) {
                    String uid =
                        e.key;

                    bool isPresent =
                        e.value;

                    final userDoc =

                    await FirebaseFirestore
                        .instance
                        .collection(
                        "users")
                        .doc(uid)
                        .get();

                    final data =

                    userDoc.data()

                    as Map<
                        String,
                        dynamic>;

                    int totalClasses =

                        data[
                        "totalClasses"
                        ] ?? 0;

                    int attendedClasses =

                        data[
                        "attendedClasses"
                        ] ?? 0;

                    totalClasses++;

                    if (
                    isPresent
                    ) {
                      present++;

                      attendedClasses++;
                    }

                    else {
                      absent++;
                    }

                    double attendancePercent =

                    totalClasses == 0

                        ? 0

                        :

                    (attendedClasses
                        /

                        totalClasses)

                        * 100;

                    await FirebaseFirestore
                        .instance
                        .collection(
                        "users")
                        .doc(uid)

                        .update({

                      "attendance":
                      attendancePercent,

                      "totalClasses":
                      totalClasses,

                      "attendedClasses":
                      attendedClasses,
                    });

                    await FirebaseFirestore
                        .instance
                        .collection(
                        "attendance_history")

                        .add({

                      "studentId":
                      uid,
                      "studentName": data["name"],

                      "present":
                      isPresent,

                      "day":

                      DateTime
                          .now()
                          .weekday,

                      "date":
                      Timestamp.now(),

                      "subject":
                      subjectController.text.trim(),

                      "teacher":
                      teacherName,
                    });
                  }

                  if (
                  mounted
                  ) {
    attendance.clear();

    subjectController.clear();

    searchController.clear();

    loadStudents = false;

    setState(() {});
    setState(() {
      isSaving = false;
    });
                    showDialog(

                      context:
                      context,

                      builder:
                          (_) {
                        return AlertDialog(

                          title:
                          const Text(
                            "Attendance Saved",
                          ),

                          content:

                          Text(

                            "Present : $present\n\nAbsent : $absent",
                          ),

                          actions: [

                            TextButton(

                              onPressed: () {
                                Navigator.pop(
                                  context,
                                );
                              },

                              child:
                              const Text(
                                "OK",
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },

                child: isSaving
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text("Save Attendance"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}