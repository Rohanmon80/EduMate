import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LabMarksPage extends StatefulWidget {
  const LabMarksPage({super.key});

  @override
  State<LabMarksPage> createState() =>
      _LabMarksPageState();
}

class _LabMarksPageState
    extends State<LabMarksPage> {

  int? selectedSemester;

  String? get studentId {
    return FirebaseAuth
        .instance
        .currentUser
        ?.uid;
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final uid = studentId;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      appBar: AppBar(
        backgroundColor:
        const Color(0xFF1976D2),

        foregroundColor:
        Colors.white,

        elevation: 0,

        title: const Text(
          "Lab Marks",
          style: TextStyle(
            fontSize: 23,
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ),

      body: uid == null
          ? const Center(
        child: Text(
          "Please login again.",
        ),
      )
          : Column(
        children: [

          // ==================================================
          // SEMESTER SELECTOR
          // ==================================================

          Padding(
            padding:
            const EdgeInsets.all(18),

            child:
            DropdownButtonFormField<int>(
              value:
              selectedSemester,

              decoration:
              InputDecoration(
                labelText:
                "Select Semester",

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),

                filled: true,

                fillColor:
                isDark
                    ? const Color(
                  0xFF182536,
                )
                    : Colors.white,
              ),

              items:
              List.generate(
                8,
                    (index) {
                  final semester =
                      index + 1;

                  return DropdownMenuItem<
                      int>(
                    value:
                    semester,

                    child: Text(
                      "Semester $semester",
                    ),
                  );
                },
              ),

              onChanged:
                  (value) {
                setState(() {
                  selectedSemester =
                      value;
                });
              },
            ),
          ),

          // ==================================================
          // CONTENT
          // ==================================================

          Expanded(
            child:
            selectedSemester ==
                null
                ? const Center(
              child: Text(
                "Select Semester",
                style:
                TextStyle(
                  fontSize: 18,
                ),
              ),
            )
                : StreamBuilder<
                QuerySnapshot>(
              stream:
              FirebaseFirestore
                  .instance
                  .collection(
                "student_marks",
              )
                  .where(
                "studentId",
                isEqualTo:
                uid,
              )
                  .where(
                "semester",
                isEqualTo:
                selectedSemester,
              )
                  .where(
                "released",
                isEqualTo:
                true,
              )
                  .snapshots(),

              builder:
                  (
                  context,
                  snapshot,
                  ) {
                if (snapshot
                    .connectionState ==
                    ConnectionState
                        .waiting) {
                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                if (snapshot
                    .hasError) {
                  return Center(
                    child: Text(
                      "Unable to load lab marks.\n${snapshot.error}",
                      textAlign:
                      TextAlign.center,
                    ),
                  );
                }

                if (!snapshot
                    .hasData) {
                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                final docs =
                    snapshot
                        .data!
                        .docs;

                // ==================================================
                // ONLY LAB MARKS
                // ==================================================

                final labDocs =
                docs.where(
                      (doc) {
                    final data =
                    doc.data()
                    as Map<String,
                        dynamic>;

                    final type =
                        data["type"]
                            ?.toString()
                            .toLowerCase() ??
                            "";

                    return type ==
                        "lab";
                  },
                ).toList();

                if (labDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No Lab Marks Released",
                      style: TextStyle(
                        fontSize: 17,
                      ),
                    ),
                  );
                }

                // ==================================================
                // GROUP BY SUBJECT
                // ==================================================

                final Map<
                String,
                List<
                Map<String,
                dynamic>>>
                grouped = {};

                for (final doc
                in labDocs) {
                final data =
                doc.data()
                as Map<
                String,
                dynamic>;

                    final code =
                    data["subjectCode"]
                        ?.toString()
                        .trim() ??
                    "";

                    final category =
                    data["examCategory"]
                        ?.toString()
                        .trim()
                        .toLowerCase() ??
                    "regular";

                    if (code.isEmpty) {
                    continue;
                    }

                    final key =
                    "${code}_$category";

                    grouped.putIfAbsent(
                    key,
                    () => [],
                    );

                    grouped[key]!.add(
                    data,
                    );
                }

                return ListView(
                padding:
                const EdgeInsets
                    .fromLTRB(
                18,
                0,
                18,
                30,
                ),

                children:
                grouped
                    .entries
                    .map(
                (
                entry,
                ) {
                return _labSubjectCard(
                context,
                entry
                    .value,
                isDark,
                );
                },
                ).toList(),
                );
                },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LAB SUBJECT CARD
  // ============================================================

  Widget _labSubjectCard(
      BuildContext context,
      List<Map<String, dynamic>>
      marks,
      bool isDark,
      ) {
    final first =
        marks.first;

    final subjectName =
        first["subjectName"]
            ?.toString() ??
            "Unknown Subject";

    final subjectCode =
        first["subjectCode"]
            ?.toString() ??
            "";

    double? internal1;
    double? internal2;
    double? external;

    for (final mark in marks) {
      final exam =
          mark["exam"]
              ?.toString()
              .trim() ??
              "";

      final value =
      (mark["marks"] as num?)
          ?.toDouble();

      if (value == null) {
        continue;
      }

      switch (exam) {
        case "Lab Internal 1":
          internal1 = value;
          break;

        case "Lab Internal 2":
          internal2 = value;
          break;

        case "Lab External":
          external = value;
          break;
      }
    }
    final internalAverage =
    internal1 != null && internal2 != null
        ? (internal1 + internal2) / 2
        : null;

    final finalLabTotal =
    internalAverage != null && external != null
        ? internalAverage + external
        : null;

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 16,
      ),

      color: isDark
          ? const Color(0xFF1E293B)
          : Colors.white,

      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          22,
        ),
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // ==================================================
            // SUBJECT
            // ==================================================

            Row(
              children: [

                Container(
                  width: 52,
                  height: 52,

                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFE8F5E9,
                    ),

                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                  ),

                  child: const Icon(
                    Icons.science,
                    color:
                    Color(0xFF43A047),
                    size: 28,
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                    children: [

                      Text(
                        subjectName,

                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        subjectCode,

                        style:
                        TextStyle(
                          color: isDark
                              ? Colors
                              .white70
                              : Colors
                              .black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            const Divider(),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // LAB INTERNAL 1
            // ==================================================

            _markRow(
              "Lab Internal 1",
              internal1,
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // LAB INTERNAL 2
            // ==================================================

            _markRow(
              "Lab Internal 2",
              internal2,
            ),

            const SizedBox(
              height: 12,
            ),

            // ==================================================
            // LAB EXTERNAL
            // ==================================================

            _markRow(
              "Lab External",
              external,
            ),
            const SizedBox(height: 18),

            const Divider(),

            const SizedBox(height: 12),

            _markRow(
              "Internal Average",
              internalAverage,
            ),

            const SizedBox(height: 12),

            _markRow(
              "Final Lab Total",
              finalLabTotal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _markRow(
      String title,
      double? marks,
      ) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment
          .spaceBetween,

      children: [

        Text(
          title,

          style:
          const TextStyle(
            fontSize: 16,
            fontWeight:
            FontWeight.w500,
          ),
        ),

        Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),

          decoration:
          BoxDecoration(
            color:
            const Color(
              0xFFE8F5E9,
            ),

            borderRadius:
            BorderRadius.circular(
              12,
            ),
          ),

          child: Text(
            marks == null
                ? "--"
                : marks % 1 == 0
                ? marks.toStringAsFixed(0)
                : marks.toStringAsFixed(1),

            style:
            const TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.bold,
              color:
              Color(0xFF2E7D32),
            ),
          ),
        ),
      ],
    );
  }
}