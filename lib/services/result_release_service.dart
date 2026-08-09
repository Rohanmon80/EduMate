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
    final students = await _firestore
        .collection("users")
        .where("role", isEqualTo: "student")
        .where("department", isEqualTo: department)
        .where("year", isEqualTo: year)
        .where("semester", isEqualTo: semester)
        .where("section", isEqualTo: section)
        .get();

    if (students.docs.isEmpty) {
      return 0;
    }

    final marks = await _firestore
        .collection("student_marks")
        .where("department", isEqualTo: department)
        .where("year", isEqualTo: year)
        .where("semester", isEqualTo: semester)
        .where("section", isEqualTo: section)
        .get();

    // Unique student + subject + exam combinations.
    final uploadedCombinations = marks.docs.map((doc) {
      final data = doc.data();

      final studentId =
          data["studentId"]?.toString() ?? "";

      final subjectCode =
          data["subjectCode"]?.toString() ?? "";

      final exam =
          data["exam"]?.toString() ?? "";

      return "$studentId|$subjectCode|$exam";
    }).toSet();

    /*
   * This function should only be used as an overall
   * uploaded-count helper.
   *
   * Exact missing count for a particular subject/exam
   * must use getMissingEntries().
   */

    return uploadedCombinations.isEmpty
        ? students.docs.length
        : 0;
  }
  Future<int> getTeachersPending({
    required String department,
    required String year,
    required int semester,
    required String section,
  }) async {
    final teachers = await _firestore
        .collection("teachers")
        .get();

    final marks = await _firestore
        .collection("student_marks")
        .where("department", isEqualTo: department)
        .where("year", isEqualTo: year)
        .where("semester", isEqualTo: semester)
        .where("section", isEqualTo: section)
        .get();

    final uploadedTeacherIds = marks.docs
        .map(
          (doc) =>
          doc.data()["teacherId"]?.toString(),
    )
        .where(
          (id) => id != null && id.isNotEmpty,
    )
        .toSet();

    int pending = 0;

    for (final teacher in teachers.docs) {
      if (!uploadedTeacherIds.contains(teacher.id)) {
        pending++;
      }
    }

    return pending;
  }
}