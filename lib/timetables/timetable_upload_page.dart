import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TimetableUploadPage extends StatefulWidget {

  final bool isAdmin;

  const TimetableUploadPage({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<TimetableUploadPage> createState() =>
      _TimetableUploadPageState();
}

class _TimetableUploadPageState
    extends State<TimetableUploadPage> {
  //-----------------------------------------
  // Firebase & Supabase
  //-----------------------------------------

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final FirebaseAuth auth = FirebaseAuth.instance;

  final SupabaseClient supabase = Supabase.instance.client;

  //-----------------------------------------
  // Teacher Details
  //-----------------------------------------

  String teacherName = "";

  String teacherId = "";

  String teacherDepartment = "";

  //-----------------------------------------
  // Selected File
  //-----------------------------------------

  File? selectedPdf;

  //-----------------------------------------
  // Dropdown Values
  //-----------------------------------------

  String selectedYear = "1st";

  String selectedDepartment = "CSE";

  String selectedSection = "A";

  //-----------------------------------------
  // Current Timetable
  //-----------------------------------------

  Map<String, dynamic>? currentTimetable;

  String? currentDocId;

  //-----------------------------------------
  // Loading States
  //-----------------------------------------

  bool isLoadingTeacher = true;

  bool isSearching = false;

  bool isUploading = false;

  //-----------------------------------------
  // Dropdown Lists
  //-----------------------------------------

  final List<String> years = [
    "1st",
    "2nd",
    "3rd",
    "4th",
  ];

  final List<String> departments = [
    "CSE",
    "AIML",
    "CSM",
    "ECE",
    "EEE",
  ];

  final List<String> sections = [
    "A",
    "B",
    "C",
    "D",
  ];

  //-----------------------------------------
  // Init
  //-----------------------------------------

  @override
  void initState() {
    super.initState();

    loadTeacherDetails();
  }

  //-----------------------------------------
  // Helpers
  //-----------------------------------------

  String get documentId =>
      "${selectedYear}_${selectedDepartment}_${selectedSection}";

  String get storagePath =>
      "$selectedYear/$selectedDepartment/$selectedSection/timetable.pdf";

  //-----------------------------------------
  // SnackBar
  //-----------------------------------------

  void showMessage(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? Colors.red
            : const Color(0xFF1565C0),
      ),
    );
  }

  //-----------------------------------------
  // Load Teacher
  //-----------------------------------------

  Future<void> loadTeacherDetails() async {
    try {
      final user = auth.currentUser;

      if (user == null) {
        if (mounted) {
          setState(() {
            isLoadingTeacher = false;
          });
        }
        return;
      }

      teacherId = user.uid;

      final collection = widget.isAdmin
          ? "admins"
          : "teachers";

      final query = await firestore
          .collection(collection)
          .where(
        "email",
        isEqualTo: user.email,
      )
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();

        teacherName =

            data["name"] ??

                (widget.isAdmin
                    ? "Admin"
                    : "Teacher");
        teacherDepartment =

        widget.isAdmin

            ? "Administrator"

            : data["department"] ?? "";
      } else {
        showMessage(
          widget.isAdmin
              ? "Admin profile not found"
              : "Teacher profile not found",
          error: true,
        );
      }

      if (mounted) {
        setState(() {
          isLoadingTeacher = false;
        });
        await searchTimetable();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingTeacher = false;
        });
      }

      showMessage(
        e.toString(),
        error: true,
      );
    }
  }

  //-----------------------------------------
  // Pick PDF
  //-----------------------------------------

  Future<void> pickPDF() async {
    final result =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: [
        "pdf",
      ],
    );

    if (result == null) return;

    if (result.files.first.size >
        20 * 1024 * 1024) {
      showMessage(
        "Maximum PDF size is 20 MB",
        error: true,
      );

      return;
    }

    setState(() {
      selectedPdf = File(
        result.files.first.path!,
      );
    });
  }

  //-----------------------------------------
  // View PDF
  //-----------------------------------------

  Future<void> openPDF(
      String url,
      ) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode:
        LaunchMode.externalApplication,
      );
    } else {
      showMessage(
        "Unable to open PDF",
        error: true,
      );
    }
  }
  //-----------------------------------------
  // Search Timetable
  //-----------------------------------------

  Future<void> searchTimetable() async {
    setState(() {
      isSearching = true;
    });

    try {
      final doc = await firestore
          .collection("timetables")
          .doc(documentId)
          .get();

      if (doc.exists) {
        setState(() {
          currentTimetable =
          doc.data() as Map<String, dynamic>;
          currentDocId = doc.id;
        });
      } else {
        setState(() {
          currentTimetable = null;
          currentDocId = null;
        });

        showMessage(
          "No timetable found.",
          error: true,
        );
      }
    } catch (e) {
      showMessage(
        e.toString(),
        error: true,
      );
    }

    if (mounted) {
      setState(() {
        isSearching = false;
      });
    }
  }

  //-----------------------------------------
  // Upload / Replace
  //-----------------------------------------

  Future<void> uploadTimetable() async {
    if (selectedPdf == null) {
      showMessage(
        "Please choose a PDF",
        error: true,
      );
      return;
    }

    if (teacherName.isEmpty) {
      showMessage(
        "Teacher details not loaded",
        error: true,
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final existing = await firestore
          .collection("timetables")
          .doc(documentId)
          .get();

      if (existing.exists) {
        final replace = await showDialog<bool>(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text(
                "Replace Timetable?",
              ),
              content: const Text(
                "A timetable already exists.\nReplace it?",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      false,
                    );
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      true,
                    );
                  },
                  child: const Text(
                    "Replace",
                  ),
                ),
              ],
            );
          },
        );

        if (replace != true) {
          if (mounted) {
            setState(() {
              isUploading = false;
            });
          }
          return;
        }

        final data =
        existing.data() as Map<String, dynamic>;

        final oldPath =
            data["filePath"] ?? "";

        if (oldPath.isNotEmpty) {
          try {
            await supabase.storage
                .from("timetables")
                .remove([oldPath]);
          } catch (_) {}
        }
      }

      await supabase.storage
          .from("timetables")
          .upload(
        storagePath,
        selectedPdf!,
        fileOptions:
        const FileOptions(
          upsert: true,
        ),
      );

      final url = supabase.storage
          .from("timetables")
          .getPublicUrl(storagePath);

      await firestore
          .collection("timetables")
          .doc(documentId)
          .set({
        "title":
        "Timetable - $selectedYear Year | $selectedDepartment | Section $selectedSection",

        "teacher": teacherName,

        "teacherId": teacherId,

        "department":
        selectedDepartment,

        "year": selectedYear,

        "section":
        selectedSection,

        "fileUrl": url,

        "filePath":
        storagePath,

        "fileName": selectedPdf!.path.split('/').last,

        "uploadedAt":
        FieldValue.serverTimestamp(),
      });

      setState(() {
        selectedPdf = null;
        isUploading = false;
      });

      await searchTimetable();

      showMessage(
        "Timetable Uploaded Successfully",
      );
    } catch (e) {
      showMessage(
        e.toString(),
        error: true,
      );
    }

    if (mounted) {
      setState(() {
        isUploading = false;
      });
    }
  }

  //-----------------------------------------
  // Delete Timetable
  //-----------------------------------------

  Future<void> deleteTimetable() async {
    if (currentTimetable == null) return;

    final confirm =
    await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "Delete Timetable",
          ),
          content: const Text(
            "This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                "Cancel",
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                "Delete",
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      isUploading = true;
    });

    try {
      final path =
      currentTimetable!["filePath"];

      if (path != null &&
          path.toString().isNotEmpty) {
        await supabase.storage
            .from("timetables")
            .remove([path]);
      }

      await firestore
          .collection("timetables")
          .doc(currentDocId)
          .delete();

      if (mounted) {
        setState(() {
          currentTimetable = null;
          currentDocId = null;
        });
      }

      showMessage(
        "Deleted Successfully",
      );
    } catch (e) {
      showMessage(
        e.toString(),
        error: true,
      );
    }

    if (mounted) {
      setState(() {
        isUploading = false;
      });
    }
  }

  //-----------------------------------------
  // Replace Current Timetable
  //-----------------------------------------

  Future<void> replaceCurrent() async {
    if (currentTimetable == null) return;

    selectedYear = currentTimetable!["year"] as String;
    selectedDepartment = currentTimetable!["department"] as String;
    selectedSection = currentTimetable!["section"] as String;

    await pickPDF();

    if (selectedPdf != null) {
      await uploadTimetable();
    }
  }

  //-----------------------------------------
  // Build
  //-----------------------------------------

@override
Widget build(BuildContext context) {
  final bool isDark =
      Theme.of(context).brightness == Brightness.dark;
return Scaffold(
  backgroundColor: isDark
      ? const Color(0xFF081120)
      : const Color(0xFFF6F8FC),

appBar: AppBar(
elevation: 0,
  backgroundColor: isDark
      ? const Color(0xFF0D47A1)
      : const Color(0xFF1565C0),
foregroundColor: Colors.white,
centerTitle: true,
  title: Text(
    widget.isAdmin
        ? "Admin Timetable Management"
        : "Teacher Timetable Management",
  ),
),

body: isLoadingTeacher
? const Center(
child: CircularProgressIndicator(),
)
: SingleChildScrollView(
padding: const EdgeInsets.all(20),

child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,

children: [

// Upload Card
//----------------------------------

  glassCard(
    isDark: isDark,

    child: Padding(

      padding:
      const EdgeInsets.all(20),

      child: Column(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(
            "Upload Timetable",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 20),

          DropdownButtonFormField<String>(

            value: selectedYear,

            decoration:
            InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF16263D)
                  : Colors.white,
              labelStyle: TextStyle(
                color: isDark
                    ? Colors.white70
                    : Colors.black87,
              ),
              labelText: "Year",
              border:
              OutlineInputBorder(),
            ),

            items: years
                .map(
                  (e) =>
                  DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
            )
                .toList(),

            onChanged: (value) {

              setState(() {
                selectedYear = value!;
                currentTimetable = null;
                currentDocId = null;
              });

              searchTimetable();
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(

            value:
            selectedDepartment,

            decoration:
            InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF16263D)
                  : Colors.white,
              labelStyle: TextStyle(
                color: isDark
                    ? Colors.white70
                    : Colors.black87,
              ),
              labelText:
              "Department",
              border:
              OutlineInputBorder(),
            ),

            items: departments
                .map(
                  (e) =>
                  DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
            )
                .toList(),

            onChanged: (value) {

              setState(() {
                selectedDepartment = value!;
                currentTimetable = null;
                currentDocId = null;
              });
              searchTimetable();
            },
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<String>(

            value:
            selectedSection,

            decoration:
            InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF16263D)
                  : Colors.white,
              labelStyle: TextStyle(
                color: isDark
                    ? Colors.white70
                    : Colors.black87,
              ),
              labelText:
              "Section",
              border:
              OutlineInputBorder(),
            ),

            items: sections
                .map(
                  (e) =>
                  DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ),
            )
                .toList(),

            onChanged: (value) {

              setState(() {
                selectedSection = value!;
                currentTimetable = null;
                currentDocId = null;
              });
              searchTimetable();
            },
          ),

          const SizedBox(height: 20),

          SizedBox(

            width: double.infinity,

            child: OutlinedButton.icon(

              onPressed: pickPDF,

              icon: const Icon(
                Icons.picture_as_pdf,
              ),

              label: Text(

                selectedPdf == null

                    ? "Choose PDF"

                    : selectedPdf!.path
                    .split("/")
                    .last,
              ),
            ),
          ),

          if (selectedPdf != null) ...[

            const SizedBox(height: 10),

            Text(

              "File Size : ${(selectedPdf!.lengthSync()/1024/1024).toStringAsFixed(2)} MB",

              style:
              const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],

          const SizedBox(height: 25),

          SizedBox(

            width: double.infinity,

            height: 55,

            child: ElevatedButton.icon(

              onPressed: isUploading
                  ? null
                  : uploadTimetable,

              icon: isUploading

                  ? const SizedBox(

                width: 20,

                height: 20,

                child:
                CircularProgressIndicator(
                  color:
                  Colors.white,
                  strokeWidth: 2,
                ),
              )

                  : const Icon(
                Icons.cloud_upload,
              ),

              label: Text(

                currentTimetable ==
                    null

                    ? "Upload Timetable"

                    : "Replace Timetable",
              ),

              style:
              ElevatedButton.styleFrom(

                  backgroundColor: const Color(0xFF1565C0),

                foregroundColor:
                Colors.white,

                shape:
                RoundedRectangleBorder(

                  borderRadius:
                  BorderRadius.circular(
                      15),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  ),

//----------------------------------
// Current Timetable Card
//----------------------------------

if (currentTimetable != null)

glassCard(
  isDark: isDark,

child: Padding(

padding:
const EdgeInsets.all(20),

child: Column(

crossAxisAlignment:
CrossAxisAlignment.start,

children: [

Row(

children: [

const Icon(
Icons.picture_as_pdf,
size: 45,
color: Colors.red,
),

const SizedBox(width: 15),

Expanded(

child: Column(

crossAxisAlignment:
CrossAxisAlignment
.start,

children: [

  Text(
    currentTimetable!["title"] ?? "Timetable",
    style: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : Colors.black,
    ),
  ),

const SizedBox(
height: 6),

  Text(
    "Teacher : ${currentTimetable!["teacher"]}",
    style: TextStyle(
      color: isDark ? Colors.white70 : Colors.black87,
    ),
  ),

  Text(
    "Year : ${currentTimetable!["year"]}",
    style: TextStyle(
      color: isDark ? Colors.white70 : Colors.black87,
    ),
  ),

  Text(
    "Department : ${currentTimetable!["department"]}",
    style: TextStyle(
      color: isDark ? Colors.white70 : Colors.black87,
    ),
  ),

  Text(
    "Section : ${currentTimetable!["section"]}",
    style: TextStyle(
      color: isDark ? Colors.white70 : Colors.black87,
    ),
  ),
],
),
),
],
),

const SizedBox(height: 20),

Builder(
builder: (_) {

final uploaded =
currentTimetable![
"uploadedAt"];

return Text(
  uploaded is Timestamp
      ? "Uploaded : ${uploaded.toDate().toLocal().toString().substring(0,16)}"
      : "Uploaded : Just Now",
  style: TextStyle(
    color: isDark ? Colors.white70 : Colors.black87,
  ),
);
},
),

const SizedBox(height: 25),

Row(

children: [

Expanded(

child:
ElevatedButton.icon(

onPressed: () {

openPDF(

currentTimetable![
"fileUrl"],
);
},

icon:
const Icon(
Icons.visibility,
),

label:
const Text(
"View",
),

style:
ElevatedButton
.styleFrom(

  backgroundColor: const Color(0xFF1976D2),

foregroundColor:
Colors.white,
),
),
),

const SizedBox(width: 12),

Expanded(

child:
ElevatedButton.icon(

  onPressed:
  isUploading ? null : replaceCurrent,

icon:
const Icon(
Icons.edit,
),

label:
const Text(
"Replace",
),

style:
ElevatedButton
.styleFrom(

backgroundColor:
Colors.orange,

foregroundColor:
Colors.white,
),
),
),

const SizedBox(width: 12),

Expanded(

child:
ElevatedButton.icon(

  onPressed:
  isUploading ? null : deleteTimetable,

icon:
const Icon(
Icons.delete,
),

label:
const Text(
"Delete",
),

style:
ElevatedButton
.styleFrom(

backgroundColor:
Colors.red,

foregroundColor:
Colors.white,
),
),
),
],
),
],
),
),
),

const SizedBox(height: 30),
],
),
),
);
}

  //-----------------------------------------
  // Glass Card Widget
  //-----------------------------------------

  Widget glassCard({
    required Widget child,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),

      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 8,
          sigmaY: 8,
        ),

        child: Container(
          width: double.infinity,

          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.88),

            borderRadius:
            BorderRadius.circular(24),

            border: Border.all(
              color: isDark
                  ? Colors.white24
                  : Colors.grey.shade300,
            ),

            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.30)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: child,
        ),
      ),
    );
  }
}

//----------------------------------


