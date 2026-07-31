import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:url_launcher/url_launcher.dart';

class TimetableService {
//---------------------------------------------
// Firebase
//---------------------------------------------

final FirebaseFirestore firestore =
FirebaseFirestore.instance;

final FirebaseAuth auth =
FirebaseAuth.instance;

final SupabaseClient supabase =
Supabase.instance.client;

//---------------------------------------------
// Current User
//---------------------------------------------

User? get currentUser =>
auth.currentUser;

//---------------------------------------------
// Document Id
//---------------------------------------------

String documentId({
required String year,
required String department,
required String section,
}) {
return "${year}_${department}_${section}";
}

//---------------------------------------------
// Storage Path
//---------------------------------------------

String storagePath({
required String year,
required String department,
required String section,
}) {
return "$year/$department/$section/timetable.pdf";
}

//---------------------------------------------
// Pick PDF
//---------------------------------------------

Future<File?> pickPDF() async {
final result =
await FilePicker.platform.pickFiles(
type: FileType.custom,
allowMultiple: false,
allowedExtensions: [
"pdf",
],
);

if (result == null) {
return null;
}

if (result.files.first.size >
20 * 1024 * 1024) {
throw Exception(
"Maximum PDF size is 20 MB",
);
}

return File(
result.files.first.path!,
);
}

//---------------------------------------------
// Open PDF
//---------------------------------------------

Future<void> openPDF(
String url,
) async {
final uri = Uri.parse(url);

if (!await canLaunchUrl(uri)) {
throw Exception(
"Unable to open PDF",
);
}

await launchUrl(
uri,
mode:
LaunchMode.externalApplication,
);
}
//---------------------------------------------
// Get Teacher / Admin Details
//---------------------------------------------

  Future<Map<String, dynamic>> getUserDetails({
    bool isAdmin = false,
  }) async {

    final user = currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final collection =
    isAdmin ? "admins" : "teachers";

    final query = await firestore
        .collection(collection)
        .where(
      "email",
      isEqualTo: user.email,
    )
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception(
        isAdmin
            ? "Admin profile not found"
            : "Teacher profile not found",
      );
    }

    final data = query.docs.first.data();

    return {
      "name": data["name"] ??
          (isAdmin ? "Admin" : "Teacher"),

      "id": user.uid,

      "department": isAdmin
          ? "Administrator"
          : (data["department"] ?? ""),

      "email": data["email"] ?? "",

      "phone": data["phone"] ?? "",

      "role": isAdmin
          ? "Admin"
          : "Teacher",
    };
  }

//---------------------------------------------
// Check Existing Timetable
//---------------------------------------------

Future<DocumentSnapshot<Map<String, dynamic>>>
getExistingTimetable({
required String year,
required String department,
required String section,
}) async {
return firestore
.collection("timetables")
.doc(
documentId(
year: year,
department: department,
section: section,
),
)
.get();
}

//---------------------------------------------
// Get Timetable
//---------------------------------------------

  Future<Map<String, dynamic>?> getTimetable({
    required String year,
    required String department,
    required String section,
  }) async {

    final id =
        "${year}_${department}_${section}";

    debugPrint("Searching timetable: $id");

    final doc = await firestore
        .collection("timetables")
        .doc(id)
        .get();

    debugPrint("Exists: ${doc.exists}");

    if (!doc.exists) {
      return null;
    }

    debugPrint(doc.data().toString());

    return doc.data();
  }

//---------------------------------------------
// Timetable Exists?
//---------------------------------------------

Future<bool> timetableExists({
required String year,
required String department,
required String section,
}) async {
final doc =
await getExistingTimetable(
year: year,
department: department,
section: section,
);

return doc.exists;
}
//---------------------------------------------
// Upload / Replace Timetable
//---------------------------------------------

Future<String> uploadTimetable({
required File pdfFile,
required String year,
required String department,
required String section,
required String teacherName,
required String teacherId,
}) async {

final docId = documentId(
year: year,
department: department,
section: section,
);

final path = storagePath(
year: year,
department: department,
section: section,
);

//-----------------------------------------
// Delete old PDF if exists
//-----------------------------------------

final existing = await firestore
.collection("timetables")
.doc(docId)
.get();

if (existing.exists) {

final data = existing.data();

final oldPath =
data?["filePath"] ?? "";

if (oldPath.toString().isNotEmpty) {

try {

await supabase.storage
.from("timetables")
.remove([
oldPath,
]);

} catch (_) {}
}
}

//-----------------------------------------
// Upload new PDF
//-----------------------------------------

await supabase.storage
.from("timetables")
.upload(
path,
pdfFile,

fileOptions:
const FileOptions(
upsert: true,
),
);

//-----------------------------------------
// Public URL
//-----------------------------------------

final fileUrl = supabase.storage
.from("timetables")
.getPublicUrl(path);

//-----------------------------------------
// Save Firestore
//-----------------------------------------

await firestore
.collection("timetables")
.doc(docId)
.set({

"title":
"Timetable - $year Year | $department | Section $section",

"teacher":
teacherName,

"teacherId":
teacherId,

"year":
year,

"department":
department,

"section":
section,

"fileUrl":
fileUrl,

"filePath":
path,

"fileName":
pdfFile.path.split("/").last,

"uploadedAt":
FieldValue.serverTimestamp(),

});

return fileUrl;
}

//---------------------------------------------
// Replace Timetable
//---------------------------------------------

Future<String> replaceTimetable({

required File pdfFile,

required String year,

required String department,

required String section,

required String teacherName,

required String teacherId,

}) async {

return uploadTimetable(

pdfFile: pdfFile,

year: year,

department: department,

section: section,

teacherName: teacherName,

teacherId: teacherId,

);
}
//---------------------------------------------
// Delete Timetable
//---------------------------------------------

Future<void> deleteTimetable({
required String year,
required String department,
required String section,
}) async {

final docId = documentId(
year: year,
department: department,
section: section,
);

final doc = await firestore
.collection("timetables")
.doc(docId)
.get();

if (!doc.exists) {
throw Exception("Timetable not found");
}

final data = doc.data()!;

final filePath =
data["filePath"] ?? "";

//-----------------------------------------
// Delete PDF from Supabase
//-----------------------------------------

if (filePath.toString().isNotEmpty) {

try {

await supabase.storage
.from("timetables")
.remove([
filePath,
]);

} catch (_) {}
}

//-----------------------------------------
// Delete Firestore document
//-----------------------------------------

await firestore
.collection("timetables")
.doc(docId)
.delete();
}

//---------------------------------------------
// Get All Timetables
//---------------------------------------------

Future<List<Map<String, dynamic>>>
getAllTimetables() async {

final snapshot = await firestore
.collection("timetables")
.orderBy(
"uploadedAt",
descending: true,
)
.get();

return snapshot.docs
.map((e) => e.data())
.toList();
}

//---------------------------------------------
// Get Timetables By Department
//---------------------------------------------

Future<List<Map<String, dynamic>>>
getDepartmentTimetables(
String department,
) async {

final snapshot = await firestore
.collection("timetables")
.where(
"department",
isEqualTo: department,
)
.orderBy(
"uploadedAt",
descending: true,
)
.get();

return snapshot.docs
.map((e) => e.data())
.toList();
}

//---------------------------------------------
// Get Timetables By Year
//---------------------------------------------

Future<List<Map<String, dynamic>>>
getYearTimetables(
String year,
) async {

final snapshot = await firestore
.collection("timetables")
.where(
"year",
isEqualTo: year,
)
.orderBy(
"uploadedAt",
descending: true,
)
.get();

return snapshot.docs
.map((e) => e.data())
.toList();
}

//---------------------------------------------
// Get Timetables By Section
//---------------------------------------------

Future<List<Map<String, dynamic>>>
getSectionTimetables({

required String year,

required String department,

required String section,

}) async {

final snapshot = await firestore
.collection("timetables")
.where(
"year",
isEqualTo: year,
)
.where(
"department",
isEqualTo: department,
)
.where(
"section",
isEqualTo: section,
)
.orderBy(
"uploadedAt",
descending: true,
)
.get();

return snapshot.docs
.map((e) => e.data())
.toList();
}
  //---------------------------------------------
  // Get File URL
  //---------------------------------------------

  Future<String?> getFileUrl({
    required String year,
    required String department,
    required String section,
  }) async {

    final data = await getTimetable(
      year: year,
      department: department,
      section: section,
    );

    if (data == null) {
      return null;
    }

    return data["fileUrl"];
  }

  //---------------------------------------------
  // Get File Name
  //---------------------------------------------

  Future<String?> getFileName({
    required String year,
    required String department,
    required String section,
  }) async {

    final data = await getTimetable(
      year: year,
      department: department,
      section: section,
    );

    if (data == null) {
      return null;
    }

    return data["fileName"];
  }

  //---------------------------------------------
  // Get Upload Time
  //---------------------------------------------

  Future<Timestamp?> getUploadTime({
    required String year,
    required String department,
    required String section,
  }) async {

    final data = await getTimetable(
      year: year,
      department: department,
      section: section,
    );

    if (data == null) {
      return null;
    }

    return data["uploadedAt"];
  }

  //---------------------------------------------
  // Check PDF Exists
  //---------------------------------------------

  Future<bool> pdfExists({
    required String year,
    required String department,
    required String section,
  }) async {

    final url = await getFileUrl(
      year: year,
      department: department,
      section: section,
    );

    return url != null &&
        url.toString().isNotEmpty;
  }

  //---------------------------------------------
  // Refresh Timetable
  //---------------------------------------------

  Future<Map<String, dynamic>?> refreshTimetable({
    required String year,
    required String department,
    required String section,
  }) async {

    return await getTimetable(
      year: year,
      department: department,
      section: section,
    );
  }

  //---------------------------------------------
  // Get Timetable Title
  //---------------------------------------------

  String timetableTitle({
    required String year,
    required String department,
    required String section,
  }) {

    return "Timetable - "
        "$year Year | "
        "$department | "
        "Section $section";
  }

//---------------------------------------------
// Close Service Class
//---------------------------------------------
}