import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/memo_header.dart';
import '../widgets/memo_student_details.dart';
import '../widgets/memo_subject_table.dart';
import '../widgets/memo_summary_card.dart';

class MemoService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

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

    final doc = await firestore
        .collection("subjects")
        .doc(subjectCode)
        .get();

    if (!doc.exists) return null;

    return doc.data();
  }
}