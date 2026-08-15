import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/memo_pdf_service.dart';
import '../../services/memo_service.dart';

class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  final MemoService _memoService = MemoService();
  final MemoPdfService _memoPdfService = MemoPdfService();

  int? _semester;

  bool _loading = false;
  bool _generating = false;

  Map<String, dynamic>? _memo;

  String? _error;

  @override
  void initState() {
    super.initState();
  }

  // ============================================================
  // LOAD STUDENT SEMESTER + MEMO
  // ============================================================

  Future<void> _loadMemo() async {
    if (_semester == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _memo = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;

      if (uid == null || uid.isEmpty) {
        setState(() {
          _loading = false;
          _error = "Student is not logged in.";
        });
        return;
      }

      final memo = await _memoService.getMemo(
        studentId: uid,
        semester: _semester!,
      );

      if (!mounted) return;

      setState(() {
        _memo = memo?.data();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // GENERATE MEMO
  // ============================================================

  Future<void> _generateMemo() async {
    if (_semester == null) return;

    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid == null || uid.isEmpty) {
      _showMessage(
        "Student is not logged in.",
      );
      return;
    }

    setState(() {
      _generating = true;
      _error = null;
    });

    try {
      await _memoService.generateMemo(
        studentId: uid,
        semester: _semester!,
      );

      final memo =
      await _memoService.getMemo(
        studentId: uid,
        semester: _semester!,
      );

      if (!mounted) return;

      setState(() {
        _memo = memo?.data();
        _generating = false;
      });

      _showMessage(
        "Marks memo generated successfully.",
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _generating = false;
        _error = e.toString();
      });

      _showMessage(
        e.toString().replaceFirst(
          "Exception: ",
          "",
        ),
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Marks Memo",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: _buildBody(),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    return Column(
      children: [
        _buildSemesterSelector(),

        Expanded(
          child: _semester == null
              ? _buildSelectSemesterMessage()
              : _loading
              ? const Center(
            child: CircularProgressIndicator(),
          )
              : _error != null && _memo == null
              ? _buildError()
              : _memo == null
              ? _buildNoMemo()
              : _buildMemo(),
        ),
      ],
    );
  }
  Widget _buildSelectSemesterMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_outlined,
              size: 70,
              color: Theme.of(context).colorScheme.primary,
            ),

            const SizedBox(height: 16),

            Text(
              "Select a Semester",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Choose a semester above to view your marks memo.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSemesterSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: DropdownButtonFormField<int>(
        value: _semester,
        decoration: const InputDecoration(
          labelText: "Select Semester",
          prefixIcon: Icon(Icons.school),
          border: OutlineInputBorder(),
        ),
        hint: const Text("Choose semester"),
        items: List.generate(
          8,
              (index) {
            final semester = index + 1;

            return DropdownMenuItem<int>(
              value: semester,
              child: Text("Semester $semester"),
            );
          },
        ),
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            _semester = value;
            _memo = null;
            _error = null;
          });

          _loadMemo();
        },
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? "Something went wrong.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadMemo,
              child: const Text(
                "Try Again",
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO MEMO
  // ============================================================

  Widget _buildNoMemo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 70,
            ),
            const SizedBox(height: 20),
            const Text(
              "Marks memo is not generated yet.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _semester == null
                  ? ""
                  : "Semester $_semester",
              style: const TextStyle(
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                _generating
                    ? null
                    : _generateMemo,
                icon: _generating
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.description,
                ),
                label: Text(
                  _generating
                      ? "Generating..."
                      : "Generate Memo",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MEMO
  // ============================================================

  Widget _buildMemo() {
    final memo = _memo!;

    final studentName =
    _stringValue(
      memo["studentName"],
    );

    final rollNumber =
    _stringValue(
      memo["rollNumber"],
    );

    final program =
    _stringValue(
      memo["program"],
    );

    final branch =
    _stringValue(
      memo["branch"],
    );

    final year =
    _stringValue(
      memo["year"],
    );

    final section =
    _stringValue(
      memo["section"],
    );

    final dateOfIssue =
    _stringValue(
      memo["dateOfIssue"],
    );

    final semester =
    _numberValue(
      memo["semester"],
    ).toInt();

    final registered =
    _numberValue(
      memo["courseRegistered"],
    ).toInt();

    final appeared =
    _numberValue(
      memo["courseAppeared"],
    ).toInt();

    final passed =
    _numberValue(
      memo["coursePassed"],
    ).toInt();

    final totalCredits =
    _numberValue(
      memo["totalCredits"],
    );

    final double? sgpa =
    _nullableNumberValue(
      memo["sgpa"],
    );

    final double? cgpa =
    _nullableNumberValue(
      memo["cgpa"],
    );

    final imageUrl =
    _stringValue(
      memo["studentImageUrl"],
    );

    final courses =
    _getCourses(
      memo["courses"],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          InteractiveViewer(
            minScale: 0.6,
            maxScale: 2.5,
            boundaryMargin: const EdgeInsets.all(40),
            child: _buildMemoCard(
              studentName: studentName,
              rollNumber: rollNumber,
              program: program,
              branch: branch,
              year: year,
              section: section,

              dateOfIssue: dateOfIssue,
              semester: semester,
              imageUrl: imageUrl,
              courses: courses,
              registered: registered,
              appeared: appeared,
              passed: passed,
              totalCredits: totalCredits,
              sgpa: sgpa,
              cgpa: cgpa,
            ),
          ),

          const SizedBox(height: 20),

          // DOWNLOAD BUTTON
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  _showMessage(
                    "Generating PDF...",
                  );

                  await _memoPdfService.shareMemo(
                    memo: _memo!,
                  );

                  if (!mounted) return;

                  _showMessage(
                    "Marks memo PDF generated successfully.",
                  );
                } catch (e) {
                  if (!mounted) return;

                  _showMessage(
                    "Unable to generate PDF: $e",
                  );
                }
              },
              icon: const Icon(
                Icons.download,
              ),
              label: const Text(
                "Download Marks Memo",
              ),
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed:
            _generating
                ? null
                : _generateMemo,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              "Regenerate Memo",
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEMO CARD
  // ============================================================

  Widget _buildMemoCard({
    required String studentName,
    required String rollNumber,
    required String program,
    required String branch,
    required String year,
    required String section,

    required String dateOfIssue,
    required int semester,
    required String imageUrl,
    required List<Map<String, dynamic>> courses,
    required int registered,
    required int appeared,
    required int passed,
    required double totalCredits,
    required double? sgpa,
    required double? cgpa,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black87,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 5,
            offset: Offset(0, 2),
            color: Colors.black12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),

          const SizedBox(height: 18),

          const Center(
            child: Text(
              "MARKS MEMO",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 18),

          _buildStudentSection(
            studentName: studentName,
            rollNumber: rollNumber,
            program: program,
            branch: branch,
            year: year,
            section: section,

            semester: semester,
            imageUrl: imageUrl,
          ),

          const SizedBox(height: 18),

          _buildCourseTable(
            courses,
          ),

          const SizedBox(height: 14),

          _buildSummary(
            registered: registered,
            appeared: appeared,
            passed: passed,
            totalCredits: totalCredits,
            sgpa: sgpa,
            cgpa: cgpa,
          ),

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                "Date of issue : $dateOfIssue",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                "CONTROLLER OF\nEXAMINATIONS",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
        vertical: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // =====================================================
          // SCIENT LOGO - LEFT
          // =====================================================

          SizedBox(
            width: 65,
            height: 65,
            child: _assetLogo(
              "assets/memo/scient_logo.png",
              65,
            ),
          ),

          const SizedBox(width: 6),

          // =====================================================
          // COLLEGE DETAILS - CENTER
          // =====================================================

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  "SCIENT INSTITUTE OF TECHNOLOGY",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 1),

                Text(
                  "(UGC AUTONOMOUS)",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 2),

                Text(
                  "Accredited by NAAC with 'A+' Grade, "
                      "Affiliated to JNTUH & Approved by AICTE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 1),

                Text(
                  "Ibrahimpatnam, Rangareddy, Telangana - 501506",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 1),

                Text(
                  "www.scient.ac.in",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 5),

          // =====================================================
          // NAAC + UGC + JNTUH - RIGHT
          // =====================================================

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _assetLogo(
                "assets/memo/naac_logo.png",
                43,
              ),

              const SizedBox(width: 1),

              _assetLogo(
                "assets/memo/ugc_logo.png",
                43,
              ),

              const SizedBox(width: 1),

              _assetLogo(
                "assets/memo/jntuh_logo.png",
                43,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assetLogo(
      String path,
      double size,
      ) {
    return Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder:
          (_, __, ___) =>
          SizedBox(
            width: size,
            height: size,
            child: const Icon(
              Icons.image_not_supported,
              size: 24,
            ),
          ),
    );
  }

  // ============================================================
  // STUDENT SECTION
  // ============================================================

  Widget _buildStudentSection({
    required String studentName,
    required String rollNumber,
    required String program,
    required String branch,
    required String year,
    required String section,

    required int semester,
    required String imageUrl,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _detailRow(
                "Name",
                studentName,
              ),
              _detailRow(
                "Hall Ticket No.",
                rollNumber,
              ),
              _detailRow(
                "Program",
                program,
              ),
              _detailRow(
                "Branch",
                branch,
              ),
              _detailRow(
                "Year",
                year,
              ),
              _detailRow(
                "Semester",
                "Semester $semester",
              ),
              _detailRow(
                "Section",
                section,
              ),
            ],
          ),
        ),

        const SizedBox(width: 15),

        Container(
          width: 95,
          height: 115,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
            ),
          ),
          child: imageUrl.isEmpty
              ? const Icon(
            Icons.person,
            size: 55,
            color: Colors.black54,
          )
              : Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder:
                (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }

              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              );
            },
            errorBuilder:
                (context, error, stackTrace) {
              return const Icon(
                Icons.person,
                size: 55,
                color: Colors.black54,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 2,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label :",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COURSE TABLE
  // ============================================================

  Widget _buildCourseTable(
      List<Map<String, dynamic>> courses,
      ) {
    return Table(
      border: TableBorder.all(
        color: Colors.black,
        width: 1,
      ),
      columnWidths: const {
        0: FixedColumnWidth(28),
        1: FixedColumnWidth(55),
        2: FlexColumnWidth(2.5),
        3: FixedColumnWidth(42),
        4: FixedColumnWidth(52),
        5: FixedColumnWidth(48),
        6: FixedColumnWidth(45),
      },
      children: [
        const TableRow(
          decoration:
          BoxDecoration(
            color: Color(0xFFF2F2F2),
          ),
          children: [
            _TableCell("S.No"),
            _TableCell("Course Code"),
            _TableCell("Course Name"),
            _TableCell("Grade"),
            _TableCell("Grade Point"),
            _TableCell("Result"),
            _TableCell("Credits"),
          ],
        ),

        ...List.generate(
          courses.length,
              (index) {
            final course =
            courses[index];

            return TableRow(
              children: [
                _TableCell(
                  "${index + 1}",
                ),
                _TableCell(
                  _stringValue(
                    course["courseCode"],
                  ),
                ),
                _TableCell(
                  _stringValue(
                    course["courseName"],
                  ),
                ),
                _TableCell(
                  _stringValue(
                    course["grade"],
                  ),
                ),
                _TableCell(
                  _numberValue(
                    course["gradePoint"],
                  ).toStringAsFixed(2),
                ),
                _TableCell(
                  _stringValue(
                    course["result"],
                  ),
                ),
                _TableCell(
                  _numberValue(
                    course["credits"],
                  ).toStringAsFixed(1),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary({
    required int registered,
    required int appeared,
    required int passed,
    required double totalCredits,
    required double? sgpa,
    required double? cgpa,
  }) {
    const TextStyle summaryStyle = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 11,
    );

    const TextStyle averageStyle = TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(
          color: Colors.black,
          thickness: 1,
          height: 1,
        ),

        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 6,
          ),
          child: Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              Text(
                "Course Registered : $registered",
                style: summaryStyle,
              ),

              Text(
                "Course Appeared : $appeared",
                style: summaryStyle,
              ),

              Text(
                "Course Passed : $passed",
                style: summaryStyle,
              ),

              Text(
                "Total Credits : ${totalCredits.toStringAsFixed(1)}",
                style: summaryStyle,
              ),
            ],
          ),
        ),

        const Divider(
          color: Colors.black,
          thickness: 1,
          height: 1,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            6,
            8,
            6,
            2,
          ),
          child: Text(
            "SEMESTER GRADE POINT AVERAGE (SGPA): "
                "${sgpa == null ? "Not Available" : sgpa.toStringAsFixed(2)}",
            style: averageStyle,
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            6,
            5,
            6,
            8,
          ),
          child: Text(
            "CUMULATIVE GRADE POINT AVERAGE (CGPA): "
                "${cgpa == null ? "Not Available" : cgpa.toStringAsFixed(2)}",
            style: averageStyle,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COURSES CONVERTER
  // ============================================================

  List<Map<String, dynamic>> _getCourses(
      dynamic value,
      ) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) =>
      Map<String, dynamic>.from(
        item,
      ),
    )
        .toList();
  }

  // ============================================================
  // STRING
  // ============================================================

  String _stringValue(
      dynamic value,
      ) {
    return value?.toString() ?? "";
  }

  // ============================================================
  // NUMBER
  // ============================================================

  double _numberValue(
      dynamic value,
      ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? "",
    ) ??
        0.0;
  }
  double? _nullableNumberValue(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }
}

// ================================================================
// TABLE CELL
// ================================================================

class _TableCell extends StatelessWidget {
  final String text;

  const _TableCell(
      this.text,
      );

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.all(5),
      child: Text(
        text,
        textAlign:
        TextAlign.center,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}