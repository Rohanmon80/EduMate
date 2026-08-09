import 'package:cloud_firestore/cloud_firestore.dart';

class ResultReleaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPendingResults() {
    return _firestore
        .collection("student_marks")
        .where("released", isEqualTo: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getReleasedResults() {
    return _firestore
        .collection("student_marks")
        .where("released", isEqualTo: true)
        .snapshots();
  }
  Stream<QuerySnapshot> getAllResults() {
    return _firestore
        .collection("student_marks")
        .snapshots();
  }

  Future<void> releaseResult(String docId) async {
    await _firestore
        .collection("student_marks")
        .doc(docId)
        .update({
      "released": true,
      "releasedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> unReleaseResult(String docId) async {
    await _firestore
        .collection("student_marks")
        .doc(docId)
        .update({
      "released": false,
      "releasedAt": null,
    });
  }
  Future<int> getMissingEntries({
    required String department,
    required String year,
    required int semester,
    required String section,
    required String subjectCode,
    required String exam,
  }) async {
    final students = await _firestore
        .collection("users")
        .where("role", isEqualTo: "student")
        .where("department", isEqualTo: department)
        .where("year", isEqualTo: year)
        .where("semester", isEqualTo: semester)
        .where("section", isEqualTo: section)
        .get();

    final uploaded = await _firestore
        .collection("student_marks")
        .where("subjectCode", isEqualTo: subjectCode)
        .where("exam", isEqualTo: exam)
        .where("department", isEqualTo: department)
        .where("year", isEqualTo: year)
        .where("semester", isEqualTo: semester)
        .where("section", isEqualTo: section)
        .get();

    // Count unique students who have uploaded marks.
    final uploadedStudentIds = uploaded.docs
        .map((doc) => doc.data()["studentId"]?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    final totalStudents = students.docs.length;

    final uploadedStudents =
    uploadedStudentIds.length > totalStudents
        ? totalStudents
        : uploadedStudentIds.length;

    final missing =
        totalStudents - uploadedStudents;

    return missing < 0 ? 0 : missing;
  }
  Future<int> getTotalMissingEntries({
    required String department,
    required String year,
    required int semester,
    required String section,
  }) async {
    // ------------------------------------------------------------
    // 1. Get all students for this class
    // ------------------------------------------------------------
    final studentsSnapshot = await _firestore
        .collection("users")
        .where("role", isEqualTo: "student")
        .where("department", isEqualTo: department)
        .where("year", isEqualTo: year)
        .where("semester", isEqualTo: semester)
        .where("section", isEqualTo: section)
        .get();

    final students = studentsSnapshot.docs;

    if (students.isEmpty) {
      return 0;
    }

    // ------------------------------------------------------------
    // 2. Get all subjects for this semester
    // ------------------------------------------------------------
    final subjectsSnapshot = await _firestore
        .collection("subjects")
        .where("department", isEqualTo: department)
        .where("year", isEqualTo: year)
        .where("semester", isEqualTo: semester)
        .where("isActive", isEqualTo: true)
        .get();

    final subjects = subjectsSnapshot.docs;

    if (subjects.isEmpty) {
      return 0;
    }

    // ------------------------------------------------------------
    // 3. Get uploaded marks for this class
    // ------------------------------------------------------------
    final marksSnapshot = await _firestore
        .collection("student_marks")
        .where("department", isEqualTo: department)
        .where("year", isEqualTo: year)
        .where("semester", isEqualTo: semester)
        .where("section", isEqualTo: section)
        .get();

    // ------------------------------------------------------------
    // 4. Create unique uploaded combinations
    //
    // student + subject + exam
    // ------------------------------------------------------------
    final uploaded = <String>{};

    for (final doc in marksSnapshot.docs) {
      final data = doc.data();

      final studentId =
      data["studentId"]?.toString();

      final subjectCode =
      data["subjectCode"]?.toString();

      final exam =
      data["exam"]?.toString();

      if (studentId == null ||
          subjectCode == null ||
          exam == null ||
          studentId.isEmpty ||
          subjectCode.isEmpty ||
          exam.isEmpty) {
        continue;
      }

      uploaded.add(
        "$studentId|$subjectCode|$exam",
      );
    }

    // ------------------------------------------------------------
    // 5. Calculate expected entries
    // ------------------------------------------------------------
    int totalMissing = 0;

    for (final student in students) {
      final studentId = student.id;

      for (final subject in subjects) {
        final data = subject.data();

        final subjectCode =
        data["subjectCode"]?.toString();

        if (subjectCode == null ||
            subjectCode.isEmpty) {
          continue;
        }

        final type =
            data["type"]?.toString().toLowerCase() ??
                "theory";

        final exams = type == "lab"
            ? [
          "Lab Internal 1",
          "Lab Internal 2",
          "Lab External",
        ]
            : [
          "Mid 1",
          "Mid 2",
          "Sem External",
        ];

        for (final exam in exams) {
          final key =
              "$studentId|$subjectCode|$exam";

          if (!uploaded.contains(key)) {
            totalMissing++;
          }
        }
      }
    }

    return totalMissing;
  }
}