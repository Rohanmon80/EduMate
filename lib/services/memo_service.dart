import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemoService {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // CURRENT USER ID
  // ============================================================

  String? get currentStudentId {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  // ============================================================
  // GET STUDENT
  // ============================================================

  Future<Map<String, dynamic>?> getStudent({
    String? studentId,
  }) async {
    final uid =
        studentId ?? currentStudentId;

    if (uid == null || uid.isEmpty) {
      return null;
    }

    final doc = await firestore
        .collection("users")
        .doc(uid)
        .get();

    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  // ============================================================
  // GET CREDITS
  // ============================================================

  Future<double> getCredits(
      String subjectCode,
      ) async {
    final snapshot = await firestore
        .collection("subjects")
        .where(
      "subjectCode",
      isEqualTo: subjectCode,
    )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 0.0;
    }

    final value =
    snapshot.docs.first.data()["credits"];

    return value is num
        ? value.toDouble()
        : 0.0;
  }

  // ============================================================
  // GET RESULTS FOR ONE SEMESTER
  // ============================================================

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getResults(
      int semester, {
        String? studentId,
      }) async {
    final uid =
        studentId ?? currentStudentId;

    if (uid == null || uid.isEmpty) {
      return [];
    }

    final snapshot = await firestore
        .collection("student_marks")
        .where(
      "studentId",
      isEqualTo: uid,
    )
        .where(
      "semester",
      isEqualTo: semester,
    )
        .where(
      "released",
      isEqualTo: true,
    )
        .get();

    return snapshot.docs;
  }

  // ============================================================
  // GET SUBJECT
  // ============================================================

  Future<Map<String, dynamic>?> getSubject(
      String subjectCode,
      ) async {
    final snapshot = await firestore
        .collection("subjects")
        .where(
      "subjectCode",
      isEqualTo: subjectCode,
    )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.data();
  }

  // ============================================================
  // GET SUBJECTS FOR SEMESTER
  // ============================================================

  Future<List<Map<String, dynamic>>> getSemesterSubjects({
    required int semester,
    required Map<String, dynamic> student,
  }) async {
    final department =
        student["department"]?.toString() ?? "";

    final year =
        student["year"]?.toString() ?? "";

    final snapshot = await firestore
        .collection("subjects")
        .where(
      "semester",
      isEqualTo: semester,
    )
        .get();

    final subjects =
    <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final subjectDepartment =
          data["department"]?.toString() ?? "";

      final subjectYear =
          data["year"]?.toString() ?? "";

      final active =
          data["isActive"] ?? true;

      if (!active) {
        continue;
      }

      if (department.isNotEmpty &&
          subjectDepartment.isNotEmpty &&
          subjectDepartment != department) {
        continue;
      }

      if (year.isNotEmpty &&
          subjectYear.isNotEmpty &&
          subjectYear != year) {
        continue;
      }

      subjects.add(data);
    }

    return subjects;
  }

  // ============================================================
  // GRADE CALCULATION
  // SAME RULES AS SEMESTER RESULTS PAGE
  // ============================================================

  Map<String, dynamic> calculateGrade({
    required double average,
    required double external,
    required double total,
  }) {
    final bool pass =
        average >= 14 &&
            external >= 21 &&
            total >= 40;

    String grade = "F";
    double gradePoint = 0.0;

    if (pass) {
      if (total >= 90) {
        grade = "O";
        gradePoint = 10.0;
      } else if (total >= 80) {
        grade = "A+";
        gradePoint = 9.0;
      } else if (total >= 70) {
        grade = "A";
        gradePoint = 8.0;
      } else if (total >= 60) {
        grade = "B+";
        gradePoint = 7.0;
      } else if (total >= 50) {
        grade = "B";
        gradePoint = 6.0;
      } else {
        grade = "C";
        gradePoint = 5.0;
      }
    }

    return {
      "pass": pass,
      "grade": grade,
      "gradePoint": gradePoint,
    };
  }

  // ============================================================
  // BUILD ONE SUBJECT RESULT
  //
  // THEORY:
  // Mid 1
  // Mid 2
  // External
  //
  // LAB:
  // Lab Internal 1
  // Lab Internal 2
  // Lab External
  //
  // REGULAR + SUPPLY
  // ============================================================

  Map<String, dynamic> buildSubjectResult(
      List<Map<String, dynamic>> marks,
      ) {
    double? regularInternal1;
    double? regularInternal2;
    double? regularExternal;

    double? supplyInternal1;
    double? supplyInternal2;
    double? supplyExternal;

    bool isLab = false;

    String subjectCode = "";
    String subjectName = "";
    String subjectType = "";

    double credits = 0.0;

    bool hasSupply = false;

    // ------------------------------------------------------------
    // READ ALL MARKS
    // ------------------------------------------------------------

    for (final item in marks) {
      subjectCode =
          item["subjectCode"]?.toString() ??
              subjectCode;

      subjectName =
          item["subjectName"]?.toString() ??
              subjectName;

      subjectType =
          item["type"]?.toString() ??
              subjectType;

      final type =
          item["type"]
              ?.toString()
              .trim()
              .toLowerCase() ??
              "";

      if (type == "lab") {
        isLab = true;
      }

      final category =
          item["examCategory"]
              ?.toString()
              .trim()
              .toLowerCase() ??
              "regular";

      final bool isSupply =
          category == "supply";

      if (isSupply) {
        hasSupply = true;
      }

      final value =
      (item["marks"] as num?)?.toDouble();

      if (value == null) {
        continue;
      }

      final exam =
          item["exam"]
              ?.toString()
              .trim() ??
              "";

      // ----------------------------------------------------------
      // THEORY
      // ----------------------------------------------------------

      if (!isLab) {
        if (exam == "Mid 1") {
          if (isSupply) {
            supplyInternal1 = value;
          } else {
            regularInternal1 = value;
          }
        } else if (exam == "Mid 2") {
          if (isSupply) {
            supplyInternal2 = value;
          } else {
            regularInternal2 = value;
          }
        } else if (
        exam == "Sem External" ||
            exam == "External") {
          if (isSupply) {
            supplyExternal = value;
          } else {
            regularExternal = value;
          }
        }
      }

      // ----------------------------------------------------------
      // LAB
      // ----------------------------------------------------------

      else {
        if (exam == "Lab Internal 1") {
          if (isSupply) {
            supplyInternal1 = value;
          } else {
            regularInternal1 = value;
          }
        } else if (exam == "Lab Internal 2") {
          if (isSupply) {
            supplyInternal2 = value;
          } else {
            regularInternal2 = value;
          }
        } else if (exam == "Lab External") {
          if (isSupply) {
            supplyExternal = value;
          } else {
            regularExternal = value;
          }
        }
      }

      final creditValue =
      (item["credits"] as num?)?.toDouble();

      if (creditValue != null) {
        credits = creditValue;
      }
    }

    // ============================================================
    // REGULAR RESULT
    // ============================================================

    final double? regularAverage =
    regularInternal1 != null &&
        regularInternal2 != null
        ? (regularInternal1 +
        regularInternal2) /
        2
        : null;

    final double? regularTotal =
    regularAverage != null &&
        regularExternal != null
        ? regularAverage +
        regularExternal
        : null;

    final bool regularPassed =
        regularAverage != null &&
            regularExternal != null &&
            regularAverage >= 14 &&
            regularExternal >= 21 &&
            regularTotal! >= 40;

    // ============================================================
    // FINAL RESULT
    //
    // If Regular passes:
    //     use Regular.
    //
    // If Regular fails:
    //     use Supply where available,
    //     otherwise keep Regular marks.
    // ============================================================

    final double? internal1 =
    regularPassed
        ? regularInternal1
        : supplyInternal1 ??
        regularInternal1;

    final double? internal2 =
    regularPassed
        ? regularInternal2
        : supplyInternal2 ??
        regularInternal2;

    final double? external =
    regularPassed
        ? regularExternal
        : supplyExternal ??
        regularExternal;

    final String examCategory =
    regularPassed
        ? "Regular"
        : hasSupply
        ? "Supply"
        : "Regular";

    // ============================================================
    // MISSING MARKS
    // ============================================================

    if (internal1 == null ||
        internal2 == null ||
        external == null) {
      return {
        "subjectCode": subjectCode,
        "subjectName": subjectName,
        "type": subjectType,
        "credits": credits,
        "average": null,
        "external": external,
        "total": null,
        "grade": "F",
        "gradePoint": 0.0,
        "pass": false,
        "pending": true,
        "examCategory": examCategory,
      };
    }

    // ============================================================
    // FINAL CALCULATION
    // ============================================================

    final double average =
        (internal1 + internal2) / 2;

    final double total =
        average + external;

    final result = calculateGrade(
      average: average,
      external: external,
      total: total,
    );

    return {
      "subjectCode": subjectCode,
      "subjectName": subjectName,
      "type": subjectType,
      "credits": credits,
      "average": average,
      "external": external,
      "total": total,
      "grade": result["grade"],
      "gradePoint":
      (result["gradePoint"] as num)
          .toDouble(),
      "pass": result["pass"],
      "pending": false,
      "examCategory": examCategory,
    };
  }

  // ============================================================
  // CALCULATE SGPA
  // ============================================================

  double calculateSGPA(
      List<Map<String, dynamic>> subjects,
      ) {
    double totalCredits = 0.0;
    double totalCreditPoints = 0.0;

    for (final subject in subjects) {
      final credits =
          (subject["credits"] as num?)
              ?.toDouble() ??
              0.0;

      final gradePoint =
          (subject["gradePoint"] as num?)
              ?.toDouble() ??
              0.0;

      totalCredits += credits;

      totalCreditPoints +=
          credits * gradePoint;
    }

    if (totalCredits == 0) {
      return 0.0;
    }

    return totalCreditPoints /
        totalCredits;
  }

  // ============================================================
  // GROUP MARKS BY SUBJECT
  // ============================================================

  Map<String, List<Map<String, dynamic>>>
  groupMarksBySubject(
      List<QueryDocumentSnapshot<Map<String, dynamic>>>
      documents,
      ) {
    final grouped =
    <String, List<Map<String, dynamic>>>{};

    for (final doc in documents) {
      final data = doc.data();

      final code =
          data["subjectCode"]
              ?.toString()
              .trim() ??
              "";

      if (code.isEmpty) {
        continue;
      }

      grouped
          .putIfAbsent(
        code,
            () => [],
      )
          .add(data);
    }

    return grouped;
  }

  // ============================================================
  // GET CURRENT CGPA
  //
  // Same weighted approach used by the Results page:
  //
  // total credit points / total credits
  //
  // Only completed semesters contribute.
  // ============================================================

  Future<double?> calculateCurrentCGPA({
    required String studentId,
    required int currentSemester,
  }) async {
    final snapshot = await firestore
        .collection("student_marks")
        .where(
      "studentId",
      isEqualTo: studentId,
    )
        .where(
      "released",
      isEqualTo: true,
    )
        .get();

    final Map<int, List<Map<String, dynamic>>> semesterMarks = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final int? semester =
      (data["semester"] as num?)?.toInt();

      if (semester == null ||
          semester < 1 ||
          semester > currentSemester) {
        continue;
      }

      semesterMarks
          .putIfAbsent(
        semester,
            () => [],
      )
          .add(data);
    }

    double totalCreditPoints = 0.0;
    double totalCredits = 0.0;

    // ============================================================
    // EVERY SEMESTER FROM 1 TO CURRENT MUST BE COMPLETE
    // ============================================================

    for (
    int semester = 1;
    semester <= currentSemester;
    semester++
    ) {
      final marks =
      semesterMarks[semester];

      // No released marks for a required semester
      if (marks == null || marks.isEmpty) {
        return null;
      }

      // ----------------------------------------------------------
      // Group by subject
      // ----------------------------------------------------------

      final subjects =
      <String, List<Map<String, dynamic>>>{};

      for (final mark in marks) {
        final code =
            mark["subjectCode"]
                ?.toString()
                .trim() ??
                "";

        if (code.isEmpty) {
          continue;
        }

        subjects
            .putIfAbsent(
          code,
              () => [],
        )
            .add(mark);
      }

      if (subjects.isEmpty) {
        return null;
      }

      // ----------------------------------------------------------
      // Build subject results
      // ----------------------------------------------------------

      final results =
      <Map<String, dynamic>>[];

      for (final subjectMarks
      in subjects.values) {
        results.add(
          buildSubjectResult(
            subjectMarks,
          ),
        );
      }

      if (results.isEmpty) {
        return null;
      }

      // ----------------------------------------------------------
      // EVERY SUBJECT MUST PASS
      // ----------------------------------------------------------

      final bool semesterPassed =
      results.every(
            (result) =>
        result["pending"] != true &&
            result["pass"] == true,
      );

      // IMPORTANT:
      // Never skip a failed semester.
      if (!semesterPassed) {
        return null;
      }

      // ----------------------------------------------------------
      // CREDIT-WEIGHTED FCGPA
      // ----------------------------------------------------------

      for (final result in results) {
        final double credits =
            (result["credits"] as num?)
                ?.toDouble() ??
                0.0;

        final double gradePoint =
            (result["gradePoint"] as num?)
                ?.toDouble() ??
                0.0;

        if (credits <= 0) {
          return null;
        }

        totalCredits += credits;

        totalCreditPoints +=
            credits * gradePoint;
      }
    }

    if (totalCredits <= 0) {
      return null;
    }

    return totalCreditPoints /
        totalCredits;
  }

  // ============================================================
  // ACADEMIC YEAR
  // ============================================================

  String getCurrentAcademicYear() {
    final now = DateTime.now();

    final int startYear =
    now.month >= 6
        ? now.year
        : now.year - 1;

    return "$startYear-${(startYear + 1).toString().substring(2)}";
  }

  // ============================================================
  // BRANCH NAME
  // ============================================================

  String getBranchName(
      String department,
      ) {
    switch (
    department.trim().toUpperCase()) {
      case "AIML":
      case "AI&ML":
      case "AI ML":
        return "ARTIFICIAL INTELLIGENCE AND MACHINE LEARNING";

      case "CSE":
        return "COMPUTER SCIENCE AND ENGINEERING";

      case "ECE":
        return "ELECTRONICS AND COMMUNICATION ENGINEERING";

      case "EEE":
        return "ELECTRICAL AND ELECTRONICS ENGINEERING";

      case "MECH":
        return "MECHANICAL ENGINEERING";

      case "CIVIL":
        return "CIVIL ENGINEERING";

      default:
        return department;
    }
  }

  // ============================================================
  // GENERATE MEMO
  //
  // This creates:
  //
  // marks_memos/{studentId}_sem{semester}
  //
  // Example:
  //
  // marks_memos/
  //   GYqzP6M..._sem5
  // ============================================================

  Future<DocumentReference<Map<String, dynamic>>>
  generateMemo({
    required String studentId,
    required int semester,
  }) async {
    // ----------------------------------------------------------
    // STUDENT
    // ----------------------------------------------------------

    final student =
    await getStudent(
      studentId: studentId,
    );

    if (student == null) {
      throw Exception(
        "Student record was not found.",
      );
    }

    // ----------------------------------------------------------
    // RELEASED MARKS
    // ----------------------------------------------------------

    final markDocuments =
    await getResults(
      semester,
      studentId: studentId,
    );

    if (markDocuments.isEmpty) {
      throw Exception(
        "No released marks found for this semester.",
      );
    }

    // ----------------------------------------------------------
    // GROUP MARKS
    // ----------------------------------------------------------

    final groupedMarks =
    groupMarksBySubject(
      markDocuments,
    );

    // ----------------------------------------------------------
    // BUILD FINAL COURSE RESULTS
    // ----------------------------------------------------------

    final courses =
    <Map<String, dynamic>>[];

    for (final entry
    in groupedMarks.entries) {
      final result =
      buildSubjectResult(
        entry.value,
      );

      courses.add({
        "courseCode":
        result["subjectCode"]
            ?.toString() ??
            "",

        "courseName":
        result["subjectName"]
            ?.toString() ??
            "",

        "grade":
        result["grade"]
            ?.toString() ??
            "F",

        "gradePoint":
        ((result["gradePoint"]
        as num?)
            ?.toDouble() ??
            0.0),

        "result":
        result["pass"] == true
            ? "PASS"
            : "FAIL",

        "credits":
        ((result["credits"]
        as num?)
            ?.toDouble() ??
            0.0),
      });
    }

    // ----------------------------------------------------------
    // CHECK PENDING SUBJECTS
    // ----------------------------------------------------------

    final pendingCourses =
    courses.where(
          (course) =>
      course["grade"] == "F" &&
          course["result"] != "PASS",
    );

    /*
      IMPORTANT:

      A failed subject is NOT automatically "pending".

      It can be a completed result with grade F.

      Therefore we separately inspect the original
      subject results for pending marks.
    */

    final pendingResults =
    groupedMarks.values
        .map(
      buildSubjectResult,
    )
        .where(
          (result) =>
      result["pending"] == true,
    )
        .toList();

    if (pendingResults.isNotEmpty) {
      final pendingCodes =
      pendingResults
          .map(
            (e) =>
        e["subjectCode"]
            ?.toString() ??
            "",
      )
          .where(
            (code) =>
        code.isNotEmpty,
      )
          .join(", ");

      throw Exception(
        "Cannot generate memo. Missing marks for: $pendingCodes",
      );
    }

    // ----------------------------------------------------------
    // SORT COURSES BY COURSE CODE
    // ----------------------------------------------------------

    courses.sort(
          (a, b) =>
          (a["courseCode"] as String)
              .compareTo(
            b["courseCode"] as String,
          ),
    );

    // ----------------------------------------------------------
    // SUMMARY
    // ----------------------------------------------------------

    final int courseRegistered =
        courses.length;

    final int courseAppeared =
        courses.length;

    final int coursePassed =
        courses.where(
              (course) =>
          course["result"] ==
              "PASS",
        ).length;

    final double totalCredits =
    courses.fold<double>(
      0.0,
          (sum, course) =>
      sum +
          ((course["credits"]
          as num?)
              ?.toDouble() ??
              0.0),
    );

    final bool semesterPassed =
        courses.isNotEmpty &&
            courses.every(
                  (course) =>
              course["result"] == "PASS",
            );

    final double? sgpa =
    semesterPassed
        ? calculateSGPA(
      courses
          .map(
            (course) => <String, dynamic>{
          "credits": course["credits"],
          "gradePoint": course["gradePoint"],
        },
      )
          .toList(),
    )
        : null;

    // ----------------------------------------------------------
    // CGPA
    // ----------------------------------------------------------

    final double? calculatedCGPA =
    await calculateCurrentCGPA(
      studentId: studentId,
      currentSemester: semester,
    );

    // ----------------------------------------------------------
    // STUDENT INFORMATION
    // ----------------------------------------------------------

    final String studentName =
        student["name"]?.toString() ??
            "";

    final String rollNumber =
        student["rollNumber"]
            ?.toString() ??
            "";

    final String department =
        student["department"]
            ?.toString() ??
            "";

    final String branch =
    getBranchName(
      department,
    );

    final String year =
        student["year"]?.toString() ??
            "";

    final String section =
        student["section"]
            ?.toString() ??
            "";

    final String studentImageUrl =
        student["photoUrl"]
            ?.toString() ??
            "";

    // ----------------------------------------------------------
    // MEMO DOCUMENT ID
    // ----------------------------------------------------------

    final String documentId =
        "${studentId}_sem$semester";

    final memoReference =
    firestore
        .collection("marks_memos")
        .doc(documentId);

    // ----------------------------------------------------------
    // MEMO DATA
    // ----------------------------------------------------------

    final memoData =
    <String, dynamic>{
      "studentId": studentId,

      "studentName": studentName,

      // Your users collection calls this
      // rollNumber, and your sample memo uses
      // this number as the Hall Ticket Number.
      "rollNumber": rollNumber,

      "program": "B.Tech",

      "branch": branch,

      "year": year,

      "semester": semester,

      "section": section,

      "studentImageUrl":
      studentImageUrl,



      "dateOfIssue":
      DateTime.now()
          .toIso8601String()
          .split("T")
          .first,

      "courseRegistered":
      courseRegistered,

      "courseAppeared":
      courseAppeared,

      "coursePassed":
      coursePassed,

      "totalCredits":
      totalCredits,

      "sgpa":
      sgpa == null
          ? null
          : double.parse(
        sgpa.toStringAsFixed(2),
      ),

      "cgpa":
      calculatedCGPA == null
          ? null
          : double.parse(
        calculatedCGPA
            .toStringAsFixed(2),
      ),

      "courses": courses,

      "memoStatus":
      "generated",

      "updatedAt":
      FieldValue.serverTimestamp(),
    };

    // ----------------------------------------------------------
    // CREATE OR UPDATE
    // ----------------------------------------------------------

    final existing =
    await memoReference.get();

    if (existing.exists) {
      await memoReference.update(
        memoData,
      );
    } else {
      await memoReference.set({
        ...memoData,
        "createdAt":
        FieldValue
            .serverTimestamp(),
      });
    }

    return memoReference;
  }

  // ============================================================
  // GENERATE MEMO FOR CURRENT STUDENT
  // ============================================================

  Future<DocumentReference<Map<String, dynamic>>>
  generateCurrentStudentMemo({
    required int semester,
  }) async {
    final uid =
        currentStudentId;

    if (uid == null) {
      throw Exception(
        "No logged-in student found.",
      );
    }

    return generateMemo(
      studentId: uid,
      semester: semester,
    );
  }

  // ============================================================
  // GET EXISTING MEMO
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
  getMemo({
    required String studentId,
    required int semester,
  }) async {
    final documentId =
        "${studentId}_sem$semester";

    final doc = await firestore
        .collection("marks_memos")
        .doc(documentId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return doc;
  }
}