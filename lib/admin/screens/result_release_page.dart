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

    return Scaffold(

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
                "${data["subjectCode"]}_${data["exam"]}";

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


          for (final entry in grouped.entries) {

            final list = entry.value;

            final first =
            list.first.data() as Map<String, dynamic>;

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
                          decoration: const InputDecoration(
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
                        width: 120,
                        child: DropdownButtonFormField<int>(
                          value: selectedSemester,
                          decoration: const InputDecoration(
                            labelText: "Semester",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text("All")),
                            DropdownMenuItem(value: 1, child: Text("1")),
                            DropdownMenuItem(value: 2, child: Text("2")),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedSemester = value!;
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

                      color: Colors.orange,

                    ),

                    ResultStatsCard(

                      title: "Released Subjects",

                      value: releasedSubjects.toString(),

                      icon: Icons.check_circle,

                      color: Colors.green,

                    ),

                    FutureBuilder<int>(

                      future: service.getTeachersPending(),

                      builder: (context, snapshot) {

                        final pending = snapshot.data ?? 0;

                        return ResultStatsCard(

                          title: "Teachers Pending",

                          value: pending.toString(),

                          icon: Icons.person,

                          color: Colors.blue,

                        );

                      },

                    ),

                    FutureBuilder<int>(

                      future: service.getTotalMissingEntries(),

                      builder: (context, snapshot) {

                        final totalMissing = snapshot.data ?? 0;

                        return ResultStatsCard(

                          title: "Missing Entries",

                          value: totalMissing.toString(),

                          icon: Icons.warning,

                          color: Colors.red,

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

                    if (selectedSemester != 0 &&
                        first["semester"] != selectedSemester) {
                      return const SizedBox.shrink();
                    }

                    final uploaded = list.length;

                    final released = first["released"] == true;

                    return Card(

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

                                ElevatedButton(

                                  onPressed: released
                                      ? null
                                      : () async {

                                    for (final d in list) {
                                      await service.releaseResult(d.id);
                                    }

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Results released successfully"),
                                      ),
                                    );
                                  },

                                  child: const Text("Release"),

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