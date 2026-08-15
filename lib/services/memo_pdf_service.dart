import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MemoPdfService {
  // ============================================================
  // GENERATE PDF BYTES
  // ============================================================

  Future<Uint8List> generateMemoPdf({
    required Map<String, dynamic> memo,
  }) async {
    final pdf = pw.Document();

    // ------------------------------------------------------------
    // LOAD COLLEGE LOGOS
    // ------------------------------------------------------------

    final scientLogo =
    await _loadAsset(
      'assets/memo/scient_logo.png',
    );

    final ugcLogo =
    await _loadAsset(
      'assets/memo/ugc_logo.png',
    );

    final naacLogo =
    await _loadAsset(
      'assets/memo/naac_logo.png',
    );

    final jntuhLogo =
    await _loadAsset(
      'assets/memo/jntuh_logo.png',
    );

    // ------------------------------------------------------------
    // OPTIONAL STUDENT PHOTO
    // ------------------------------------------------------------

    pw.MemoryImage? studentPhoto;

    final studentImageUrl =
        memo["studentImageUrl"]
            ?.toString()
            .trim() ??
            "";

    if (studentImageUrl.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse(studentImageUrl),
        );

        if (response.statusCode == 200) {
          studentPhoto = pw.MemoryImage(
            response.bodyBytes,
          );
        }
      } catch (_) {
        studentPhoto = null;
      }
    }

    // ------------------------------------------------------------
    // STUDENT DETAILS
    // ------------------------------------------------------------

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

    // ------------------------------------------------------------
    // SUMMARY
    // ------------------------------------------------------------

    final courseRegistered =
    _numberValue(
      memo["courseRegistered"],
    ).toInt();

    final courseAppeared =
    _numberValue(
      memo["courseAppeared"],
    ).toInt();

    final coursePassed =
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

    // ------------------------------------------------------------
    // COURSES
    // ------------------------------------------------------------

    final courses =
    _getCourses(
      memo["courses"],
    );

    // ------------------------------------------------------------
    // PDF PAGE
    // ------------------------------------------------------------

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(
          28,
        ),
        build: (context) {
          return pw.Container(
            decoration:
            pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColors.black,
                width: 1.2,
              ),
            ),
            padding:
            const pw.EdgeInsets.all(
              12,
            ),
            child: pw.Column(
              crossAxisAlignment:
              pw.CrossAxisAlignment
                  .stretch,
              children: [
                // =================================================
                // HEADER
                // =================================================

                _buildHeader(
                  scientLogo: scientLogo,
                  ugcLogo: ugcLogo,
                  naacLogo: naacLogo,
                  jntuhLogo: jntuhLogo,
                ),

                pw.SizedBox(
                  height: 12,
                ),

                // =================================================
                // TITLE
                // =================================================

                pw.Container(
                  height: 34,
                  alignment:
                  pw.Alignment.center,
                  decoration:
                  pw.BoxDecoration(
                    border: pw.Border.all(
                      color:
                      PdfColors.black,
                      width: 1.0,
                    ),
                  ),
                  child: pw.Text(
                    "MARKS MEMO",
                    style:
                    pw.TextStyle(
                      fontSize: 15,
                      fontWeight:
                      pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(
                  height: 16,
                ),

                // =================================================
                // STUDENT INFORMATION
                // =================================================

                _buildStudentDetails(
                  studentName:
                  studentName,
                  rollNumber:
                  rollNumber,
                  program: program,
                  branch: branch,
                  year: year,
                  semester:
                  semester,
                  section:
                  section,

                  studentPhoto:
                  studentPhoto,
                ),

                pw.SizedBox(
                  height: 15,
                ),

                // =================================================
                // COURSE TABLE
                // =================================================

                _buildCourseTable(
                  courses,
                ),

                pw.SizedBox(
                  height: 0,
                ),

                // =================================================
                // SUMMARY
                // =================================================

                _buildSummary(
                  courseRegistered:
                  courseRegistered,
                  courseAppeared:
                  courseAppeared,
                  coursePassed:
                  coursePassed,
                  totalCredits:
                  totalCredits,
                ),

                // =================================================
                // SGPA / CGPA
                // =================================================

                _buildSgpaCgpa(
                  sgpa: sgpa,
                  cgpa: cgpa,
                ),

                pw.Spacer(),

                // =================================================
                // FOOTER
                // =================================================

                _buildFooter(
                  dateOfIssue:
                  dateOfIssue,
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ============================================================
  // HEADER
  // ============================================================

  pw.Widget _buildHeader({
    required pw.MemoryImage scientLogo,
    required pw.MemoryImage ugcLogo,
    required pw.MemoryImage naacLogo,
    required pw.MemoryImage jntuhLogo,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment:
          pw.CrossAxisAlignment
              .center,
          children: [
            // ----------------------------------------------------
            // SCIENT LOGO
            // ----------------------------------------------------

            pw.Container(
              width: 65,
              height: 65,
              child: pw.Image(
                scientLogo,
                fit:
                pw.BoxFit.contain,
              ),
            ),

            pw.SizedBox(
              width: 8,
            ),

            // ----------------------------------------------------
            // COLLEGE NAME
            // ----------------------------------------------------

            pw.Expanded(
              child: pw.Column(
                children: [
                  pw.Text(
                    "SCIENT INSTITUTE OF TECHNOLOGY",
                    textAlign:
                    pw.TextAlign
                        .center,
                    style:
                    pw.TextStyle(
                      fontSize: 13,
                      fontWeight:
                      pw.FontWeight
                          .bold,
                    ),
                  ),

                  pw.SizedBox(
                    height: 3,
                  ),

                  pw.Text(
                    "(UGC AUTONOMOUS)",
                    textAlign:
                    pw.TextAlign
                        .center,
                    style:
                    pw.TextStyle(
                      fontSize: 10,
                      fontWeight:
                      pw.FontWeight
                          .bold,
                    ),
                  ),

                  pw.SizedBox(
                    height: 3,
                  ),

                  pw.Text(
                    "Accredited by NAAC with 'A+' Grade, "
                        "Affiliated to JNTUH & Approved by AICTE",
                    textAlign:
                    pw.TextAlign
                        .center,
                    style:
                    const pw.TextStyle(
                      fontSize: 7,
                    ),
                  ),

                  pw.SizedBox(
                    height: 2,
                  ),

                  pw.Text(
                    "Ibrahimpatnam, Rangareddy, Telangana",
                    textAlign:
                    pw.TextAlign
                        .center,
                    style:
                    const pw.TextStyle(
                      fontSize: 7,
                    ),
                  ),

                  pw.SizedBox(
                    height: 2,
                  ),

                  pw.Text(
                    "www.scient.ac.in",
                    textAlign:
                    pw.TextAlign
                        .center,
                    style:
                    const pw.TextStyle(
                      fontSize: 7,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(
              width: 8,
            ),

            // ----------------------------------------------------
            // UGC / NAAC / JNTUH
            // ----------------------------------------------------

            pw.Row(
              children: [
                pw.Container(
                  width: 42,
                  height: 42,
                  child: pw.Image(
                    ugcLogo,
                    fit:
                    pw.BoxFit.contain,
                  ),
                ),

                pw.SizedBox(
                  width: 3,
                ),

                pw.Container(
                  width: 42,
                  height: 42,
                  child: pw.Image(
                    naacLogo,
                    fit:
                    pw.BoxFit.contain,
                  ),
                ),

                pw.SizedBox(
                  width: 3,
                ),

                pw.Container(
                  width: 42,
                  height: 42,
                  child: pw.Image(
                    jntuhLogo,
                    fit:
                    pw.BoxFit.contain,
                  ),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(
          height: 6,
        ),

        pw.Divider(
          color: PdfColors.black,
          thickness: 0.8,
        ),
      ],
    );
  }

  // ============================================================
  // STUDENT DETAILS
  // ============================================================

  pw.Widget _buildStudentDetails({
    required String studentName,
    required String rollNumber,
    required String program,
    required String branch,
    required String year,
    required int semester,
    required String section,

    required pw.MemoryImage? studentPhoto,
  }) {
    return pw.Row(
      crossAxisAlignment:
      pw.CrossAxisAlignment
          .start,
      children: [
        // --------------------------------------------------------
        // DETAILS
        // --------------------------------------------------------

        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment:
            pw.CrossAxisAlignment
                .start,
            children: [
              _detailLine(
                "Program",
                program,
              ),

              _detailLine(
                "Branch",
                branch,
              ),

              _detailLine(
                "Year",
                year,
              ),

              _detailLine(
                "Semester",
                "Semester $semester",
              ),

              _detailLine(
                "Section",
                section,
              ),



              _detailLine(
                "Name",
                studentName,
              ),
            ],
          ),
        ),

        pw.SizedBox(
          width: 15,
        ),

        // --------------------------------------------------------
        // HALL TICKET + PHOTO
        // --------------------------------------------------------

        pw.Column(
          crossAxisAlignment:
          pw.CrossAxisAlignment
              .end,
          children: [
            pw.Row(
              crossAxisAlignment:
              pw.CrossAxisAlignment
                  .center,
              children: [
                pw.Text(
                  "Hall Ticket No. :",
                  style:
                  pw.TextStyle(
                    fontSize: 9,
                    fontWeight:
                    pw.FontWeight
                        .bold,
                  ),
                ),

                pw.SizedBox(
                  width: 5,
                ),

                pw.Container(
                  width: 115,
                  height: 32,
                  alignment:
                  pw.Alignment.center,
                  decoration:
                  pw.BoxDecoration(
                    border:
                    pw.Border.all(
                      color:
                      PdfColors.black,
                      width: 0.8,
                    ),
                  ),
                  child: pw.Text(
                    rollNumber,
                    style:
                    pw.TextStyle(
                      fontSize: 11,
                      fontWeight:
                      pw.FontWeight
                          .bold,
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(
              height: 8,
            ),

            pw.Container(
              width: 90,
              height: 105,
              decoration:
              pw.BoxDecoration(
                border:
                pw.Border.all(
                  color:
                  PdfColors.black,
                  width: 0.8,
                ),
              ),
              child:
              studentPhoto != null
                  ? pw.Image(
                studentPhoto,
                fit:
                pw.BoxFit.cover,
              )
                  : pw.Center(
                child: pw.Text(
                  "PHOTO",
                  style:
                  const pw.TextStyle(
                    fontSize: 9,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // DETAIL LINE
  // ============================================================

  pw.Widget _detailLine(
      String label,
      String value,
      ) {
    return pw.Padding(
      padding:
      const pw.EdgeInsets.only(
        bottom: 5,
      ),
      child: pw.Row(
        crossAxisAlignment:
        pw.CrossAxisAlignment
            .start,
        children: [
          pw.SizedBox(
            width: 75,
            child: pw.Text(
              label,
              style:
              pw.TextStyle(
                fontSize: 9,
                fontWeight:
                pw.FontWeight
                    .bold,
              ),
            ),
          ),

          pw.Text(
            ": ",
            style:
            const pw.TextStyle(
              fontSize: 9,
            ),
          ),

          pw.Expanded(
            child: pw.Text(
              value,
              style:
              const pw.TextStyle(
                fontSize: 9,
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

  pw.Widget _buildCourseTable(
      List<Map<String, dynamic>>
      courses,
      ) {
    final rows =
    <pw.TableRow>[
      pw.TableRow(
        decoration:
        const pw.BoxDecoration(
          color:
          PdfColors.grey200,
        ),
        children: [
          _tableHeader(
            "S.No",
          ),
          _tableHeader(
            "COURSE CODE",
          ),
          _tableHeader(
            "COURSE NAME",
          ),
          _tableHeader(
            "GRADE\nSECURED",
          ),
          _tableHeader(
            "GRADE\nPOINT",
          ),
          _tableHeader(
            "RESULT",
          ),
          _tableHeader(
            "CREDITS",
          ),
        ],
      ),
    ];

    for (int i = 0;
    i < courses.length;
    i++) {
      final course =
      courses[i];

      rows.add(
        pw.TableRow(
          children: [
            _tableCell(
              "${i + 1}",
            ),
            _tableCell(
              _stringValue(
                course[
                "courseCode"],
              ),
            ),
            _tableCell(
              _stringValue(
                course[
                "courseName"],
              ),
              align:
              pw.TextAlign.left,
            ),
            _tableCell(
              _stringValue(
                course["grade"],
              ),
            ),
            _tableCell(
              _numberValue(
                course[
                "gradePoint"],
              ).toStringAsFixed(
                2,
              ),
            ),
            _tableCell(
              _stringValue(
                course["result"],
              ),
            ),
            _tableCell(
              _numberValue(
                course["credits"],
              ).toStringAsFixed(
                1,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border:
      pw.TableBorder.all(
        color: PdfColors.black,
        width: 0.7,
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(
          28,
        ),
        1: pw.FixedColumnWidth(
          75,
        ),
        2: pw.FlexColumnWidth(
          3,
        ),
        3: pw.FixedColumnWidth(
          55,
        ),
        4: pw.FixedColumnWidth(
          52,
        ),
        5: pw.FixedColumnWidth(
          48,
        ),
        6: pw.FixedColumnWidth(
          45,
        ),
      },
      children: rows,
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  pw.Widget _tableHeader(
      String text,
      ) {
    return pw.Container(
      padding:
      const pw.EdgeInsets.all(
        4,
      ),
      alignment:
      pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign:
        pw.TextAlign.center,
        style:
        pw.TextStyle(
          fontSize: 7,
          fontWeight:
          pw.FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // TABLE CELL
  // ============================================================

  pw.Widget _tableCell(
      String text, {
        pw.TextAlign align =
            pw.TextAlign.center,
      }) {
    return pw.Container(
      padding:
      const pw.EdgeInsets.all(
        4,
      ),
      alignment:
      align == pw.TextAlign.left
          ? pw.Alignment.centerLeft
          : pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: align,
        style:
        const pw.TextStyle(
          fontSize: 7.5,
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  pw.Widget _buildSummary({
    required int courseRegistered,
    required int courseAppeared,
    required int coursePassed,
    required double totalCredits,
  }) {
    return pw.Container(
      decoration:
      const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(
            color: PdfColors.black,
            width: 0.7,
          ),
          right: pw.BorderSide(
            color: PdfColors.black,
            width: 0.7,
          ),
          bottom: pw.BorderSide(
            color: PdfColors.black,
            width: 0.7,
          ),
        ),
      ),
      padding:
      const pw.EdgeInsets.all(
        6,
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              "Course Registered : $courseRegistered",
              style:
              pw.TextStyle(
                fontSize: 8,
                fontWeight:
                pw.FontWeight
                    .bold,
              ),
            ),
          ),

          pw.Expanded(
            child: pw.Text(
              "Course Appeared : $courseAppeared",
              style:
              pw.TextStyle(
                fontSize: 8,
                fontWeight:
                pw.FontWeight
                    .bold,
              ),
            ),
          ),

          pw.Expanded(
            child: pw.Text(
              "Course Passed : $coursePassed",
              style:
              pw.TextStyle(
                fontSize: 8,
                fontWeight:
                pw.FontWeight
                    .bold,
              ),
            ),
          ),

          pw.Container(
            width: 65,
            alignment:
            pw.Alignment.center,
            child: pw.Text(
              totalCredits
                  .toStringAsFixed(
                1,
              ),
              style:
              pw.TextStyle(
                fontSize: 9,
                fontWeight:
                pw.FontWeight
                    .bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SGPA / CGPA
  // ============================================================

  pw.Widget _buildSgpaCgpa({
    required double? sgpa,
    required double? cgpa,
  }) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          left: pw.BorderSide(
            color: PdfColors.black,
            width: 0.7,
          ),
          right: pw.BorderSide(
            color: PdfColors.black,
            width: 0.7,
          ),
          bottom: pw.BorderSide(
            color: PdfColors.black,
            width: 0.7,
          ),
        ),
      ),
      padding: const pw.EdgeInsets.all(7),
      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "SEMESTER GRADE POINT AVERAGE (SGPA): "
                "${sgpa == null ? "Not Available" : sgpa.toStringAsFixed(2)}",
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 8),

          pw.Text(
            "CUMULATIVE GRADE POINT AVERAGE (CGPA): "
                "${cgpa == null ? "Not Available" : cgpa.toStringAsFixed(2)}",
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  pw.Widget _buildFooter({
    required String dateOfIssue,
  }) {
    return pw.Row(
      mainAxisAlignment:
      pw.MainAxisAlignment
          .spaceBetween,
      crossAxisAlignment:
      pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          "Date of issue : $dateOfIssue",
          style:
          const pw.TextStyle(
            fontSize: 9,
          ),
        ),

        pw.Text(
          "CONTROLLER OF EXAMINATIONS",
          style:
          pw.TextStyle(
            fontSize: 9,
            fontWeight:
            pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SHARE / SAVE PDF
  //
  // Android will show the system share/save options.
  // ============================================================

  Future<void> shareMemo({
    required Map<String, dynamic> memo,
  }) async {
    final bytes =
    await generateMemoPdf(
      memo: memo,
    );

    final studentName =
    _stringValue(
      memo["studentName"],
    );

    final semester =
    _numberValue(
      memo["semester"],
    ).toInt();

    final safeName =
    studentName
        .replaceAll(
      RegExp(
        r'[^a-zA-Z0-9]+',
      ),
      "_",
    )
        .trim();

    final fileName =
        "${safeName}_Semester_${semester}_Marks_Memo.pdf";

    await Printing.sharePdf(
      bytes: bytes,
      filename: fileName,
    );
  }

  // ============================================================
  // PRINT / PDF PREVIEW
  // ============================================================

  Future<void> printMemo({
    required Map<String, dynamic> memo,
  }) async {
    final bytes =
    await generateMemoPdf(
      memo: memo,
    );

    await Printing.layoutPdf(
      onLayout: (_) async {
        return bytes;
      },
    );
  }

  // ============================================================
  // LOAD LOCAL ASSET
  // ============================================================

  Future<pw.MemoryImage> _loadAsset(
      String path,
      ) async {
    final data =
    await rootBundle.load(
      path,
    );

    return pw.MemoryImage(
      data.buffer.asUint8List(),
    );
  }

  // ============================================================
  // COURSES
  // ============================================================

  List<Map<String, dynamic>>
  _getCourses(
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