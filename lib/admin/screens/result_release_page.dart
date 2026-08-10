import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/missing_students_dialog.dart';
import '../../services/result_release_service.dart';
import '../widgets/result_stats_card.dart';
class ResultReleasePage extends StatefulWidget {
  const ResultReleasePage({super.key});

  @override
  State<ResultReleasePage> createState() =>
      _ResultReleasePageState();
}

class _ResultReleasePageState
    extends State<ResultReleasePage> {

  final ResultReleaseService service =
  ResultReleaseService();
  String selectedDepartment = "All";
  String selectedYear = "All";
  String selectedSection = "All";
  String selectedExam = "All";
  int selectedSemester = 0;

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
        title: const Text("Result Release"),
      ),

      body: StreamBuilder<QuerySnapshot>(

        stream: service.getAllResults(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          Map<String, List<QueryDocumentSnapshot>> grouped = {};

          for (final doc in docs) {

            final data =
            doc.data() as Map<String, dynamic>;

            final key =
                "${data["department"]}_"
                "${data["year"]}_"
                "${data["semester"]}_"
                "${data["section"]}_"
                "${data["subjectCode"]}_"
                "${data["exam"]}";

            grouped.putIfAbsent(key, () => []);

            grouped[key]!.add(doc);

          }

          if (docs.isEmpty) {

            return const Center(
              child: Text(
                "No Pending Results",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            );
          }

          int releasedSubjects = 0;
          int pendingSubjects = 0;


          for (final entry in grouped.entries) {
            final list = entry.value;

            final first =
            list.first.data() as Map<String, dynamic>;

            if (selectedDepartment != "All" &&
                first["department"] != selectedDepartment) {
              continue;
            }

            if (selectedYear != "All" &&
                first["year"] != selectedYear) {
              continue;
            }

            if (selectedSection != "All" &&
                first["section"] != selectedSection) {
              continue;
            }

            if (selectedSemester != 0 &&
                first["semester"] != selectedSemester) {
              continue;
            }

            if (selectedExam != "All" &&
                first["exam"] != selectedExam) {
              continue;
            }

            if (first["released"] == true) {
              releasedSubjects++;
            } else {
              pendingSubjects++;
            }
          }

          return SingleChildScrollView(

            child: Column(

              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [

                      SizedBox(
                        width: 170,
                        child: DropdownButtonFormField<String>(
                          value: selectedDepartment,
                          decoration: InputDecoration(

                            filled: true,

                            fillColor:
                            isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            labelText: "Department",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: "All", child: Text("All")),
                            DropdownMenuItem(value: "AIML", child: Text("AIML")),
                            DropdownMenuItem(value: "CSE", child: Text("CSE")),
                            DropdownMenuItem(value: "ECE", child: Text("ECE")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedDepartment = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          value: selectedYear,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            labelText: "Year",
                            border: const OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: "All", child: Text("All")),
                            DropdownMenuItem(value: "1st", child: Text("1st")),
                            DropdownMenuItem(value: "2nd", child: Text("2nd")),
                            DropdownMenuItem(value: "3rd", child: Text("3rd")),
                            DropdownMenuItem(value: "4th", child: Text("4th")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedYear = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<String>(
                          value: selectedSection,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            labelText: "Section",
                            border: const OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: "All",
                              child: Text("All"),
                            ),
                            DropdownMenuItem(
                              value: "A",
                              child: Text("A"),
                            ),
                            DropdownMenuItem(
                              value: "B",
                              child: Text("B"),
                            ),
                            DropdownMenuItem(
                              value: "C",
                              child: Text("C"),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedSection = value!;
                            });
                          },
                        ),
                      ),

                      SizedBox(
                        width: 120,
                        child: DropdownButtonFormField<int>(
                          value: selectedSemester,
                          decoration: InputDecoration(

                            filled: true,

                            fillColor:
                            isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            labelText: "Semester",
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: 0,
                              child: Text("All"),
                            ),

                            ...List.generate(
                              8,
                                  (index) {
                                final semester = index + 1;

                                return DropdownMenuItem(
                                  value: semester,
                                  child: Text(
                                    "Semester $semester",
                                  ),
                                );
                              },
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedSemester = value!;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        width: 170,
                        child: DropdownButtonFormField<String>(
                          value: selectedExam,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            labelText: "Exam",
                            border: const OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: "All", child: Text("All")),
                            DropdownMenuItem(value: "Mid 1", child: Text("Mid 1")),
                            DropdownMenuItem(value: "Mid 2", child: Text("Mid 2")),
                            DropdownMenuItem(value: "Sem External", child: Text("Sem External")),
                            DropdownMenuItem(value: "Lab Internal 1", child: Text("Lab Internal 1")),
                            DropdownMenuItem(value: "Lab Internal 2", child: Text("Lab Internal 2")),
                            DropdownMenuItem(value: "Lab External", child: Text("Lab External")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedExam = value!;
                            });
                          },
                        ),
                      ),

                    ],
                  ),
                ),

                GridView.count(

                  shrinkWrap: true,

                  physics:
                  const NeverScrollableScrollPhysics(),

                  crossAxisCount: 2,

                  childAspectRatio: 1.5,

                  children: [

                    ResultStatsCard(

                      title: "Pending Subjects",

                      value: pendingSubjects.toString(),

                      icon: Icons.pending_actions,

                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,

                    ),

                    ResultStatsCard(

                      title: "Released Subjects",

                      value: releasedSubjects.toString(),

                      icon: Icons.check_circle,

                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,

                    ),


                    FutureBuilder<int>(
                      future:
                      selectedDepartment == "All" ||
                          selectedYear == "All" ||
                          selectedSection == "All" ||
                          selectedSemester == 0
                          ? Future.value(0)
                          : service.getTotalMissingEntries(
                        department: selectedDepartment,
                        year: selectedYear,
                        semester: selectedSemester,
                        section: selectedSection,
                      ),
                      builder: (context, snapshot) {
                        final totalMissing = snapshot.data ?? 0;

                        return ResultStatsCard(
                          title: "Missing Entries",
                          value: totalMissing.toString(),
                          icon: Icons.warning,
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                        );
                      },
                    ),

                  ],

                ),

                const SizedBox(height: 20),

                ListView(

                  shrinkWrap: true,

                  physics:
                  const NeverScrollableScrollPhysics(),

                  children:

                  grouped.entries.map((entry){
                    final list = entry.value;

                    final first =
                    list.first.data() as Map<String, dynamic>;
                    if (selectedDepartment != "All" &&
                        first["department"] != selectedDepartment) {
                      return const SizedBox.shrink();
                    }
                    if (selectedYear != "All" &&
                        first["year"] != selectedYear) {
                      return const SizedBox.shrink();
                    }
                    if (selectedSection != "All" &&
                        first["section"] != selectedSection) {
                      return const SizedBox.shrink();
                    }

                    if (selectedSemester != 0 &&
                        first["semester"] != selectedSemester) {
                      return const SizedBox.shrink();
                    }
                    if (selectedExam != "All" &&
                        first["exam"] != selectedExam) {
                      return const SizedBox.shrink();
                    }

                    final uploadedStudentIds = list
                        .map((doc) {
                      final data =
                      doc.data() as Map<String, dynamic>;
                      return data["studentId"]?.toString();
                    })
                        .where((id) => id != null && id.isNotEmpty)
                        .toSet();

                    final uploaded = uploadedStudentIds.length;

                    final allReleased = list.isNotEmpty &&
                        list.every((doc) {
                          final data =
                          doc.data() as Map<String, dynamic>;
                          return data["released"] == true;
                        });

                    final released = allReleased;

                    return Card(

                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,

                        margin: const EdgeInsets.all(12),

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

                            const SizedBox(height: 10),

                            Text("Subject : ${first["subjectCode"]}"),

                            Text("Teacher : ${first["teacherName"]}"),

                            Text("Exam : ${first["exam"]}"),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text("Uploaded : $uploaded"),

                                FutureBuilder<int>(
                                  future: service.getMissingEntries(
                                    department: first["department"],
                                    year: first["year"],
                                    semester: first["semester"],
                                    section: first["section"],
                                    subjectCode: first["subjectCode"],
                                    exam: first["exam"],
                                  ),
                                  builder: (context, snapshot) {

                                    final missing = snapshot.data ?? 0;

                                    return Text(
                                      "Missing : $missing",
                                      style: TextStyle(
                                        color: missing == 0 ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),

                              ],
                            ),

                            Text(
                              released
                                  ? "Status : Released"
                                  : "Status : Pending",
                            ),

                            const SizedBox(height: 15),

                            Row(

                              children: [

                                ElevatedButton(

                                  onPressed: () {

                                    showDialog(

                                      context: context,

                                      builder: (_) => MissingStudentsDialog(

                                        subjectCode: first["subjectCode"],

                                        exam: first["exam"],

                                        department: first["department"],

                                        year: first["year"],

                                        semester: first["semester"],

                                        section: first["section"],

                                      ),

                                    );

                                  },

                                  child: const Text("View Students"),

                                ),

                                const Spacer(),

                                FutureBuilder<int>(
                                  future: service.getMissingEntries(
                                    department: first["department"],
                                    year: first["year"],
                                    semester: first["semester"],
                                    section: first["section"],
                                    subjectCode: first["subjectCode"],
                                    exam: first["exam"],
                                  ),
                                  builder: (context, missingSnapshot) {
                                    final missing = missingSnapshot.data ?? 0;

                                    return ElevatedButton(
                                      onPressed:
                                      released ||
                                          missingSnapshot.connectionState ==
                                              ConnectionState.waiting
                                          ? null
                                          : () async {
                                        try {
                                          for (final d in list) {
                                            await service.releaseResult(d.id);
                                          }

                                          if (!context.mounted) return;

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              backgroundColor: Colors.green,
                                              content: Text(
                                                "Results released successfully",
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!context.mounted) return;

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: Colors.red,
                                              content: Text(
                                                "Unable to release results: $e",
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(
                                        released ? "Released" : "Release",
                                      ),
                                    );
                                  },
                                ),

                              ],

                            ),

                          ],

                        ),

                      ),

                    );
                  }).toList(),

                ),

              ],

            ),

          );
        },

      ),

    );

  }

}