import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class MemoService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Future<int> getCredits(String subjectCode) async {

    final snapshot = await firestore
        .collection("subjects")
        .where("subjectCode", isEqualTo: subjectCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 0;
    }

    return (snapshot.docs.first["credits"] as num).toInt();
  }

  Future<Map<String, dynamic>?> getStudent() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await firestore
        .collection("students")
        .doc(uid)
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }

  Future<List<QueryDocumentSnapshot>> getResults(
      int semester) async {

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snapshot = await firestore
        .collection("student_marks")
        .where("studentId", isEqualTo: uid)
        .where("semester", isEqualTo: semester)
        .where("released", isEqualTo: true)
        .get();

    return snapshot.docs;
  }

  Future<Map<String, dynamic>?> getSubject(
      String subjectCode) async {

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
}