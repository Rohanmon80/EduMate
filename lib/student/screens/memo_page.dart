import 'package:flutter/material.dart';

import '../../services/memo_service.dart';
import '../widgets/memo_header.dart';
import '../widgets/memo_student_details.dart';
import '../widgets/memo_subject_table.dart';
import '../widgets/memo_summary_card.dart';

class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  int _selectedSemesterNumber() {
    switch (selectedSemester) {
      case 'I Year I Semester':
        return 1;
      case 'I Year II Semester':
        return 2;
      case 'II Year I Semester':
        return 3;
      case 'II Year II Semester':
        return 4;
      case 'III Year I Semester':
        return 5;
      case 'III Year II Semester':
        return 6;
      case 'IV Year I Semester':
        return 7;
      case 'IV Year II Semester':
        return 8;
      default:
        return 1;
    }
  }
  final MemoService service = MemoService();

  String? selectedSemester;
  String? selectedExamType;
  String? selectedExamName;

  bool showMemo = false;

  final List<String> semesters = [
    'I Year I Semester',
    'I Year II Semester',
    'II Year I Semester',
    'II Year II Semester',
    'III Year I Semester',
    'III Year II Semester',
    'IV Year I Semester',
    'IV Year II Semester',
  ];

  final List<String> examTypes = [
    'Regular',
    'Supply',
  ];

  final List<String> examNames = [
    'End Semester Examination',
    'Supplementary Examination',
  ];

  @override
  Widget build(BuildContext context) {
    if (showMemo) {
      return _buildMemoPage();
    }

    return _buildSelectionPage();
  }

  // ============================================================
  // MEMO SELECTION PAGE
  // ============================================================

  Widget _buildSelectionPage() {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Print Marks Memo',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            const SizedBox(height: 25),

            // ----------------------------------------------------
            // SELECT SEMESTER
            // ----------------------------------------------------

            _buildDropdown(
              hint: 'Select Semester',
              value: selectedSemester,
              items: semesters,
              onChanged: (value) {
                setState(() {
                  selectedSemester = value;
                });
              },
            ),

            const SizedBox(height: 28),

            // ----------------------------------------------------
            // SELECT EXAM TYPE
            // ----------------------------------------------------

            _buildDropdown(
              hint: 'Select Exam Type',
              value: selectedExamType,
              items: examTypes,
              onChanged: (value) {
                setState(() {
                  selectedExamType = value;

                  // Reset exam name whenever exam type changes.
                  selectedExamName = null;
                });
              },
            ),

            const SizedBox(height: 28),

            // ----------------------------------------------------
            // SELECT EXAM NAME
            // ----------------------------------------------------

            _buildDropdown(
              hint: 'Select Exam Name',
              value: selectedExamName,
              items: examNames,
              onChanged: selectedExamType == null
                  ? null
                  : (value) {
                setState(() {
                  selectedExamName = value;
                });
              },
            ),

            const SizedBox(height: 45),

            // ----------------------------------------------------
            // PRINT MEMO BUTTON
            // ----------------------------------------------------

            SizedBox(
              height: 62,

              child: ElevatedButton.icon(
                onPressed: _canPrintMemo()
                    ? _openMemo
                    : null,

                icon: const Icon(
                  Icons.print,
                  size: 28,
                  color: Colors.white,
                ),

                label: const Text(
                  'Print Memo',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Container(
      height: 90,

      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade500,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(22),
      ),

      padding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,

          isExpanded: true,

          icon: const Icon(
            Icons.arrow_drop_down,
            size: 35,
            color: Colors.grey,
          ),

          hint: Text(
            hint,
            style: const TextStyle(
              fontSize: 22,
              color: Color(0xFF444444),
            ),
          ),

          style: const TextStyle(
            fontSize: 22,
            color: Colors.black87,
          ),

          items: items.map(
                (item) {
              return DropdownMenuItem<String>(
                value: item,

                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
              );
            },
          ).toList(),

          onChanged: onChanged,
        ),
      ),
    );
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _canPrintMemo() {
    return selectedSemester != null &&
        selectedExamType != null &&
        selectedExamName != null;
  }

  // ============================================================
  // OPEN MEMO
  // ============================================================

  void _openMemo() {
    if (!_canPrintMemo()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select semester, exam type and exam name.',
          ),
        ),
      );

      return;
    }

    setState(() {
      showMemo = true;
    });
  }

  // ============================================================
  // ACTUAL MEMO PAGE
  // ============================================================

  Widget _buildMemoPage() {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,

      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
          ),

          onPressed: () {
            setState(() {
              showMemo = false;
            });
          },
        ),

        title: const Text(
          'Provisional Memo',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),

        centerTitle: true,
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 900,

            margin: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(15),

              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                ),
              ],
            ),

            child: Padding(
              padding: const EdgeInsets.all(25),

              child: Column(
                children: [

                  // ------------------------------------------------
                  // SELECTED DETAILS
                  // ------------------------------------------------

                  _buildSelectedExamDetails(),

                  const SizedBox(height: 25),

                  // ------------------------------------------------
                  // EXISTING MEMO HEADER
                  // ------------------------------------------------

                  const MemoHeader(),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // STUDENT DETAILS
                  // ------------------------------------------------

                  const MemoStudentDetails(),

                  const SizedBox(height: 25),

                  // ------------------------------------------------
                  // SUBJECT TABLE
                  // ------------------------------------------------

                  MemoSubjectTable(
                    semester: _selectedSemesterNumber(),
                    examType: selectedExamType!,
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // SUMMARY
                  // ------------------------------------------------

                  MemoSummaryCard(
                    semester: _selectedSemesterNumber(),
                    examType: selectedExamType!,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECTED EXAM INFORMATION
  // ============================================================

  Widget _buildSelectedExamDetails() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),

        borderRadius: BorderRadius.circular(12),

        border: Border.all(
          color: const Color(0xFF2196F3),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Text(
            selectedSemester ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Exam Type: ${selectedExamType ?? ''}',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Exam: ${selectedExamName ?? ''}',
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}