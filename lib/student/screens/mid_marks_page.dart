import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MidMarksPage extends StatefulWidget {
  const MidMarksPage({super.key});

  @override
  State<MidMarksPage> createState() =>
      _MidMarksPageState();
}

class _MidMarksPageState extends State<MidMarksPage> {
  int? selectedSemester;
  String? selectedExam;

  final List<String> midExams = [
    "Mid 1",
    "Mid 2",
  ];

  String? get studentId {
    return FirebaseAuth.instance.currentUser?.uid;
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
          "Mid Exam Marks",
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
          // SELECT SEMESTER
          // ==================================================

          Padding(
            padding:
            const EdgeInsets.fromLTRB(
              18,
              28,
              18,
              0,
            ),

            child:
            DropdownButtonFormField<int>(
              value:
              selectedSemester,

              decoration:
              InputDecoration(
                labelText:
                "Select Semester",

                labelStyle:
                TextStyle(
                  fontSize: 18,
                  color: isDark
                      ? Colors.white70
                      : Colors.black87,
                ),

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),

                  borderSide:
                  BorderSide(
                    color: isDark
                        ? Colors.white54
                        : Colors.black45,
                  ),
                ),

                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),

                  borderSide:
                  BorderSide(
                    color: isDark
                        ? Colors.white54
                        : Colors.black45,
                    width: 1.5,
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

                  // Reset exam whenever
                  // semester changes.
                  selectedExam = null;
                });
              },
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          // ==================================================
          // SELECT MID EXAM
          // ==================================================

          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 18,
            ),

            child:
            DropdownButtonFormField<
                String>(
              value:
              selectedExam,

              decoration:
              InputDecoration(
                labelText:
                "Select Mid Exam",

                labelStyle:
                TextStyle(
                  fontSize: 18,
                  color: isDark
                      ? Colors.white70
                      : Colors.black87,
                ),

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),

                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),

                  borderSide:
                  BorderSide(
                    color: isDark
                        ? Colors.white54
                        : Colors.black45,
                    width: 1.5,
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
              midExams.map(
                    (exam) {
                  return DropdownMenuItem<
                      String>(
                    value: exam,

                    child: Text(
                      exam,
                    ),
                  );
                },
              ).toList(),

              onChanged:
              selectedSemester ==
                  null
                  ? null
                  : (value) {
                setState(() {
                  selectedExam =
                      value;
                });
              },
            ),
          ),

          const SizedBox(
            height: 25,
          ),

          // ==================================================
          // MARKS
          // ==================================================

          Expanded(
            child:
            selectedSemester == null ||
                selectedExam == null
                ? const Center(
              child: Text(
                "Select Semester and Mid Exam",
                style:
                TextStyle(
                  fontSize: 17,
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
                "exam",
                isEqualTo:
                selectedExam,
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
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        20,
                      ),
                      child: Text(
                        "Unable to load marks.\n\n${snapshot.error}",
                        textAlign:
                        TextAlign.center,
                      ),
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

                // --------------------------------------------------
                // ONLY THEORY SUBJECTS
                // --------------------------------------------------

                final theoryDocs =
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

                    return type !=
                        "lab";
                  },
                ).toList();

                if (theoryDocs
                    .isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: [

                        Icon(
                          Icons
                              .assignment_outlined,
                          size: 65,
                          color: isDark
                              ? Colors
                              .white38
                              : Colors
                              .grey,
                        ),

                        const SizedBox(
                          height: 15,
                        ),

                        Text(
                          "No $selectedExam Marks Released",
                          style:
                          const TextStyle(
                            fontSize:
                            17,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // --------------------------------------------------
                // SORT SUBJECTS
                // --------------------------------------------------

                theoryDocs.sort(
                      (a, b) {
                    final aData =
                    a.data()
                    as Map<String,
                        dynamic>;

                    final bData =
                    b.data()
                    as Map<String,
                        dynamic>;

                    final aCode =
                        aData[
                        "subjectCode"]
                            ?.toString() ??
                            "";

                    final bCode =
                        bData[
                        "subjectCode"]
                            ?.toString() ??
                            "";

                    return aCode
                        .compareTo(
                      bCode,
                    );
                  },
                );

                return ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(
                    18,
                    0,
                    18,
                    30,
                  ),

                  itemCount:
                  theoryDocs
                      .length,

                  itemBuilder:
                      (
                      context,
                      index,
                      ) {
                    final data =
                    theoryDocs[
                    index]
                        .data()
                    as Map<String,
                        dynamic>;

                    return _subjectMarkCard(
                      data,
                      isDark,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBJECT MARK CARD
  // ============================================================

  Widget _subjectMarkCard(
      Map<String, dynamic> data,
      bool isDark,
      ) {
    final subjectName =
        data["subjectName"]
            ?.toString() ??
            "Unknown Subject";

    final subjectCode =
        data["subjectCode"]
            ?.toString() ??
            "";

    final marks =
        (data["marks"] as num?)
            ?.toDouble() ??
            0;

    final maxMarks =
    40;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 16,
      ),

      padding:
      const EdgeInsets.all(18),

      decoration:
      BoxDecoration(
        color: isDark
            ? const Color(0xFF182536)
            : Colors.white,

        borderRadius:
        BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset:
            const Offset(0, 5),
            color: Colors.black
                .withValues(
              alpha: 0.07,
            ),
          ),
        ],
      ),

      child: Row(
        children: [

          // ==================================================
          // SUBJECT ICON
          // ==================================================

          Container(
            width: 58,
            height: 58,

            decoration:
            BoxDecoration(
              color:
              const Color(
                0xFFFFF0D5,
              ),

              borderRadius:
              BorderRadius.circular(
                17,
              ),
            ),

            child: const Icon(
              Icons.assignment,
              color:
              Color(0xFFFFA000),
              size: 30,
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          // ==================================================
          // SUBJECT DETAILS
          // ==================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  subjectName,

                  maxLines: 2,

                  overflow:
                  TextOverflow.ellipsis,

                  style:
                  TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                    color: isDark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  subjectCode,

                  style:
                  TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white60
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ==================================================
          // MARKS
          // ==================================================

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,

            children: [

              Text(
                marks
                    .toStringAsFixed(
                  0,
                ),

                style:
                const TextStyle(
                  fontSize: 27,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xFF1976D2),
                ),
              ),

              Text(
                "/ $maxMarks",

                style:
                TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? Colors.white60
                      : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}