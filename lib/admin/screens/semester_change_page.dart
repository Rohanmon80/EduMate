import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SemesterChangePage extends StatefulWidget {
  const SemesterChangePage({super.key});

  @override
  State<SemesterChangePage> createState() =>
      _SemesterChangePageState();
}

class _SemesterChangePageState
    extends State<SemesterChangePage> {

  int currentSemester = 1;
  int newSemester = 2;

  String selectedDepartment = "All";
  String selectedYear = "All";
  String selectedSection = "All";

  bool loading = false;

  int getYearFromSemester(int semester) {
    if (semester <= 2) {
      return 1;
    }

    if (semester <= 4) {
      return 2;
    }

    if (semester <= 6) {
      return 3;
    }

    return 4;
  }

  String getYearText(int semester) {
    final year =
    getYearFromSemester(semester);

    switch (year) {
      case 1:
        return "1st";
      case 2:
        return "2nd";
      case 3:
        return "3rd";
      default:
        return "4th";
    }
  }

  Future<int> countStudents() async {
    Query<Map<String, dynamic>> query =
    FirebaseFirestore.instance
        .collection("users")
        .where(
      "role",
      isEqualTo: "student",
    )
        .where(
      "semester",
      isEqualTo: currentSemester,
    );

    if (selectedDepartment != "All") {
      query = query.where(
        "department",
        isEqualTo: selectedDepartment,
      );
    }

    if (selectedYear != "All") {
      query = query.where(
        "year",
        isEqualTo: selectedYear,
      );
    }

    if (selectedSection != "All") {
      query = query.where(
        "section",
        isEqualTo: selectedSection,
      );
    }

    final snapshot =
    await query.get();

    return snapshot.docs.length;
  }

  Future<void> changeSemester() async {
    if (currentSemester == newSemester) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Current and new semester cannot be the same.",
          ),
        ),
      );

      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Confirm Semester Change",
          ),

          content: Text(
            "Move students from Semester "
                "$currentSemester to Semester "
                "$newSemester?\n\n"
                "Their academic year will also be updated.",
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text("Continue"),
            ),

          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      loading = true;
    });

    try {

      Query<Map<String, dynamic>> query =
      FirebaseFirestore.instance
          .collection("users")
          .where(
        "role",
        isEqualTo: "student",
      )
          .where(
        "semester",
        isEqualTo: currentSemester,
      );

      if (selectedDepartment != "All") {
        query = query.where(
          "department",
          isEqualTo: selectedDepartment,
        );
      }

      if (selectedYear != "All") {
        query = query.where(
          "year",
          isEqualTo: selectedYear,
        );
      }

      if (selectedSection != "All") {
        query = query.where(
          "section",
          isEqualTo: selectedSection,
        );
      }

      final snapshot =
      await query.get();

      if (snapshot.docs.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              "No students found.",
            ),
          ),
        );

        return;
      }

      final batch =
      FirebaseFirestore.instance.batch();

      final newYear =
      getYearText(newSemester);

      for (final student
      in snapshot.docs) {

        batch.update(
          student.reference,
          {
            "semester": newSemester,
            "year": newYear,
            "semesterUpdatedAt":
            FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "${snapshot.docs.length} student(s) moved to "
                "Semester $newSemester.",
          ),
        ),
      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Unable to change semester: $e",
          ),
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      appBar: AppBar(
        title: const Text(
          "Semester Management",
        ),
        backgroundColor:
        Colors.transparent,
        elevation: 0,
      ),

      body: SingleChildScrollView(

        padding:
        const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            const Text(
              "Change Student Semester",
              style: TextStyle(
                fontSize: 28,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Use this when the college moves students to the next semester.",
              style: TextStyle(
                color: isDark
                    ? Colors.white70
                    : Colors.black54,
              ),
            ),

            const SizedBox(height: 30),

            Card(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : Colors.white,

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(24),
              ),

              child: Padding(
                padding:
                const EdgeInsets.all(20),

                child: Column(
                  children: [

                    DropdownButtonFormField<int>(
                      value: currentSemester,

                      decoration:
                      const InputDecoration(
                        labelText:
                        "Current Semester",
                        border:
                        OutlineInputBorder(),
                      ),

                      items:
                      List.generate(
                        8,
                            (index) {
                          final semester =
                              index + 1;

                          return DropdownMenuItem(
                            value: semester,
                            child: Text(
                              "Semester $semester",
                            ),
                          );
                        },
                      ),

                      onChanged:
                      loading
                          ? null
                          : (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setState(() {
                          currentSemester =
                              value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      value: newSemester,

                      decoration:
                      const InputDecoration(
                        labelText:
                        "New Semester",
                        border:
                        OutlineInputBorder(),
                      ),

                      items:
                      List.generate(
                        8,
                            (index) {
                          final semester =
                              index + 1;

                          return DropdownMenuItem(
                            value: semester,
                            child: Text(
                              "Semester $semester",
                            ),
                          );
                        },
                      ),

                      onChanged:
                      loading
                          ? null
                          : (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setState(() {
                          newSemester =
                              value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value:
                      selectedDepartment,

                      decoration:
                      const InputDecoration(
                        labelText:
                        "Department",
                        border:
                        OutlineInputBorder(),
                      ),

                      items: const [

                        DropdownMenuItem(
                          value: "All",
                          child:
                          Text("All"),
                        ),

                        DropdownMenuItem(
                          value: "AIML",
                          child:
                          Text("AIML"),
                        ),

                        DropdownMenuItem(
                          value: "CSE",
                          child:
                          Text("CSE"),
                        ),

                        DropdownMenuItem(
                          value: "ECE",
                          child:
                          Text("ECE"),
                        ),

                      ],

                      onChanged:
                      loading
                          ? null
                          : (value) {
                        setState(() {
                          selectedDepartment =
                          value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value:
                      selectedYear,

                      decoration:
                      const InputDecoration(
                        labelText:
                        "Current Year",
                        border:
                        OutlineInputBorder(),
                      ),

                      items: const [

                        DropdownMenuItem(
                          value: "All",
                          child:
                          Text("All"),
                        ),

                        DropdownMenuItem(
                          value: "1st",
                          child:
                          Text("1st Year"),
                        ),

                        DropdownMenuItem(
                          value: "2nd",
                          child:
                          Text("2nd Year"),
                        ),

                        DropdownMenuItem(
                          value: "3rd",
                          child:
                          Text("3rd Year"),
                        ),

                        DropdownMenuItem(
                          value: "4th",
                          child:
                          Text("4th Year"),
                        ),

                      ],

                      onChanged:
                      loading
                          ? null
                          : (value) {
                        setState(() {
                          selectedYear =
                          value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value:
                      selectedSection,

                      decoration:
                      const InputDecoration(
                        labelText:
                        "Section",
                        border:
                        OutlineInputBorder(),
                      ),

                      items: const [

                        DropdownMenuItem(
                          value: "All",
                          child:
                          Text("All"),
                        ),

                        DropdownMenuItem(
                          value: "A",
                          child:
                          Text("A"),
                        ),

                        DropdownMenuItem(
                          value: "B",
                          child:
                          Text("B"),
                        ),

                        DropdownMenuItem(
                          value: "C",
                          child:
                          Text("C"),
                        ),

                      ],

                      onChanged:
                      loading
                          ? null
                          : (value) {
                        setState(() {
                          selectedSection =
                          value!;
                        });
                      },
                    ),

                    const SizedBox(height: 25),

                    Container(
                      width: double.infinity,

                      padding:
                      const EdgeInsets.all(
                        16,
                      ),

                      decoration:
                      BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(
                          16,
                        ),

                        color: isDark
                            ? Colors.white
                            .withValues(
                          alpha: .06,
                        )
                            : Colors.blue
                            .withValues(
                          alpha: .05,
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [

                          Text(
                            "Semester $currentSemester",
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            "→ Semester $newSemester",
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            "New Academic Year: "
                                "${getYearText(newSemester)}",
                          ),

                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,

                      child:
                      ElevatedButton.icon(
                        onPressed:
                        loading
                            ? null
                            : changeSemester,

                        icon: loading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons
                              .published_with_changes,
                        ),

                        label: Text(
                          loading
                              ? "Updating..."
                              : "Change Semester",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}