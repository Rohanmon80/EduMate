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

    final marks = await FirebaseFirestore.instance
        .collection("student_marks")
        .where("subjectCode", isEqualTo: subjectCode)
        .get();

    return students.docs.length - marks.docs.length;
  }
}