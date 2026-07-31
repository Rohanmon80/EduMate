import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TeacherMaterialUploadPage extends StatefulWidget {
  const TeacherMaterialUploadPage({super.key});

  @override
  State<TeacherMaterialUploadPage> createState() =>
      _TeacherMaterialUploadPageState();
}

class _TeacherMaterialUploadPageState
    extends State<TeacherMaterialUploadPage> {

//-----------------------------------------
// Controllers
//-----------------------------------------

final TextEditingController titleController =
TextEditingController();

//-----------------------------------------
// Firebase
//-----------------------------------------

final FirebaseFirestore firestore =
FirebaseFirestore.instance;

final FirebaseAuth auth =
FirebaseAuth.instance;

final SupabaseClient supabase =
Supabase.instance.client;

//-----------------------------------------
// Teacher
//-----------------------------------------

String teacherName = "";

String teacherId = "";

String teacherDepartment = "";

//-----------------------------------------
// Dropdown Data (Dynamic)
//-----------------------------------------

List<String> years = [];

List<String> departments = [];

List<String> sections = [];

//-----------------------------------------
// Selected Values
//-----------------------------------------

String? selectedYear;

String? selectedDepartment;

String? selectedSection;

//-----------------------------------------
// File
//-----------------------------------------

File? selectedFile;

String fileType = "FILE";

String fileSize = "";

//-----------------------------------------
// Loading
//-----------------------------------------

bool isUploading = false;

bool isLoading = true;

//-----------------------------------------
// Init
//-----------------------------------------

@override
void initState() {
super.initState();

initializePage();
}

//-----------------------------------------
// Dispose
//-----------------------------------------

@override
void dispose() {
titleController.dispose();
super.dispose();
}

//-----------------------------------------
// Initialize
//-----------------------------------------

Future<void> initializePage() async {

await loadTeacher();

await loadAcademicData();

if (mounted) {
setState(() {
isLoading = false;
});
}
}
//-----------------------------------------
// Load Teacher Details
//-----------------------------------------

Future<void> loadTeacher() async {

try {
  final user = auth.currentUser;

  if (user == null) {
    throw Exception("Teacher not logged in");
  }

  final doc = await firestore
      .collection("teachers")
      .doc(user.uid)
      .get();

  if (!doc.exists) {
    throw Exception("Teacher profile not found");
  }

  final data = doc.data()!;


  teacherName = data["name"] ?? "Teacher";

  teacherId = user.uid;

  teacherDepartment =
      data["department"] ?? "";


} catch (e) {

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(e.toString()),
),
);
}
}

//-----------------------------------------
// Load Academic Settings
//-----------------------------------------

Future<void> loadAcademicData() async {

try {
  final doc = await firestore
      .collection("settings")
      .doc("academic")
      .get();

  if (!doc.exists) {
    throw Exception(
      "Academic settings not found.",
    );
  }

  final data = doc.data()!;

  years = List<String>.from(
    data["years"] ?? [],
  );

  departments = List<String>.from(
    data["departments"] ?? [],
  );

  sections = List<String>.from(
    data["sections"] ?? [],
  );

//---------------------------------------
// Default Selected Values
//---------------------------------------

  if (years.isNotEmpty) {
    selectedYear = years.first;
  }

//---------------------------------------
// Teacher Department
//---------------------------------------

  if (teacherDepartment.isNotEmpty &&
      departments.contains(
        teacherDepartment,
      )) {
    selectedDepartment =
        teacherDepartment;
  } else if (departments.isNotEmpty) {
    selectedDepartment =
        departments.first;
  }

//---------------------------------------
// Section
//---------------------------------------

  if (sections.isNotEmpty) {
    selectedSection =
        sections.first;
  }

} catch (e) {

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(

SnackBar(
content: Text(
e.toString(),
),
),
);
}
}

//-----------------------------------------
// Pick File
//-----------------------------------------

Future<void> pickFile() async {

final result =
await FilePicker.platform.pickFiles(
type: FileType.any,
);

if (result == null) return;

if (result.files.first.size >
50 * 1024 * 1024) {

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(

const SnackBar(
content: Text(
"Maximum file size is 50 MB",
),
),
);

return;
}

setState(() {

selectedFile = File(
result.files.first.path!,
);

fileType =
result.files.first.extension
?.toUpperCase() ??
"FILE";

fileSize =
"${(result.files.first.size / 1024 / 1024).toStringAsFixed(2)} MB";
});
}

//-----------------------------------------
// Remove File
//-----------------------------------------

void removeFile() {

setState(() {

selectedFile = null;

fileType = "FILE";

fileSize = "";
});
}
//-----------------------------------------
// Upload Material
//-----------------------------------------

Future<void> uploadMaterial() async {
  if (titleController.text
      .trim()
      .isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please enter material title",
        ),
      ),
    );

    return;
  }

  if (selectedFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please choose a file",
        ),
      ),
    );

    return;
  }

  if (selectedYear == null ||
      selectedDepartment == null ||
      selectedSection == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please select Year, Department and Section",
        ),
      ),
    );

    return;
  }

  if (isUploading) return;

  setState(() {
    isUploading = true;
  });
  try {
//-----------------------------------
// Upload to Supabase
//-----------------------------------

    final storagePath =
        "$teacherId/${DateTime
        .now()
        .millisecondsSinceEpoch}_${selectedFile!
        .path
        .split('/')
        .last}";

    final bytes = await selectedFile!.readAsBytes();
    debugPrint("Firebase User: ${auth.currentUser?.uid}");
    debugPrint("Supabase User: ${supabase.auth.currentUser?.id}");

    await supabase.storage
        .from("study-materials")
        .uploadBinary(
      storagePath,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    )
        .timeout(
      const Duration(seconds: 60),
    );

    final fileUrl = supabase.storage
        .from("study-materials")
        .getPublicUrl(storagePath);

//-----------------------------------
// Save Firestore
//-----------------------------------

    await firestore.collection("study_materials").add({

      "title": titleController.text.trim(),

      "teacher": teacherName,

      "teacherId": teacherId,

      "department": selectedDepartment,
      "departmentLower":
      selectedDepartment!.toLowerCase(),

      "year": selectedYear,

      "section": selectedSection,

      "fileUrl": fileUrl,

      "fileName": selectedFile!
          .path
          .split("/")
          .last,
      "extension": selectedFile!
          .path
          .split(".")
          .last
          .toLowerCase(),

      "fileType": fileType,

      "fileSize": fileSize,

      "uploadedAt": FieldValue.serverTimestamp(),
      "uploadedBy": teacherName,
      "teacherUid": teacherId,
    });

    if (!mounted) return;

    showSuccess("Material Uploaded Successfully");

  } catch (e, stackTrace) {

    debugPrint(e.toString());
    debugPrint(stackTrace.toString());

    showError(e.toString());

  } finally {

    if (mounted) {
      setState(() {
        isUploading = false;
      });
    }
  }
}
//-----------------------------------------
// Build UI
//-----------------------------------------

@override
Widget build(BuildContext context) {

return Scaffold(

appBar: AppBar(
title: const Text("Upload Materials"),
centerTitle: true,
),

body: isLoading

? const Center(
child: CircularProgressIndicator(),
)

: Stack(

children: [

AbsorbPointer(

absorbing: isUploading,

child: SingleChildScrollView(

padding: const EdgeInsets.all(20),

child: Column(

crossAxisAlignment:
CrossAxisAlignment.start,

children: [

//--------------------------------
// Teacher Card
//--------------------------------

Card(

elevation: 3,

shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(18),
),

child: Padding(

padding:
const EdgeInsets.all(18),

child: Row(

children: [

const CircleAvatar(
radius: 28,
child: Icon(
Icons.person,
size: 30,
),
),

const SizedBox(width: 16),

Expanded(

child: Column(

crossAxisAlignment:
CrossAxisAlignment.start,

children: [

Text(
teacherName,
style: const TextStyle(
fontSize: 20,
fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 4),

Text(teacherDepartment),
],
),
),
],
),
),
),

const SizedBox(height: 25),

//--------------------------------
// Material Title
//--------------------------------

TextField(

controller: titleController,

decoration:
const InputDecoration(

labelText:
"Material Title",

border:
OutlineInputBorder(),
),
),

const SizedBox(height: 20),

//--------------------------------
// Choose File
//--------------------------------

SizedBox(

width: double.infinity,

child: ElevatedButton.icon(

onPressed: pickFile,

icon: const Icon(
Icons.upload_file,
),

label: const Text(
"Choose File",
),
),
),

const SizedBox(height: 20),
//--------------------------------
// Selected File
//--------------------------------

if (selectedFile != null)
Card(
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(15),
),
child: ListTile(
leading: Icon(
fileType == "PDF"
? Icons.picture_as_pdf
: fileType == "PPT" ||
fileType == "PPTX"
? Icons.slideshow
: fileType == "DOC" ||
fileType == "DOCX"
? Icons.description
: fileType == "PNG" ||
fileType == "JPG" ||
fileType == "JPEG"
? Icons.image
: Icons.insert_drive_file,
color: Colors.blue,
),

title: Text(
selectedFile!.path.split("/").last,
maxLines: 1,
overflow: TextOverflow.ellipsis,
),

subtitle: Text(
"$fileType • $fileSize",
),

trailing: IconButton(
icon: const Icon(
Icons.close,
color: Colors.red,
),
onPressed: removeFile,
),
),
),

const SizedBox(height: 25),

//--------------------------------
// Year
//--------------------------------

DropdownButtonFormField<String>(
value: selectedYear,
decoration: const InputDecoration(
labelText: "Year",
border: OutlineInputBorder(),
),
items: years
.map(
(year) => DropdownMenuItem(
value: year,
child: Text(year),
),
)
.toList(),
onChanged: (value) {
setState(() {
selectedYear = value;
});
},
),

const SizedBox(height: 20),

//--------------------------------
// Department
//--------------------------------

DropdownButtonFormField<String>(
value: selectedDepartment,
decoration: const InputDecoration(
labelText: "Department",
border: OutlineInputBorder(),
),
items: departments
.map(
(department) => DropdownMenuItem(
value: department,
child: Text(department),
),
)
.toList(),
onChanged: (value) {
setState(() {
selectedDepartment = value;
});
},
),

const SizedBox(height: 20),

//--------------------------------
// Section
//--------------------------------

DropdownButtonFormField<String>(
value: selectedSection,
decoration: const InputDecoration(
labelText: "Section",
border: OutlineInputBorder(),
),
items: sections
.map(
(section) => DropdownMenuItem(
value: section,
child: Text(section),
),
)
.toList(),
onChanged: (value) {
setState(() {
selectedSection = value;
});
},
),

const SizedBox(height: 30),

//--------------------------------
// Upload Button
//--------------------------------

SizedBox(
width: double.infinity,
height: 55,
child: ElevatedButton(
  onPressed: isUploading
      ? null
      : () async {
    FocusScope.of(context).unfocus();
    await uploadMaterial();
  },

child: isUploading

? const Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [

SizedBox(
width: 22,
height: 22,
child:
CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
),

SizedBox(width: 15),

Text(
"Uploading...",
style: TextStyle(
color: Colors.white,
),
),
],
)

: const Text(
"Upload Material",
),
),
),

const SizedBox(height: 40),
],
),
),
),

  //--------------------------------
  // Loading Overlay
  //--------------------------------

  if (isUploading)
    Container(
      color: Colors.black38,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    ),
],
),
);
}

//-----------------------------------------
// Success Snackbar
//-----------------------------------------

  void showSuccess(String message) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

//-----------------------------------------
// Error Snackbar
//-----------------------------------------

  void showError(String message) {

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        content: Text(message),
      ),
    );
  }

}
