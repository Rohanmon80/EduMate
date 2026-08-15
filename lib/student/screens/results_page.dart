import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SemesterResultsPage extends StatefulWidget {
  const SemesterResultsPage({super.key});

  @override
  State<SemesterResultsPage> createState() => _SemesterResultsPageState();
}

class _SemesterResultsPageState extends State<SemesterResultsPage> {
  // Change to 10 if your B.Tech system has 10 semesters.
  static const int totalSemesters = 8;

  int selectedSemester = 1;
  late Future<List<_SemesterSummary>> _summaryFuture;

  String? get studentId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadAllSemesterSummaries();
  }

  Future<void> _refresh() async {
    setState(() {
      _summaryFuture = _loadAllSemesterSummaries();
    });

    await _summaryFuture;
  }

  // ============================================================
  // LOAD EXPECTED SUBJECTS
  // ============================================================

  Future<QuerySnapshot<Map<String, dynamic>>> _loadExpectedSubjects(
      int semester,
      ) async {
    final uid = studentId;

    if (uid == null) {
      throw Exception('Student not logged in');
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists) {
      throw Exception('Student profile not found');
    }

    final userData = userDoc.data() ?? <String, dynamic>{};

    final department = userData['department']?.toString();

    if (department == null || department.isEmpty) {
      throw Exception('Student department is missing');
    }

    return FirebaseFirestore.instance
        .collection('subjects')
        .where('department', isEqualTo: department)
        .where('semester', isEqualTo: semester)
        .get();
  }

  // ============================================================
  // GRADE CALCULATION
  // ============================================================

  Map<String, dynamic> calculateGrade({
    required double total,
    required double average,
    required double external,
  }) {
    final passed =
        average >= 14 &&
            external >= 21 &&
            total >= 40;

    if (!passed) {
      return {
        'pass': false,
        'grade': 'F',
        'gradePoint': 0,
      };
    }

    if (total >= 90) {
      return {
        'pass': true,
        'grade': 'O',
        'gradePoint': 10,
      };
    }

    if (total >= 80) {
      return {
        'pass': true,
        'grade': 'A+',
        'gradePoint': 9,
      };
    }

    if (total >= 70) {
      return {
        'pass': true,
        'grade': 'A',
        'gradePoint': 8,
      };
    }

    if (total >= 60) {
      return {
        'pass': true,
        'grade': 'B+',
        'gradePoint': 7,
      };
    }

    if (total >= 50) {
      return {
        'pass': true,
        'grade': 'B',
        'gradePoint': 6,
      };
    }

    return {
      'pass': true,
      'grade': 'C',
      'gradePoint': 5,
    };
  }

  // ============================================================
  // BUILD SUBJECT RESULT
  // ============================================================

  Map<String, dynamic> buildSubjectResult(
      List<Map<String, dynamic>> marks, {
        required int semester,
      }) {
    double? regularInternal1;
    double? regularInternal2;
    double? regularExternal;

    double? supplyInternal1;
    double? supplyInternal2;
    double? supplyExternal;

    String subjectCode = '';
    String subjectName = '';
    String subjectType = 'Theory';

    double credits = 0;

    bool isLab = false;

    for (final item in marks) {
      subjectCode =
          item['subjectCode']?.toString().trim() ?? subjectCode;

      subjectName =
          item['subjectName']?.toString().trim() ?? subjectName;

      subjectType =
          item['type']?.toString().trim() ?? subjectType;

      final type =
          item['type']?.toString().trim().toLowerCase() ?? '';

      isLab = isLab || type == 'lab';

      final category =
          item['examCategory']
              ?.toString()
              .trim()
              .toLowerCase() ??
              'regular';

      final isSupply = category == 'supply';

      final value =
      (item['marks'] as num?)?.toDouble();

      if (value == null) {
        continue;
      }

      final exam =
          item['exam']?.toString().trim() ?? '';

      // ========================================================
      // THEORY
      // ========================================================

      if (!isLab) {
        if (exam == 'Mid 1') {
          if (isSupply) {
            supplyInternal1 = value;
          } else {
            regularInternal1 = value;
          }
        } else if (exam == 'Mid 2') {
          if (isSupply) {
            supplyInternal2 = value;
          } else {
            regularInternal2 = value;
          }
        } else if (
        exam == 'Sem External' ||
            exam == 'External') {
          if (isSupply) {
            supplyExternal = value;
          } else {
            regularExternal = value;
          }
        }
      }

      // ========================================================
      // LAB
      // ========================================================

      else {
        if (exam == 'Lab Internal 1') {
          if (isSupply) {
            supplyInternal1 = value;
          } else {
            regularInternal1 = value;
          }
        } else if (exam == 'Lab Internal 2') {
          if (isSupply) {
            supplyInternal2 = value;
          } else {
            regularInternal2 = value;
          }
        } else if (exam == 'Lab External') {
          if (isSupply) {
            supplyExternal = value;
          } else {
            regularExternal = value;
          }
        }
      }

      final creditValue =
      (item['credits'] as num?)?.toDouble();

      if (creditValue != null) {
        credits = creditValue;
      }
    }

    // ============================================================
    // CHECK REGULAR RESULT
    // ============================================================

    final regularComplete =
        regularInternal1 != null &&
            regularInternal2 != null &&
            regularExternal != null;

    /*
      IMPORTANT

      If the regular result is not completely released,
      the subject is genuinely PENDING.

      A completed regular result that is F is NOT pending.
      It must appear as F.
    */

    if (!regularComplete) {
      return {
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'type': subjectType,
        'credits': credits,
        'average': null,
        'external': null,
        'total': null,
        'grade': '-',
        'gradePoint': 0,
        'pass': false,
        'pending': true,
        'needsSupply': false,
        'semester': semester,
        'examCategory': 'Regular',
      };
    }

    // ============================================================
    // REGULAR CALCULATION
    // ============================================================

    final regularAverage =
        (regularInternal1! + regularInternal2!) / 2;

    final regularTotal =
        regularAverage + regularExternal!;

    final regularPassed =
        regularAverage >= 14 &&
            regularExternal >= 21 &&
            regularTotal >= 40;

    double? internal1;
    double? internal2;
    double? external;

    String examCategory = 'Regular';

    bool needsSupply = false;

    // ============================================================
    // REGULAR PASSED
    // ============================================================

    if (regularPassed) {
      internal1 = regularInternal1;
      internal2 = regularInternal2;
      external = regularExternal;
    }

    // ============================================================
    // REGULAR FAILED
    // ============================================================

    else {
      examCategory = 'Supply';

      final midFailed =
          regularAverage < 14;

      final externalFailed =
          regularExternal < 21 ||
              regularTotal < 40;

      // ==========================================================
      // MIDS FAILED
      // ==========================================================

      if (midFailed) {
        if (supplyInternal1 == null ||
            supplyInternal2 == null) {
          needsSupply = true;
        }

        internal1 = supplyInternal1;
        internal2 = supplyInternal2;

        // If external is also failed,
        // supply external is required.
        if (externalFailed &&
            regularExternal < 21) {
          external = supplyExternal;

          if (supplyExternal == null) {
            needsSupply = true;
          }
        } else {
          external = regularExternal;
        }
      }

      // ==========================================================
      // ONLY EXTERNAL FAILED
      // ==========================================================

      else {
        internal1 = regularInternal1;
        internal2 = regularInternal2;

        external = supplyExternal;

        if (supplyExternal == null) {
          needsSupply = true;
        }
      }
    }

    // ============================================================
    // FAILED / SUPPLY REQUIRED
    // ============================================================

    /*
      This is important for your F graph.

      If a regular result is already failed and the required
      supply result is not available, it remains:

      Grade = F
      Grade Point = 0
      Pending = false
      Needs Supply = true
    */

    if (needsSupply ||
        internal1 == null ||
        internal2 == null ||
        external == null) {
      final visibleAverage =
      internal1 != null &&
          internal2 != null
          ? (internal1 + internal2) / 2
          : midFailedValue(
        regularAverage,
        supplyInternal1,
        supplyInternal2,
      );

      return {
        'subjectCode': subjectCode,
        'subjectName': subjectName,
        'type': subjectType,
        'credits': credits,
        'average': visibleAverage,
        'external': external,
        'total': null,
        'grade': 'F',
        'gradePoint': 0,
        'pass': false,
        'pending': false,
        'needsSupply': true,
        'semester': semester,
        'examCategory': examCategory,
      };
    }

    // ============================================================
    // FINAL RESULT
    // ============================================================

    final average =
        (internal1 + internal2) / 2;

    final total =
        average + external;

    final gradeData = calculateGrade(
      total: total,
      average: average,
      external: external,
    );

    return {
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'type': subjectType,
      'credits': credits,
      'average': average,
      'external': external,
      'total': total,
      'grade': gradeData['grade'],
      'gradePoint': gradeData['gradePoint'],
      'pass': gradeData['pass'],
      'pending': false,
      'needsSupply': false,
      'semester': semester,
      'examCategory': examCategory,
    };
  }

  double midFailedValue(
      double regularAverage,
      double? supplyInternal1,
      double? supplyInternal2,
      ) {
    if (supplyInternal1 != null &&
        supplyInternal2 != null) {
      return (
          supplyInternal1 +
              supplyInternal2
      ) /
          2;
    }

    return regularAverage;
  }

  // ============================================================
  // SGPA
  // ============================================================

  double calculateSGPA(
      List<Map<String, dynamic>> subjects,
      ) {
    double totalCredits = 0;
    double totalCreditPoints = 0;

    for (final subject in subjects) {
      final credits =
          (subject['credits'] as num?)?.toDouble() ??
              0;

      final gradePoint =
          (subject['gradePoint'] as num?)?.toDouble() ??
              0;

      if (credits <= 0) {
        continue;
      }

      totalCredits += credits;

      totalCreditPoints +=
          gradePoint * credits;
    }

    if (totalCredits == 0) {
      return 0;
    }

    return totalCreditPoints /
        totalCredits;
  }

  // ============================================================
  // CGPA
  //
  // CGPA =
  // Σ(SGPA × Semester Credits) /
  // Total Credits
  // ============================================================

  double? calculateCGPA(
      List<_SemesterSummary> summaries, {
        int? throughSemester,
      }) {
    double totalCredits = 0;
    double totalCreditPoints = 0;

    for (final summary in summaries) {
      if (throughSemester != null &&
          summary.semester > throughSemester) {
        continue;
      }

      /*
        Only semesters with complete released results
        are included.

        A failed subject still has grade point 0 and
        therefore contributes:

        credits × 0 = 0
      */

      if (!summary.gpaReady ||
          summary.sgpa == null) {
        continue;
      }

      totalCredits +=
          summary.totalCredits;

      totalCreditPoints +=
          summary.sgpa! *
              summary.totalCredits;
    }

    if (totalCredits <= 0) {
      return null;
    }

    return totalCreditPoints /
        totalCredits;
  }

  // ============================================================
  // LOAD ALL SEMESTERS
  // ============================================================

  Future<List<_SemesterSummary>>
  _loadAllSemesterSummaries() async {
    final uid = studentId;

    if (uid == null) {
      throw Exception(
        'Please login again.',
      );
    }

    final marksSnapshot =
    await FirebaseFirestore.instance
        .collection('student_marks')
        .where(
      'studentId',
      isEqualTo: uid,
    )
        .where(
      'released',
      isEqualTo: true,
    )
        .get();

    final Map<
        int,
        Map<
            String,
            List<Map<String, dynamic>>>> grouped =
    {};

    for (final doc
    in marksSnapshot.docs) {
      final data = doc.data();

      final semester =
      (data['semester'] as num?)
          ?.toInt();

      final code =
          data['subjectCode']
              ?.toString()
              .trim() ??
              '';

      if (semester == null ||
          semester < 1 ||
          semester > totalSemesters ||
          code.isEmpty) {
        continue;
      }

      grouped
          .putIfAbsent(
        semester,
            () => {},
      )
          .putIfAbsent(
        code,
            () => [],
      )
          .add(data);
    }

    final summaries =
    <_SemesterSummary>[];

    for (
    int semester = 1;
    semester <= totalSemesters;
    semester++
    ) {
      final subjectSnapshot =
      await _loadExpectedSubjects(
        semester,
      );

      final expectedDocs =
          subjectSnapshot.docs;

      final semesterGroups =
          grouped[semester] ?? {};

      if (expectedDocs.isEmpty) {
        summaries.add(
          _SemesterSummary.empty(
            semester,
          ),
        );

        continue;
      }

      final results =
      <Map<String, dynamic>>[];

      final usedCodes =
      <String>{};

      // ==========================================================
      // ADMIN SUBJECT ORDER
      // ==========================================================

      for (final subjectDoc
      in expectedDocs) {
        final data =
        subjectDoc.data();

        final code =
            data['subjectCode']
                ?.toString()
                .trim() ??
                '';

        if (code.isEmpty) {
          continue;
        }

        usedCodes.add(code);

        final marks =
        semesterGroups[code];

        // ========================================================
        // SUBJECT HAS NO MARKS
        // ========================================================

        if (marks == null ||
            marks.isEmpty) {
          results.add({
            'subjectCode': code,
            'subjectName':
            data['subjectName']
                ?.toString() ??
                '',
            'type':
            data['type']
                ?.toString() ??
                'Theory',
            'credits':
            (data['credits'] as num?)
                ?.toDouble() ??
                0,
            'average': null,
            'external': null,
            'total': null,
            'grade': '-',
            'gradePoint': 0,
            'pass': false,
            'pending': true,
            'needsSupply': false,
            'semester': semester,
            'examCategory': 'Regular',
          });
        }

        // ========================================================
        // SUBJECT HAS MARKS
        // ========================================================

        else {
          results.add(
            buildSubjectResult(
              marks,
              semester: semester,
            ),
          );
        }
      }

      // ============================================================
      // EXTRA RELEASED SUBJECTS
      // ============================================================

      for (final entry
      in semesterGroups.entries) {
        if (usedCodes.contains(
          entry.key,
        )) {
          continue;
        }

        results.add(
          buildSubjectResult(
            entry.value,
            semester: semester,
          ),
        );
      }

      // ============================================================
      // TOTAL CREDITS
      // ============================================================

      double totalCredits = 0;

      for (final result
      in results) {
        totalCredits +=
            (result['credits'] as num?)
                ?.toDouble() ??
                0;
      }

      // ============================================================
      // SEMESTER STATUS
      // ============================================================

      final pending =
      results.any(
            (result) =>
        result['pending'] == true,
      );

      final hasReleasedResult =
      results.any(
            (result) =>
        result['pending'] != true,
      );

      /*
        gpaReady means all subjects have
        a completed result.

        Even if one subject is F,
        gpaReady is TRUE.

        This allows SGPA to be calculated
        with grade point 0 for F.
      */

      final gpaReady =
          results.isNotEmpty &&
              !pending &&
              totalCredits > 0;

      final passed =
          gpaReady &&
              results.every(
                    (result) =>
                result['pass'] == true,
              );

      final sgpa =
      gpaReady
          ? calculateSGPA(
        results,
      )
          : null;

      summaries.add(
        _SemesterSummary(
          semester: semester,
          subjects: results,
          totalCredits:
          totalCredits,
          sgpa: sgpa,
          pending: pending,
          passed: passed,
          gpaReady: gpaReady,
          hasReleasedResult:
          hasReleasedResult,
        ),
      );
    }

    return summaries;
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final background =
    isDark
        ? const Color(0xFF07111F)
        : const Color(0xFFF6F9FC);

    return Scaffold(
      backgroundColor:
      background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child:
          FutureBuilder<
              List<_SemesterSummary>>(
            future: _summaryFuture,
            builder:
                (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child:
                  CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return ListView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(
                      height: 220,
                    ),
                    Center(
                      child: Padding(
                        padding:
                        const EdgeInsets.all(
                          24,
                        ),
                        child: Text(
                          'Unable to load results.\n'
                              '${snapshot.error}',
                          textAlign:
                          TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }

              final summaries =
                  snapshot.data ??
                      <_SemesterSummary>[];

              final selected =
              summaries.firstWhere(
                    (item) =>
                item.semester ==
                    selectedSemester,
                orElse: () =>
                    _SemesterSummary.empty(
                      selectedSemester,
                    ),
              );

              final semCgpa =
              calculateCGPA(
                summaries,
                throughSemester:
                selectedSemester,
              );

              final finalCgpa =
              calculateCGPA(
                summaries,
              );

              return CustomScrollView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child:
                    _buildHeader(
                      isDark,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child:
                    _buildSemesterSelector(
                      isDark,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child:
                    _buildMetricCard(
                      isDark: isDark,
                      selected: selected,
                      semCgpa: semCgpa,
                      finalCgpa: finalCgpa,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child:
                    _buildChartCard(
                      isDark: isDark,
                      selected: selected,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child:
                    _buildSemesterStatus(
                      isDark,
                      selected,
                    ),
                  ),

                  if (selected.subjects.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding:
                        EdgeInsets.all(30),
                        child: Center(
                          child: Text(
                            'No subjects configured for this semester.',
                          ),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate:
                      SliverChildBuilderDelegate(
                            (
                            context,
                            index,
                            ) {
                          final result =
                          selected.subjects[
                          index];

                          return _buildSubjectCard(
                            context,
                            isDark,
                            result,
                          );
                        },
                        childCount:
                        selected.subjects.length,
                      ),
                    ),

                  const SliverToBoxAdapter(
                    child:
                    SizedBox(height: 30),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
      bool isDark,
      ) {
    return Container(
      height: 170,
      decoration:
      const BoxDecoration(
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xFF0B5CBF),
            Color(0xFF3DA7ED),
          ],
        ),
        borderRadius:
        BorderRadius.vertical(
          bottom:
          Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 68,
            child: Row(
              children: [
                IconButton(
                  onPressed: () =>
                      Navigator.maybePop(
                        context,
                      ),
                  icon:
                  const Icon(
                    Icons
                        .arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                ),

                const Expanded(
                  child: Text(
                    'Results',
                    textAlign:
                    TextAlign.center,
                    style:
                    TextStyle(
                      color:
                      Colors.white,
                      fontSize: 25,
                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),
                ),

                IconButton(
                  onPressed:
                  _refresh,
                  icon:
                  const Icon(
                    Icons
                        .refresh_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          const Text(
            'Overall',
            style:
            TextStyle(
              color:
              Colors.white,
              fontSize: 28,
              fontWeight:
              FontWeight.w500,
            ),
          ),

          const SizedBox(
            height: 18,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEMESTER SELECTOR
  // ============================================================

  Widget _buildSemesterSelector(
      bool isDark,
      ) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        8,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Please Select the Semester to View Data',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? Colors.white70
                    : const Color(
                  0xFF222222,
                ),
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          SizedBox(
            height: 54,
            child:
            ListView.separated(
              scrollDirection:
              Axis.horizontal,
              itemCount:
              totalSemesters,
              separatorBuilder:
                  (_, __) =>
              const SizedBox(
                width: 10,
              ),
              itemBuilder:
                  (context, index) {
                final semester =
                    index + 1;

                final selected =
                    semester ==
                        selectedSemester;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedSemester =
                          semester;
                    });
                  },
                  child:
                  AnimatedContainer(
                    duration:
                    const Duration(
                      milliseconds: 180,
                    ),
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 25,
                    ),
                    alignment:
                    Alignment.center,
                    decoration:
                    BoxDecoration(
                      color: selected
                          ? const Color(
                        0xFF2399E8,
                      )
                          : isDark
                          ? const Color(
                        0xFF243244,
                      )
                          : const Color(
                        0xFFE3E3E3,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        30,
                      ),
                    ),
                    child:
                    Text(
                      '${_ordinalYear(semester)} Year '
                          '${_romanSemester(semester)} Sem',
                      style:
                      TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w600,
                        color: selected
                            ? Colors.white
                            : isDark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _ordinalYear(
      int semester,
      ) {
    final year =
        ((semester - 1) ~/ 2) + 1;

    if (year == 1) {
      return 'I';
    }

    if (year == 2) {
      return 'II';
    }

    if (year == 3) {
      return 'III';
    }

    return 'IV';
  }

  String _romanSemester(
      int semester,
      ) {
    return semester.isOdd
        ? 'I'
        : 'II';
  }

  // ============================================================
  // GPA METRIC CARD
  // ============================================================

  Widget _buildMetricCard({
    required bool isDark,
    required _SemesterSummary selected,
    required double? semCgpa,
    required double? finalCgpa,
  }) {
    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        12,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 18,
      ),
      decoration:
      BoxDecoration(
        color: isDark
            ? const Color(0xFF172437)
            : const Color(0xFFEAF6FF),
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: isDark
            ? null
            : const [
          BoxShadow(
            blurRadius: 16,
            offset:
            Offset(0, 5),
            color:
            Color(0x12000000),
          ),
        ],
      ),
      child: Row(
        children: [
          _metric(
            icon:
            Icons.star_rounded,
            title:
            'Sem SGPA',
            value:
            selected.sgpa ==
                null
                ? '—'
                : selected.sgpa!
                .toStringAsFixed(
              2,
            ),
            isDark:
            isDark,
          ),

          _metric(
            icon:
            Icons
                .star_border_rounded,
            title:
            'Sem CGPA',
            value:
            semCgpa == null
                ? '—'
                : semCgpa
                .toStringAsFixed(
              2,
            ),
            isDark:
            isDark,
          ),

          _metric(
            icon:
            Icons.star_rounded,
            title:
            'Final CGPA',
            value:
            finalCgpa == null
                ? '—'
                : finalCgpa
                .toStringAsFixed(
              2,
            ),
            isDark:
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 25,
            color:
            const Color(
              0xFFEF704B,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            title,
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color: isDark
                  ? Colors.white70
                  : const Color(
                0xFF174D83,
              ),
              fontSize: 13,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            value,
            style:
            TextStyle(
              color: isDark
                  ? Colors.white
                  : const Color(
                0xFF12263A,
              ),
              fontSize: 18,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SGPA GRAPH
  // ============================================================

  Widget _buildChartCard({
    required bool isDark,
    required _SemesterSummary selected,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        14,
      ),
      padding: const EdgeInsets.fromLTRB(
        12,
        15,
        12,
        10,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A2536)
            : const Color(0xFFF0EBF8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF174D83),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Semester ${selected.semester} Subject Performance',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white
                        : const Color(0xFF174D83),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 270,
            child: LayoutBuilder(
              builder: (
                  context,
                  constraints,
                  ) {
                // Exactly 10 subject slots.
                const int subjectCount = 10;

                final chartWidth = math.max(
                  constraints.maxWidth,
                  subjectCount * 72.0,
                );

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth,
                    height: 270,
                    child: CustomPaint(
                      painter: _SubjectChartPainter(
                        subjects: selected.subjects,
                        textColor: isDark
                            ? Colors.white70
                            : const Color(0xFF2C2C2C),
                        gridColor: isDark
                            ? Colors.white24
                            : const Color(0x8899A2AB),
                        passColor: const Color(0xFF2378CF),
                        failColor: const Color(0xFFE34F4F),
                        pendingColor: const Color(0xFFFFA726),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: Text(
              'Bar height = Grade Point • Orange = Pending • Red = F',
              style: TextStyle(
                color: isDark
                    ? Colors.white54
                    : Colors.black54,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEMESTER STATUS
  // ============================================================

  Widget _buildSemesterStatus(
      bool isDark,
      _SemesterSummary selected,
      ) {
    final Color color;
    final String text;
    final IconData icon;

    if (selected.pending) {
      color =
          Colors.orange;
      text =
      'SEMESTER RESULT: PENDING';
      icon =
          Icons
              .hourglass_bottom_rounded;
    } else if (selected.passed) {
      color =
          Colors.green;
      text =
      'SEMESTER RESULT: PASS';
      icon =
          Icons
              .check_circle_rounded;
    } else if (selected.gpaReady) {
      color =
          Colors.red;
      text =
      'SEMESTER RESULT: FAIL';
      icon =
          Icons.cancel_rounded;
    } else {
      color =
          Colors.grey;
      text =
      'SEMESTER RESULT: NO DATA';
      icon =
          Icons.info_outline_rounded;
    }

    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        16,
        2,
        16,
        10,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      decoration:
      BoxDecoration(
        color:
        isDark
            ? color.withOpacity(.12)
            : color.withOpacity(.08),
        borderRadius:
        BorderRadius.circular(14),
        border:
        Border.all(
          color:
          color.withOpacity(.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Text(
              text,
              style:
              TextStyle(
                color: color,
                fontWeight:
                FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),

          Text(
            '${selected.totalCredits.toStringAsFixed(
              selected.totalCredits % 1 == 0
                  ? 0
                  : 1,
            )} Credits',
            style:
            TextStyle(
              color:
              isDark
                  ? Colors.white60
                  : Colors.black54,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBJECT CARD
  // ============================================================

  Widget _buildSubjectCard(
      BuildContext context,
      bool isDark,
      Map<String, dynamic> result,
      ) {
    final pending =
        result['pending'] == true;

    final pass =
        result['pass'] == true;

    final needsSupply =
        result['needsSupply'] == true;

    final grade =
        result['grade']
            ?.toString() ??
            '-';

    final credits =
        (result['credits'] as num?)
            ?.toDouble() ??
            0;

    final average =
    (result['average'] as num?)
        ?.toDouble();

    final external =
    (result['external'] as num?)
        ?.toDouble();

    final total =
    (result['total'] as num?)
        ?.toDouble();

    final type =
        result['type']
            ?.toString() ??
            'Theory';

    final subjectName =
        result['subjectName']
            ?.toString() ??
            '';

    final subjectCode =
        result['subjectCode']
            ?.toString() ??
            '';

    final statusColor =
    pending
        ? Colors.orange
        : pass
        ? Colors.green
        : Colors.red;

    final statusText =
    pending
        ? 'PENDING'
        : needsSupply
        ? 'F • SUPPLY REQUIRED'
        : pass
        ? 'PASS'
        : 'FAIL';

    return Container(
      margin:
      const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        12,
      ),
      decoration:
      BoxDecoration(
        color: isDark
            ? const Color(
          0xFF172437,
        )
            : Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border:
        Border.all(
          color:
          isDark
              ? Colors.white10
              : const Color(
            0xFFD4D4D4,
          ),
        ),
        boxShadow: isDark
            ? null
            : const [
          BoxShadow(
            color:
            Color(0x0D000000),
            blurRadius: 10,
            offset:
            Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data:
        Theme.of(context)
            .copyWith(
          dividerColor:
          Colors.transparent,
        ),
        child:
        ExpansionTile(
          tilePadding:
          const EdgeInsets
              .symmetric(
            horizontal: 18,
            vertical: 3,
          ),
          childrenPadding:
          const EdgeInsets
              .fromLTRB(
            18,
            0,
            18,
            17,
          ),

          leading: Text(
            '${result['semester']}.',
            style:
            TextStyle(
              color: isDark
                  ? Colors.white
                  : const Color(
                0xFF5C35A5,
              ),
              fontSize: 17,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          title: Text(
            subjectName,
            style:
            TextStyle(
              color: isDark
                  ? Colors.white
                  : const Color(
                0xFF1A1A1A,
              ),
              fontSize: 16,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          subtitle:
          Padding(
            padding:
            const EdgeInsets.only(
              top: 3,
            ),
            child: Text(
              subjectCode,
              style:
              TextStyle(
                color: isDark
                    ? Colors.white54
                    : Colors.black54,
                fontSize: 12,
              ),
            ),
          ),

          trailing:
          Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                grade,
                style:
                TextStyle(
                  color:
                  statusColor,
                  fontSize: 19,
                  fontWeight:
                  FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                '${credits.toStringAsFixed(
                  credits % 1 == 0
                      ? 0
                      : 1,
                )} Cr',
                style:
                TextStyle(
                  color: isDark
                      ? Colors.white54
                      : Colors.black54,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          children: [
            Row(
              children: [
                _detailBox(
                  'Average ${type.toLowerCase() == 'lab' ? 'Internal' : 'Mid'}',
                  average == null
                      ? '--'
                      : average
                      .toStringAsFixed(
                    1,
                  ),
                  isDark,
                ),

                const SizedBox(
                  width: 8,
                ),

                _detailBox(
                  type.toLowerCase() ==
                      'lab'
                      ? 'Lab External'
                      : 'Semester External',
                  external == null
                      ? '--'
                      : external
                      .toStringAsFixed(
                    1,
                  ),
                  isDark,
                ),

                const SizedBox(
                  width: 8,
                ),

                _detailBox(
                  'Total',
                  total == null
                      ? '--'
                      : total
                      .toStringAsFixed(
                    1,
                  ),
                  isDark,
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Grade Points: '
                        '${result['gradePoint'] ?? 0}',
                    style:
                    TextStyle(
                      color: isDark
                          ? Colors.white70
                          : Colors.black87,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    statusColor,
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                  child:
                  Text(
                    statusText,
                    style:
                    const TextStyle(
                      color:
                      Colors.white,
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL BOX
  // ============================================================

  Widget _detailBox(
      String title,
      String value,
      bool isDark,
      ) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets
            .symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        decoration:
        BoxDecoration(
          color: isDark
              ? Colors.white
              .withOpacity(.05)
              : const Color(
            0xFFF6F8FA,
          ),
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color: isDark
                    ? Colors.white54
                    : Colors.black54,
                fontSize: 10,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              value,
              style:
              TextStyle(
                color: isDark
                    ? Colors.white
                    : Colors.black87,
                fontSize: 15,
                fontWeight:
                FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SEMESTER SUMMARY MODEL
// ================================================================

class _SemesterSummary {
  final int semester;

  final List<
      Map<String, dynamic>> subjects;

  final double totalCredits;

  final double? sgpa;

  final bool pending;

  final bool passed;

  final bool gpaReady;

  final bool hasReleasedResult;

  const _SemesterSummary({
    required this.semester,
    required this.subjects,
    required this.totalCredits,
    required this.sgpa,
    required this.pending,
    required this.passed,
    required this.gpaReady,
    required this.hasReleasedResult,
  });

  factory _SemesterSummary.empty(
      int semester,
      ) {
    return _SemesterSummary(
      semester: semester,
      subjects: const [],
      totalCredits: 0,
      sgpa: null,
      pending: false,
      passed: false,
      gpaReady: false,
      hasReleasedResult: false,
    );
  }
}

// ================================================================
// GRAPH PAINTER
// ================================================================

class _SubjectChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> subjects;

  final Color textColor;
  final Color gridColor;
  final Color passColor;
  final Color failColor;
  final Color pendingColor;

  _SubjectChartPainter({
    required this.subjects,
    required this.textColor,
    required this.gridColor,
    required this.passColor,
    required this.failColor,
    required this.pendingColor,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    const double left = 38.0;
    const double right = 12.0;
    const double top = 22.0;
    const double bottom = 58.0;
    const double maxValue = 10.0;

    final double chartWidth =
        size.width - left - right;

    final double chartHeight =
        size.height - top - bottom;

    final Paint gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    // ============================================================
    // Y AXIS + GRID
    // ============================================================

    for (int value = 0; value <= 10; value += 2) {
      final double y =
          top +
              chartHeight -
              (value / maxValue) * chartHeight;

      _drawDashedLine(
        canvas,
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );

      textPainter.text = TextSpan(
        text: '$value',
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          3,
          y - textPainter.height / 2,
        ),
      );
    }

    // ============================================================
    // ALWAYS CREATE 10 SUBJECT SLOTS
    // ============================================================

    const int subjectCount = 10;

    final double slotWidth =
        chartWidth / subjectCount;

    final double barWidth =
    math.min(
      34.0,
      slotWidth * 0.52,
    );

    // ============================================================
    // DRAW 10 SUBJECT BARS
    // ============================================================

    for (int i = 0; i < subjectCount; i++) {
      final double centerX =
          left +
              slotWidth * i +
              slotWidth / 2;

      // ----------------------------------------------------------
      // If there is no subject configured at this position
      // ----------------------------------------------------------

      if (i >= subjects.length) {
        _drawPending(
          canvas,
          centerX,
          top + chartHeight - 18,
          pendingColor,
          'PENDING',
        );

        _drawSubjectLabel(
          canvas,
          textPainter,
          centerX,
          size.height - 38,
          'S${i + 1}',
        );

        continue;
      }

      final Map<String, dynamic> subject =
      subjects[i];

      final bool pending =
          subject['pending'] == true;

      final bool passed =
          subject['pass'] == true;

      final double gradePoint =
          (subject['gradePoint'] as num?)
              ?.toDouble() ??
              0.0;

      final String grade =
          subject['grade']
              ?.toString() ??
              '-';

      final String code =
          subject['subjectCode']
              ?.toString()
              .trim() ??
              '';

      // ----------------------------------------------------------
      // PENDING
      // ----------------------------------------------------------

      if (pending) {
        _drawPending(
          canvas,
          centerX,
          top + chartHeight - 18,
          pendingColor,
          'PENDING',
        );
      }

      // ----------------------------------------------------------
      // FAILED
      // ----------------------------------------------------------

      else if (!passed || grade == 'F') {
        _drawStatusBar(
          canvas,
          centerX,
          top,
          chartHeight,
          barWidth,
          failColor,
          'F',
        );
      }

      // ----------------------------------------------------------
      // PASSED
      // ----------------------------------------------------------

      else {
        final double safeGradePoint =
        gradePoint.clamp(0.0, 10.0);

        final double barHeight =
            (safeGradePoint / maxValue) *
                chartHeight;

        final RRect rect =
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - barWidth / 2,
            top +
                chartHeight -
                barHeight,
            barWidth,
            math.max(
              8.0,
              barHeight,
            ),
          ),
          const Radius.circular(10),
        );

        final Paint barPaint = Paint()
          ..color = passColor
          ..style = PaintingStyle.fill;

        canvas.drawRRect(
          rect,
          barPaint,
        );

        // Grade point on top
        textPainter.text = TextSpan(
          text: safeGradePoint
              .toStringAsFixed(0),
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        );

        textPainter.layout();

        textPainter.paint(
          canvas,
          Offset(
            centerX -
                textPainter.width / 2,
            top +
                chartHeight -
                barHeight -
                20,
          ),
        );
      }

      // ----------------------------------------------------------
      // SUBJECT CODE
      // ----------------------------------------------------------

      _drawSubjectLabel(
        canvas,
        textPainter,
        centerX,
        size.height - 38,
        code.isEmpty
            ? 'S${i + 1}'
            : code,
      );
    }
  }

  // ==============================================================
  // PENDING
  // ==============================================================

  void _drawPending(
      Canvas canvas,
      double centerX,
      double y,
      Color color,
      String text,
      ) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(
            centerX,
            y,
          ),
          width: 42,
          height: 28,
        ),
        const Radius.circular(8),
      ),
      paint,
    );

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: 'P',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        centerX - tp.width / 2,
        y - tp.height / 2,
      ),
    );
  }

  // ==============================================================
  // FAILED BAR
  // ==============================================================

  void _drawStatusBar(
      Canvas canvas,
      double centerX,
      double top,
      double chartHeight,
      double barWidth,
      Color color,
      String text,
      ) {
    final double barHeight = 38.0;

    final RRect rect =
    RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - barWidth / 2,
        top +
            chartHeight -
            barHeight,
        barWidth,
        barHeight,
      ),
      const Radius.circular(10),
    );

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      rect,
      paint,
    );

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        centerX - tp.width / 2,
        top +
            chartHeight -
            barHeight / 2 -
            tp.height / 2,
      ),
    );
  }

  // ==============================================================
  // SUBJECT LABEL
  // ==============================================================

  void _drawSubjectLabel(
      Canvas canvas,
      TextPainter textPainter,
      double centerX,
      double y,
      String code,
      ) {
    String label = code;

    if (label.length > 8) {
      label = label.substring(
        0,
        8,
      );
    }

    textPainter.text = TextSpan(
      text: label,
      style: TextStyle(
        color: textColor,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    );

    textPainter.layout(
      maxWidth: 58,
    );

    textPainter.paint(
      canvas,
      Offset(
        centerX -
            textPainter.width / 2,
        y,
      ),
    );
  }

  // ==============================================================
  // DASHED GRID LINE
  // ==============================================================

  void _drawDashedLine(
      Canvas canvas,
      Offset start,
      Offset end,
      Paint paint,
      ) {
    const double dashWidth = 7.0;
    const double dashGap = 6.0;

    final double distance =
        (end - start).distance;

    if (distance <= 0) {
      return;
    }

    final Offset direction =
        (end - start) / distance;

    double drawn = 0.0;

    while (drawn < distance) {
      final double next =
      math.min(
        drawn + dashWidth,
        distance,
      );

      canvas.drawLine(
        start +
            direction * drawn,
        start +
            direction * next,
        paint,
      );

      drawn +=
          dashWidth +
              dashGap;
    }
  }

  @override
  bool shouldRepaint(
      covariant _SubjectChartPainter oldDelegate,
      ) {
    return oldDelegate.subjects != subjects ||
        oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.passColor != passColor ||
        oldDelegate.failColor != failColor ||
        oldDelegate.pendingColor != pendingColor;
  }
}