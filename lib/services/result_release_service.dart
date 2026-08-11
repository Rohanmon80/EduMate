import 'package:cloud_firestore/cloud_firestore.dart';

class ResultReleaseService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // GET PENDING RESULTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getPendingResults() {
    return _firestore
        .collection("student_marks")
        .where("released", isEqualTo: false)
        .snapshots();
  }

  // ============================================================
  // GET RELEASED RESULTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getReleasedResults() {
    return _firestore
        .collection("student_marks")
        .where("released", isEqualTo: true)
        .snapshots();
  }

  // ============================================================
  // GET ALL RESULTS
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> getAllResults() {
    return _firestore
        .collection("student_marks")
        .snapshots();
  }

  // ============================================================
  // RELEASE ONE MARK DOCUMENT
  // ============================================================

  Future<void> releaseResult(String docId) async {
    await _firestore
        .collection("student_marks")
        .doc(docId)
        .update({
      "released": true,
      "releasedAt":
      FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // UNRELEASE ONE MARK DOCUMENT
  // ============================================================

  Future<void> unReleaseResult(String docId) async {
    await _firestore
        .collection("student_marks")
        .doc(docId)
        .update({
      "released": false,
      "releasedAt": null,
    });
  }

  // ============================================================
  // GET MISSING ENTRIES FOR ONE SUBJECT + EXAM
  // ============================================================

  Future<int> getMissingEntries({
    required String department,
    required String year,
    required int semester,
    required String section,
    required String subjectCode,
    required String exam,
  }) async {
    final studentsSnapshot = await _firestore
        .collection("users")
        .where(
      "role",
      isEqualTo: "student",
    )
        .where(
      "department",
      isEqualTo: department,
    )
        .where(
      "year",
      isEqualTo: year,
    )
        .where(
      "semester",
      isEqualTo: semester,
    )
        .where(
      "section",
      isEqualTo: section,
    )
        .get();

    final uploadedSnapshot = await _firestore
        .collection("student_marks")
        .where(
      "subjectCode",
      isEqualTo: subjectCode,
    )
        .where(
      "exam",
      isEqualTo: exam,
    )
        .where(
      "department",
      isEqualTo: department,
    )
        .where(
      "year",
      isEqualTo: year,
    )
        .where(
      "semester",
      isEqualTo: semester,
    )
        .where(
      "section",
      isEqualTo: section,
    )
        .get();

    // Unique student IDs having marks.
    final uploadedStudentIds =
    <String>{};

    for (final doc
    in uploadedSnapshot.docs) {
      final studentId =
      doc.data()["studentId"]?.toString();

      if (studentId != null &&
          studentId.isNotEmpty) {
        uploadedStudentIds.add(studentId);
      }
    }

    final totalStudents =
        studentsSnapshot.docs.length;

    final uploadedStudents =
    uploadedStudentIds.length >
        totalStudents
        ? totalStudents
        : uploadedStudentIds.length;

    final missing =
        totalStudents - uploadedStudents;

    return missing < 0 ? 0 : missing;
  }

  // ============================================================
  // GET TOTAL MISSING ENTRIES FOR CLASS
  // ============================================================

  Future<int> getTotalMissingEntries({
    required String department,
    required String year,
    required int semester,
    required String section,
  }) async {
    final studentsSnapshot = await _firestore
        .collection("users")
        .where(
      "role",
      isEqualTo: "student",
    )
        .where(
      "department",
      isEqualTo: department,
    )
        .where(
      "year",
      isEqualTo: year,
    )
        .where(
      "semester",
      isEqualTo: semester,
    )
        .where(
      "section",
      isEqualTo: section,
    )
        .get();

    final students =
        studentsSnapshot.docs;

    if (students.isEmpty) {
      return 0;
    }

    final subjectsSnapshot = await _firestore
        .collection("subjects")
        .where(
      "department",
      isEqualTo: department,
    )
        .where(
      "year",
      isEqualTo: year,
    )
        .where(
      "semester",
      isEqualTo: semester,
    )
        .where(
      "isActive",
      isEqualTo: true,
    )
        .get();

    final subjects =
        subjectsSnapshot.docs;

    if (subjects.isEmpty) {
      return 0;
    }

    final marksSnapshot = await _firestore
        .collection("student_marks")
        .where(
      "department",
      isEqualTo: department,
    )
        .where(
      "year",
      isEqualTo: year,
    )
        .where(
      "semester",
      isEqualTo: semester,
    )
        .where(
      "section",
      isEqualTo: section,
    )
        .get();

    final uploaded = <String>{};

    for (final doc
    in marksSnapshot.docs) {
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

    int totalMissing = 0;

    for (final student
    in students) {
      final studentId =
          student.id;

      for (final subject
      in subjects) {
        final data =
        subject.data();

        final subjectCode =
        data["subjectCode"]?.toString();

        if (subjectCode == null ||
            subjectCode.isEmpty) {
          continue;
        }

        final subjectType =
            data["type"]
                ?.toString()
                .toLowerCase() ??
                "theory";

        final bool isLab =
        subjectType.contains("lab");

        final exams = isLab
            ? const [
          "Lab Internal 1",
          "Lab Internal 2",
          "Lab External",
        ]
            : const [
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

  // ============================================================
  // GET ALL EXPECTED RELEASE GROUPS
  //
  // This is important:
  // It creates groups even when ZERO marks have been uploaded.
  // ============================================================

  Future<List<Map<String, dynamic>>> getReleaseGroups({
    String? department,
    String? year,
    String? section,
    int? semester,
    String? exam,
  }) async {
    // ----------------------------------------------------------
    // 1. Get students
    // ----------------------------------------------------------

    Query<Map<String, dynamic>> studentsQuery =
    _firestore
        .collection("users")
        .where(
      "role",
      isEqualTo: "student",
    );

    if (department != null) {
      studentsQuery = studentsQuery.where(
        "department",
        isEqualTo: department,
      );
    }

    if (year != null) {
      studentsQuery = studentsQuery.where(
        "year",
        isEqualTo: year,
      );
    }

    if (section != null) {
      studentsQuery = studentsQuery.where(
        "section",
        isEqualTo: section,
      );
    }

    if (semester != null) {
      studentsQuery = studentsQuery.where(
        "semester",
        isEqualTo: semester,
      );
    }

    final studentsSnapshot =
    await studentsQuery.get();

    final students =
        studentsSnapshot.docs;

    if (students.isEmpty) {
      return [];
    }

    // ----------------------------------------------------------
    // 2. Get active subjects
    // ----------------------------------------------------------

    Query<Map<String, dynamic>> subjectsQuery =
    _firestore
        .collection("subjects")
        .where(
      "isActive",
      isEqualTo: true,
    );

    if (department != null) {
      subjectsQuery = subjectsQuery.where(
        "department",
        isEqualTo: department,
      );
    }

    if (year != null) {
      subjectsQuery = subjectsQuery.where(
        "year",
        isEqualTo: year,
      );
    }

    if (semester != null) {
      subjectsQuery = subjectsQuery.where(
        "semester",
        isEqualTo: semester,
      );
    }

    final subjectsSnapshot =
    await subjectsQuery.get();

    final subjects =
        subjectsSnapshot.docs;

    if (subjects.isEmpty) {
      return [];
    }

    // ----------------------------------------------------------
    // 3. Get uploaded marks
    // ----------------------------------------------------------

    final marksSnapshot =
    await _firestore
        .collection("student_marks")
        .get();

    // ----------------------------------------------------------
    // 4. Group uploaded marks
    // ----------------------------------------------------------

    final Map<
        String,
        List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    uploadedGroups = {};

    for (final doc
    in marksSnapshot.docs) {
      final data = doc.data();

      final docDepartment =
          data["department"]?.toString() ?? "";

      final docYear =
          data["year"]?.toString() ?? "";

      final docSection =
          data["section"]?.toString() ?? "";

      final docSemester =
      (data["semester"] as num?)?.toInt();

      final docSubject =
          data["subjectCode"]?.toString() ?? "";

      final docExam =
          data["exam"]?.toString() ?? "";

      if (docDepartment.isEmpty ||
          docYear.isEmpty ||
          docSection.isEmpty ||
          docSemester == null ||
          docSubject.isEmpty ||
          docExam.isEmpty) {
        continue;
      }

      final key =
          "$docDepartment|"
          "$docYear|"
          "$docSemester|"
          "$docSection|"
          "$docSubject|"
          "$docExam";

      uploadedGroups
          .putIfAbsent(
        key,
            () => [],
      )
          .add(doc);
    }

    // ----------------------------------------------------------
    // 5. Build expected groups
    // ----------------------------------------------------------

    final List<Map<String, dynamic>>
    groups = [];

    final Set<String> addedGroups =
    <String>{};

    // ----------------------------------------------------------
    // IMPORTANT
    //
    // Build class combinations first.
    // This avoids creating duplicate cards for every student.
    // ----------------------------------------------------------

    final Map<String, List<QueryDocumentSnapshot<
        Map<String, dynamic>>>>
    studentsByClass = {};

    for (final student in students) {
      final data =
      student.data();

      final studentDepartment =
          data["department"]?.toString() ?? "";

      final studentYear =
          data["year"]?.toString() ?? "";

      final studentSection =
          data["section"]?.toString() ?? "";

      final studentSemester =
      (data["semester"] as num?)?.toInt();

      if (studentDepartment.isEmpty ||
          studentYear.isEmpty ||
          studentSection.isEmpty ||
          studentSemester == null) {
        continue;
      }

      final classKey =
          "$studentDepartment|"
          "$studentYear|"
          "$studentSemester|"
          "$studentSection";

      studentsByClass
          .putIfAbsent(
        classKey,
            () => [],
      )
          .add(student);
    }

    // ----------------------------------------------------------
    // 6. Create subject/exam group for every class
    // ----------------------------------------------------------

    for (final classEntry
    in studentsByClass.entries) {
      final classStudents =
          classEntry.value;

      final firstStudent =
      classStudents.first.data();

      final classDepartment =
          firstStudent["department"]
              ?.toString() ??
              "";

      final classYear =
          firstStudent["year"]
              ?.toString() ??
              "";

      final classSection =
          firstStudent["section"]
              ?.toString() ??
              "";

      final classSemester =
      (firstStudent["semester"]
      as num?)
          ?.toInt();

      if (classSemester == null) {
        continue;
      }

      for (final subject
      in subjects) {
        final subjectData =
        subject.data();

        final subjectDepartment =
            subjectData["department"]
                ?.toString() ??
                "";

        final subjectYear =
            subjectData["year"]
                ?.toString() ??
                "";

        final subjectSemester =
        (subjectData["semester"]
        as num?)
            ?.toInt();

        final subjectCode =
            subjectData["subjectCode"]
                ?.toString() ??
                "";

        final subjectName =
            subjectData["subjectName"]
                ?.toString() ??
                "";

        final subjectType =
            subjectData["type"]
                ?.toString() ??
                "Theory";

        // Make sure subject belongs to this class.
        if (subjectDepartment !=
            classDepartment ||
            subjectYear != classYear ||
            subjectSemester !=
                classSemester ||
            subjectCode.isEmpty) {
          continue;
        }

        final bool isLab =
        subjectType
            .toLowerCase()
            .contains("lab");

        final List<String> exams =
        isLab
            ? const [
          "Lab Internal 1",
          "Lab Internal 2",
          "Lab External",
        ]
            : const [
          "Mid 1",
          "Mid 2",
          "Sem External",
        ];

        for (final examName in exams) {
          if (exam != null &&
              examName != exam) {
            continue;
          }

          final key =
              "$classDepartment|"
              "$classYear|"
              "$classSemester|"
              "$classSection|"
              "$subjectCode|"
              "$examName";

          if (addedGroups.contains(key)) {
            continue;
          }

          addedGroups.add(key);

          // Uploaded documents for this exact group.
          final uploadedDocs =
              uploadedGroups[key] ??
                  <
                      QueryDocumentSnapshot<
                          Map<String, dynamic>>>[];

          // ----------------------------------------------------
          // Count only students belonging to this class.
          // ----------------------------------------------------

          final classStudentIds =
          classStudents
              .map(
                (student) =>
            student.id,
          )
              .toSet();

          final uploadedStudentIds =
          uploadedDocs
              .map(
                (doc) =>
                doc.data()["studentId"]
                    ?.toString(),
          )
              .where(
                (id) =>
            id != null &&
                id.isNotEmpty &&
                classStudentIds
                    .contains(id),
          )
              .cast<String>()
              .toSet();

          final totalStudents =
              classStudentIds.length;

          final uploaded =
              uploadedStudentIds.length;

          final missing =
              totalStudents - uploaded;

          // ----------------------------------------------------
          // A group is released only if:
          // 1. It has uploaded marks
          // 2. ALL uploaded documents are released
          // ----------------------------------------------------

          final bool allReleased =
              uploadedDocs.isNotEmpty &&
                  uploadedDocs.every(
                        (doc) =>
                    doc.data()["released"] ==
                        true,
                  );

          groups.add({
            "department":
            classDepartment,

            "year":
            classYear,

            "semester":
            classSemester,

            "section":
            classSection,

            "subjectCode":
            subjectCode,

            "subjectName":
            subjectName,

            "type":
            subjectType,

            "exam":
            examName,

            "documents":
            uploadedDocs,

            "uploaded":
            uploaded,

            "totalStudents":
            totalStudents,

            "missing":
            missing < 0
                ? 0
                : missing,

            "released":
            allReleased,
          });
        }
      }
    }

    // ----------------------------------------------------------
    // 7. Sort groups
    // ----------------------------------------------------------

    groups.sort(
          (a, b) {
        final subjectA =
            a["subjectName"]
                ?.toString() ??
                "";

        final subjectB =
            b["subjectName"]
                ?.toString() ??
                "";

        final subjectCompare =
        subjectA.compareTo(subjectB);

        if (subjectCompare != 0) {
          return subjectCompare;
        }

        final examA =
            a["exam"]
                ?.toString() ??
                "";

        final examB =
            b["exam"]
                ?.toString() ??
                "";

        return examA.compareTo(examB);
      },
    );

    return groups;
  }
}