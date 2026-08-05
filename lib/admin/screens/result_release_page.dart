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
                "${data["subjectCode"]}_${data.keys.firstWhere(
                  (e) => e.contains("Mid") ||
                  e.contains("Sem") ||
                  e.contains("Lab"),
              orElse: () => "Unknown",
            )}";

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
          final totalSubjects = grouped.length;

          int releasedSubjects = 0;
          int pendingSubjects = 0;
          int missingEntries = 0;

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

                    ResultStatsCard(

                      title: "Teachers Pending",

                      value: "--",

                      icon: Icons.person,

                      color: Colors.blue,

                    ),

                    ResultStatsCard(

                      title: "Missing Entries",

                      value: missingEntries.toString(),

                      icon: Icons.warning,

                      color: Colors.red,

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

                    // Keep your existing subject card code here

                  }).toList(),

                ),

              ],

            ),

          );

            children:

            grouped.entries.map((entry) {

              FutureBuilder<int>(
                future: service.getMissingEntries(
                  department: first["department"],
                  year: first["year"],
                  semester: first["semester"],
                  section: first["section"],
                  subjectCode: first["subjectCode"],
                  exam: entry.key.split("_").last,
                ),

                builder: (context, snapshot) {

                  final missing = snapshot.data ?? 0;

                  return Text(
                    "Missing : $missing",
                    style: TextStyle(
                      color:
                      missing == 0
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  );

                },

              ),

              final list = entry.value;

              final first =
              list.first.data()
              as Map<String, dynamic>;

              final uploaded =
                  list.length;

              final released =
                  first["released"] == true;

              return Card(

                margin:
                const EdgeInsets.all(12),

                child: Padding(

                  padding:
                  const EdgeInsets.all(16),

                  child: Column(

                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(

                        first["subjectName"],

                        style: const TextStyle(

                          fontSize: 18,

                          fontWeight:
                          FontWeight.bold,

                        ),

                      ),

                      const SizedBox(height:10),

                      Text(
                        "Subject : ${first["subjectCode"]}",
                      ),

                      Text(
                        "Exam : ${entry.key.split("_").last}",
                      ),

                      Text(
                        "Uploaded : $uploaded",
                      ),

                      Text(
                        released
                            ? "Status : Released"
                            : "Status : Pending",
                      ),

                      const SizedBox(height:15),

                      Row(

                        children: [

                          ElevatedButton(

                            onPressed: () {

                              showDialog(

                                context: context,

                                builder: (_) => MissingStudentsDialog(

                                  subjectCode:
                                  first["subjectCode"],

                                  exam:
                                  entry.key.split("_").last,

                                  department:
                                  first["department"],

                                  year:
                                  first["year"],

                                  semester:
                                  first["semester"],

                                  section:
                                  first["section"],

                                ),

                              );

                            },

                            child: const Text(
                              "View Students",
                            ),

                          ),

                          const Spacer(),

                          ElevatedButton(

                            onPressed: released
                                ? null
                                : () async {

                              for(final d in list){

                                await service.releaseResult(
                                    d.id);

                              }

                            },

                            child: const Text(
                              "Release",
                            ),

                          ),

                        ],

                      ),

                    ],

                  ),

                ),

              );

            }).toList(),

          );

            itemCount: docs.length,

            itemBuilder: (context, index) {

              final data =
              docs[index].data()
              as Map<String, dynamic>;

              return Card(

                margin: const EdgeInsets.all(10),

                child: ListTile(

                  leading: const CircleAvatar(
                    child: Icon(Icons.school),
                  ),

                  title: Text(
                    data["subjectName"] ?? "",
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [

                      Text(
                          "Subject : ${data["subjectCode"]}"),

                      Text(
                          "Student : ${data["studentName"]}"),

                      Text(
                          "Roll : ${data["rollNumber"]}"),

                    ],
                  ),

                  trailing: ElevatedButton(

                    child: const Text("Release"),

                    onPressed: () async {

                      await service.releaseResult(
                          docs[index].id);

                      if (context.mounted) {

                        ScaffoldMessenger.of(context)
                            .showSnackBar(

                          const SnackBar(
                            content: Text(
                                "Result Released"),
                          ),

                        );

                      }

                    },

                  ),

                ),

              );

            },

          );

        },

      ),

    );

  }

}