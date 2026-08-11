import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/missing_students_dialog.dart';
import '../../services/result_release_service.dart';
import '../widgets/result_stats_card.dart';

class ResultReleasePage extends StatefulWidget {
  const ResultReleasePage({super.key});

  @override
  State<ResultReleasePage> createState() => _ResultReleasePageState();
}

class _ResultReleasePageState extends State<ResultReleasePage> {
  final ResultReleaseService service = ResultReleaseService();

  String selectedDepartment = "All";
  String selectedYear = "All";
  String selectedSection = "All";
  String selectedExam = "All";
  int selectedSemester = 0;

  Future<List<Map<String, dynamic>>> _getReleaseGroups() {
    return service.getReleaseGroups(
      department: selectedDepartment == "All"
          ? null
          : selectedDepartment,
      year: selectedYear == "All"
          ? null
          : selectedYear,
      section: selectedSection == "All"
          ? null
          : selectedSection,
      semester: selectedSemester == 0
          ? null
          : selectedSemester,
      exam: selectedExam == "All"
          ? null
          : selectedExam,
    );
  }

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      appBar: AppBar(
        title: const Text("Result Release"),
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getReleaseGroups(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Error loading results:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final groups = snapshot.data ?? [];

          // ----------------------------------------------------
          // Statistics
          // ----------------------------------------------------

          final pendingGroups = groups.where((group) {
            return group["released"] != true;
          }).toList();

          final releasedGroups = groups.where((group) {
            return group["released"] == true;
          }).toList();

          final totalMissing = groups.fold<int>(
            0,
                (sum, group) {
              final missing =
              (group["missing"] ?? 0) as int;

              return sum + missing;
            },
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ==================================================
                // FILTERS
                // ==================================================

                Padding(
                  padding: const EdgeInsets.all(12),

                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,

                    children: [

                      // --------------------------------------------
                      // Department
                      // --------------------------------------------

                      SizedBox(
                        width: 160,

                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedDepartment,

                          decoration: InputDecoration(
                            filled: true,

                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,

                            labelText: "Department",

                            border:
                            const OutlineInputBorder(),
                          ),

                          items: const [
                            DropdownMenuItem(
                              value: "All",
                              child: Text("All"),
                            ),

                            DropdownMenuItem(
                              value: "AIML",
                              child: Text("AIML"),
                            ),

                            DropdownMenuItem(
                              value: "CSE",
                              child: Text("CSE"),
                            ),

                            DropdownMenuItem(
                              value: "ECE",
                              child: Text("ECE"),
                            ),
                          ],

                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              selectedDepartment = value;
                            });
                          },
                        ),
                      ),

                      // --------------------------------------------
                      // Year
                      // --------------------------------------------

                      SizedBox(
                        width: 150,

                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedYear,

                          decoration: InputDecoration(
                            filled: true,

                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,

                            labelText: "Year",

                            border:
                            const OutlineInputBorder(),
                          ),

                          items: const [
                            DropdownMenuItem(
                              value: "All",
                              child: Text("All"),
                            ),

                            DropdownMenuItem(
                              value: "1st",
                              child: Text("1st"),
                            ),

                            DropdownMenuItem(
                              value: "2nd",
                              child: Text("2nd"),
                            ),

                            DropdownMenuItem(
                              value: "3rd",
                              child: Text("3rd"),
                            ),

                            DropdownMenuItem(
                              value: "4th",
                              child: Text("4th"),
                            ),
                          ],

                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              selectedYear = value;
                            });
                          },
                        ),
                      ),

                      // --------------------------------------------
                      // Section
                      // --------------------------------------------

                      SizedBox(
                        width: 150,

                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedSection,

                          decoration: InputDecoration(
                            filled: true,

                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,

                            labelText: "Section",

                            border:
                            const OutlineInputBorder(),
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
                            if (value == null) return;

                            setState(() {
                              selectedSection = value;
                            });
                          },
                        ),
                      ),

                      // --------------------------------------------
                      // Semester
                      // --------------------------------------------

                      SizedBox(
                        width: 145,

                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          value: selectedSemester,

                          decoration: InputDecoration(
                            filled: true,

                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,

                            labelText: "Semester",

                            border:
                            const OutlineInputBorder(),
                          ),

                          items: [
                            const DropdownMenuItem<int>(
                              value: 0,
                              child: Text("All"),
                            ),

                            ...List.generate(
                              8,
                                  (index) {
                                final semester =
                                    index + 1;

                                return DropdownMenuItem<int>(
                                  value: semester,

                                  child: Text(
                                    "Semester $semester",
                                    overflow:
                                    TextOverflow.ellipsis,
                                  ),
                                );
                              },
                            ),
                          ],

                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              selectedSemester = value;
                            });
                          },
                        ),
                      ),

                      // --------------------------------------------
                      // Exam
                      // --------------------------------------------

                      SizedBox(
                        width: 160,

                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedExam,

                          decoration: InputDecoration(
                            filled: true,

                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,

                            labelText: "Exam",

                            border:
                            const OutlineInputBorder(),
                          ),

                          items: const [
                            DropdownMenuItem(
                              value: "All",
                              child: Text("All"),
                            ),

                            DropdownMenuItem(
                              value: "Mid 1",
                              child: Text("Mid 1"),
                            ),

                            DropdownMenuItem(
                              value: "Mid 2",
                              child: Text("Mid 2"),
                            ),

                            DropdownMenuItem(
                              value: "Sem External",
                              child: Text("Sem External"),
                            ),

                            DropdownMenuItem(
                              value: "Lab Internal 1",
                              child: Text("Lab Internal 1"),
                            ),

                            DropdownMenuItem(
                              value: "Lab Internal 2",
                              child: Text("Lab Internal 2"),
                            ),

                            DropdownMenuItem(
                              value: "Lab External",
                              child: Text("Lab External"),
                            ),
                          ],

                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              selectedExam = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 5),

                // ==================================================
                // STATISTICS
                // ==================================================

                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8),

                  child: GridView.count(
                    shrinkWrap: true,

                    physics:
                    const NeverScrollableScrollPhysics(),

                    crossAxisCount: 2,

                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,

                    childAspectRatio: 1.5,

                    children: [

                      ResultStatsCard(
                        title: "Pending Exams",

                        value:
                        pendingGroups.length.toString(),

                        icon:
                        Icons.pending_actions,

                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                      ),

                      ResultStatsCard(
                        title: "Released Exams",

                        value:
                        releasedGroups.length.toString(),

                        icon:
                        Icons.check_circle,

                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                      ),

                      ResultStatsCard(
                        title: "Missing Entries",

                        value:
                        totalMissing.toString(),

                        icon:
                        Icons.warning,

                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // NO SUBJECTS
                // ==================================================

                if (groups.isEmpty)
                  Padding(
                    padding:
                    const EdgeInsets.all(30),

                    child: Column(
                      children: [

                        Icon(
                          Icons.assignment_outlined,
                          size: 50,
                          color: isDark
                              ? Colors.white54
                              : Colors.black45,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          "No subjects found for the selected filters.",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // ==================================================
                // RESULT GROUPS
                // ==================================================

                ListView.builder(
                  shrinkWrap: true,

                  physics:
                  const NeverScrollableScrollPhysics(),

                  itemCount: groups.length,

                  itemBuilder: (context, index) {
                    final group =
                    groups[index];

                    return _buildResultCard(
                      context,
                      group,
                      isDark,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // RESULT CARD
  // ============================================================

  Widget _buildResultCard(
      BuildContext context,
      Map<String, dynamic> group,
      bool isDark,
      ) {
    final subjectName =
        group["subjectName"]?.toString() ??
            "Unknown Subject";

    final subjectCode =
        group["subjectCode"]?.toString() ??
            "";

    final subjectType =
        group["type"]?.toString() ??
            "Theory";

    final exam =
        group["exam"]?.toString() ??
            "";

    final department =
        group["department"]?.toString() ??
            "";

    final year =
        group["year"]?.toString() ??
            "";

    final section =
        group["section"]?.toString() ??
            "";

    final semester =
        (group["semester"] as num?)?.toInt() ??
            0;

    final uploaded =
    (group["uploaded"] ?? 0) as int;

    final totalStudents =
    (group["totalStudents"] ?? 0) as int;

    final missing =
    (group["missing"] ?? 0) as int;

    final released =
        group["released"] == true;

    final List<QueryDocumentSnapshot>
    documents =
    List<QueryDocumentSnapshot>.from(
      group["documents"] ?? [],
    );

    final canRelease =
        !released &&
            missing == 0 &&
            documents.isNotEmpty;

    return Card(
      color: isDark
          ? const Color(0xFF1E293B)
          : Colors.white,

      margin:
      const EdgeInsets.fromLTRB(
        12,
        6,
        12,
        6,
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // ----------------------------------------------------
            // Subject title
            // ----------------------------------------------------

            Text(
              subjectName,

              style: const TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // ----------------------------------------------------
            // Subject details
            // ----------------------------------------------------

            Text(
              "Subject : $subjectCode",
            ),

            Text(
              "Type : $subjectType",
            ),

            Text(
              "Exam : $exam",
            ),

            const SizedBox(height: 8),

            // ----------------------------------------------------
            // Class information
            // ----------------------------------------------------

            Text(
              "Class : $department • "
                  "$year • Section $section • "
                  "Semester $semester",
            ),

            const SizedBox(height: 8),

            // ----------------------------------------------------
            // Student / mark counts
            // ----------------------------------------------------

            Text(
              "Students : $totalStudents",
            ),

            Text(
              "Uploaded : $uploaded",
            ),

            Text(
              "Missing : $missing",

              style: TextStyle(
                color: missing == 0
                    ? Colors.green
                    : Colors.red,

                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            // ----------------------------------------------------
            // Status
            // ----------------------------------------------------

            Text(
              released
                  ? "Status : Released"
                  : "Status : Pending",

              style: TextStyle(
                color: released
                    ? Colors.green
                    : Colors.orange,

                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // ----------------------------------------------------
            // Buttons
            // ----------------------------------------------------

            Row(
              children: [

                // ----------------------------------------------
                // View students
                // ----------------------------------------------

                Flexible(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,

                        builder: (_) =>
                            MissingStudentsDialog(
                              subjectCode:
                              subjectCode,

                              exam:
                              exam,

                              department:
                              department,

                              year:
                              year,

                              semester:
                              semester,

                              section:
                              section,
                            ),
                      );
                    },

                    icon: const Icon(
                      Icons.people_outline,
                      size: 18,
                    ),

                    label: const Text(
                      "View Students",
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // ----------------------------------------------
                // Release
                // ----------------------------------------------

                Flexible(
                  child: ElevatedButton.icon(
                    onPressed:
                    canRelease
                        ? () =>
                        _releaseGroup(
                          context,
                          documents,
                        )
                        : null,

                    icon: Icon(
                      released
                          ? Icons.check
                          : Icons.publish,
                      size: 18,
                    ),

                    label: Text(
                      released
                          ? "Released"
                          : missing > 0
                          ? "Missing $missing"
                          : documents.isEmpty
                          ? "No Marks"
                          : "Release",
                    ),
                  ),
                ),
              ],
            ),

            // ----------------------------------------------------
            // Explanation when marks are missing
            // ----------------------------------------------------

            if (missing > 0)
              Padding(
                padding:
                const EdgeInsets.only(
                  top: 10,
                ),

                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Colors.red,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        "$missing student(s) still have "
                            "missing marks for this exam. "
                            "Release is disabled until all "
                            "marks are uploaded.",
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ----------------------------------------------------
            // No marks uploaded
            // ----------------------------------------------------

            if (documents.isEmpty)
              Padding(
                padding:
                const EdgeInsets.only(
                  top: 10,
                ),

                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    const Icon(
                      Icons.info_outline,
                      size: 18,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        "No marks have been uploaded "
                            "for this exam yet.",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RELEASE ONE SUBJECT + EXAM GROUP
  // ============================================================

  Future<void> _releaseGroup(
      BuildContext context,
      List<QueryDocumentSnapshot> documents,
      ) async {
    if (documents.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // Confirmation dialog
    // ----------------------------------------------------------

    final shouldRelease =
    await showDialog<bool>(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title:
          const Text("Release Results?"),

          content: Text(
            "This will release marks for "
                "${documents.length} uploaded student "
                "record(s) for this subject and exam.",
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },

              child:
              const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },

              child:
              const Text("Release"),
            ),
          ],
        );
      },
    );

    if (shouldRelease != true) {
      return;
    }

    // ----------------------------------------------------------
    // Release all documents in THIS group
    // ----------------------------------------------------------

    try {
      for (final document in documents) {
        await service.releaseResult(
          document.id,
        );
      }

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          backgroundColor:
          Colors.green,

          content: Text(
            "Results released successfully.",
          ),
        ),
      );

      // Refresh page so status becomes Released.
      _refresh();

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
            "Unable to release results: $e",
          ),
        ),
      );
    }
  }
}