import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collection = "subjects";

  /// Add Subject
  Future<void> addSubject({
    required String subjectCode,
    required String subjectName,
    required String department,
    required String year,
    required int semester,
    required int credits,
    required String type,
    required String regulation,
  }) async {
    await _firestore.collection(collection).doc(subjectCode).set({
      "subjectCode": subjectCode,
      "subjectName": subjectName,
      "department": department,
      "year": year,
      "semester": semester,
      "credits": credits,
      "type": type,
      "regulation": regulation,
      "isActive": true,
    });
  }

  /// Get Subjects
  Stream<QuerySnapshot> getSubjects() {
    return _firestore.collection(collection).snapshots();
  }

  /// Delete Subject
  Future<void> deleteSubject(String subjectCode) async {
    await _firestore.collection(collection).doc(subjectCode).delete();
  }

  /// Update Subject
  Future<void> updateSubject(
      String subjectCode,
      Map<String, dynamic> data,
      ) async {
    await _firestore
        .collection(collection)
        .doc(subjectCode)
        .update(data);
  }
}