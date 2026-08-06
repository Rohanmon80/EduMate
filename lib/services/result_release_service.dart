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

    final students = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "student")
        .where("department", isEqualTo: department)
        .where("year", isEqualTo: year)
        .where("semester", isEqualTo: semester)
        .where("section", isEqualTo: section)
        .get();

    final uploaded = await FirebaseFirestore.instance
        .collection("student_marks")
        .where("subjectCode", isEqualTo: subjectCode)
        .where("exam", isEqualTo: exam)
        .where("department", isEqualTo: department)
        .where("year", isEqualTo: year)
        .where("semester", isEqualTo: semester)
        .where("section", isEqualTo: section)
        .get();

    return students.docs.length - uploaded.docs.length;
  }
  Future<int> getTotalMissingEntries() async {

    final students = await FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "student")
        .get();

    final uploaded = await FirebaseFirestore.instance
        .collection("student_marks")
        .get();

    return students.docs.length - uploaded.docs.length;
  }
  Future<int> getTeachersPending() async {

    final teachers = await FirebaseFirestore.instance
        .collection("teachers")
        .get();

    final uploaded = await FirebaseFirestore.instance
        .collection("student_marks")
        .get();

    final uploadedTeachers = uploaded.docs
        .map((e) => e["teacherId"] as String)
        .toSet();

    int pending = 0;

    for (final teacher in teachers.docs) {

      if (!uploadedTeachers.contains(teacher.id)) {
        pending++;
      }

    }

    return pending;
  }
}