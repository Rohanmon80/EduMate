import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:dio/dio.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import 'timetable_service.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() =>
      _TimetablePageState();
}

class _TimetablePageState
    extends State<TimetablePage> {
  Future<File> _downloadPdfFile(String url) async {
    if (url.trim().isEmpty) {
      throw Exception("PDF URL is empty");
    }

    final uri = Uri.tryParse(url);

    if (uri == null || !uri.hasScheme) {
      throw Exception("Invalid PDF URL");
    }

    final directory =
    await getApplicationDocumentsDirectory();

    final fileName =
        "EduMate_Timetable_${year}_${department}_${section}.pdf";

    final file = File(
      "${directory.path}/$fileName",
    );

    debugPrint("Downloading timetable:");
    debugPrint(url);
    debugPrint("Saving to:");
    debugPrint(file.path);

    final response = await Dio().get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) {
          return status != null &&
              status >= 200 &&
              status < 400;
        },
      ),
    );

    if (response.data == null || response.data!.isEmpty) {
      throw Exception("Downloaded PDF is empty");
    }

    final bytes = response.data!;

// Check PDF signature: %PDF
    if (bytes.length < 4 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46) {
      throw Exception(
        "The downloaded file is not a valid PDF. "
            "Check your Supabase file URL and bucket permissions.",
      );
    }

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    debugPrint(
      "PDF downloaded successfully: ${file.path}",
    );

    return file;
  }

final TimetableService timetableService =
TimetableService();

//------------------------------------
// Student
//------------------------------------

String studentName = "";

String year = "";

String department = "";

String section = "";

//------------------------------------
// Timetable
//------------------------------------

Map<String, dynamic>? timetable;

//------------------------------------
// Loading
//------------------------------------

bool isLoading = true;

bool isRefreshing = false;

//------------------------------------
// Init
//------------------------------------

@override
void initState() {
super.initState();

loadStudent();
}

//------------------------------------
// SnackBar
//------------------------------------

void showMessage(
String message, {
bool error = false,
}) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(message),
backgroundColor:
error ? Colors.red : Colors.green,
),
);
}

//------------------------------------
// Load Student
//------------------------------------

Future<void> loadStudent() async {
try {
final user =
FirebaseAuth.instance.currentUser;

if (user == null) {
throw Exception("User not logged in");
}

final query =
await FirebaseFirestore.instance
.collection("users")
.where(
"email",
isEqualTo: user.email,
)
.limit(1)
.get();

if (query.docs.isEmpty) {
throw Exception(
"Student profile not found");
}

final data = query.docs.first.data();

studentName =
data["name"] ?? "";

year =
data["year"] ?? "";

department =
data["department"] ?? "";

section =
data["section"] ?? "";
debugPrint("Student Year: $year");
debugPrint("Student Department: $department");
debugPrint("Student Section: $section");
debugPrint("Searching ID: ${year}_${department}_${section}");

await loadTimetable();

} catch (e) {

showMessage(
e.toString(),
error: true,
);

if (mounted) {
setState(() {
isLoading = false;
});
}
}
}
//------------------------------------
// Load Timetable
//------------------------------------

Future<void> loadTimetable() async {
try {
final data =
await timetableService.getTimetable(
year: year,
department: department,
section: section,
);

if (mounted) {
setState(() {
timetable = data;
isLoading = false;
});
}
} catch (e) {
showMessage(
e.toString(),
error: true,
);

if (mounted) {
setState(() {
isLoading = false;
});
}
}
}

//------------------------------------
// Refresh
//------------------------------------

Future<void> refreshPage() async {

if (mounted) {
setState(() {
isRefreshing = true;
});
}

await loadStudent();

if (mounted) {
setState(() {
isRefreshing = false;
});
}
}

//------------------------------------
// View Timetable
//------------------------------------

  Future<void> viewTimetable() async {
    if (timetable == null) {
      showMessage(
        "No timetable available",
        error: true,
      );
      return;
    }

    final url =
        timetable!["fileUrl"]?.toString() ?? "";
    debugPrint("TIMETABLE PDF URL:");
    debugPrint(url);

    if (url.isEmpty) {
      showMessage(
        "Timetable PDF URL is missing",
        error: true,
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final file = await _downloadPdfFile(url);

      if (!mounted) return;

      Navigator.of(context).pop();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TimetablePdfViewerPage(
            filePath: file.path,
            title: "Class Timetable",
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

        showMessage(
          "Unable to open PDF: $e",
          error: true,
        );
      }

      debugPrint(
        "VIEW PDF ERROR: $e",
      );
    }
  }

//------------------------------------
// Download Timetable
//------------------------------------

  Future<void> downloadTimetable() async {
    if (timetable == null) {
      showMessage(
        "No timetable available",
        error: true,
      );
      return;
    }

    final url =
        timetable!["fileUrl"]?.toString() ?? "";
    debugPrint("TIMETABLE PDF URL:");
    debugPrint(url);

    if (url.isEmpty) {
      showMessage(
        "Timetable PDF URL is missing",
        error: true,
      );
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final file = await _downloadPdfFile(url);

      if (!mounted) return;

      Navigator.of(context).pop();

      showModalBottomSheet(
        context: context,
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                    size: 50,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Timetable Downloaded",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    file.path,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(sheetContext);

                            await OpenFilex.open(
                              file.path,
                            );
                          },
                          icon: const Icon(
                            Icons.picture_as_pdf,
                          ),
                          label: const Text("Open"),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(sheetContext);

                            await SharePlus.instance
                                .share(
                              ShareParams(
                                files: [
                                  XFile(file.path),
                                ],
                                text:
                                "EduMate Class Timetable",
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.share,
                          ),
                          label: const Text("Save / Share"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

        showMessage(
          "Download failed: $e",
          error: true,
        );
      }

      debugPrint(
        "DOWNLOAD PDF ERROR: $e",
      );
    }
  }
//------------------------------------
// Build
//------------------------------------

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

centerTitle: true,

  backgroundColor: isDark
  ? const Color(0xFF0D47A1)
      : const Color(0xFF1565C0),

foregroundColor: Colors.white,

title: const Text(
"Class Timetable",
),
),

body: RefreshIndicator(

onRefresh: refreshPage,

child: isLoading

? const Center(
child: CircularProgressIndicator(),
)

: SingleChildScrollView(

physics:
const AlwaysScrollableScrollPhysics(),

padding:
const EdgeInsets.all(20),

child: Column(

crossAxisAlignment:
CrossAxisAlignment.start,

children: [

//----------------------------------
// Student Card
//----------------------------------

glassCard(
  isDark: isDark,

child: Padding(

padding:
const EdgeInsets.all(20),

child: Row(

children: [

const CircleAvatar(

radius: 35,

  backgroundColor: const Color(0xFF1565C0),

child: Icon(
Icons.person,
color: Colors.white,
size: 35,
),
),

const SizedBox(width: 18),

Expanded(

child: Column(

crossAxisAlignment:
CrossAxisAlignment.start,

children: [

Text(

studentName,

style:
const TextStyle(

fontSize: 22,

fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 8),

Text(
"Year : $year",
),

Text(
"Department : $department",
),

Text(
"Section : $section",
),
],
),
),
],
),
),
),

const SizedBox(height: 25),

//----------------------------------
// Empty State
//----------------------------------

if (timetable == null)

glassCard(
  isDark: isDark,

child: Padding(

padding:
const EdgeInsets.all(35),

child: Column(

children: const [

Icon(

Icons.calendar_month,

size: 90,

color: Colors.grey,
),

SizedBox(height: 20),

Text(

"No Timetable Uploaded Yet",

style: TextStyle(

fontSize: 22,

fontWeight:
FontWeight.bold,
),
),

SizedBox(height: 10),

Text(

"Please contact your teacher.",

textAlign:
TextAlign.center,
),
],
),
),
),

//----------------------------------
// Timetable Card
//----------------------------------

if (timetable != null)

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

color: Colors.red,

size: 45,
),

const SizedBox(width: 15),

Expanded(

child: Column(

crossAxisAlignment:
CrossAxisAlignment.start,

children: [

Text(

timetable!["title"],

style:
const TextStyle(

fontSize: 20,

fontWeight:
FontWeight.bold,
),
),

const SizedBox(height: 8),

Text(
"Uploaded By : ${timetable!["teacher"]}",
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
      timetable!["uploadedAt"];

      String uploadedDate =
          "Just Now";

      if (uploaded is Timestamp) {

        final date =
        uploaded.toDate();

        uploadedDate =
        "${date.day}/${date.month}/${date.year}";
      }

      return Text(
        "Uploaded : $uploadedDate",
        style: const TextStyle(
          color: Colors.grey,
        ),
      );
    },
  ),

  const SizedBox(height: 25),

  Row(

    children: [

      //---------------------------------
      // View
      //---------------------------------

      Expanded(

        child:
        ElevatedButton.icon(

          onPressed:
          viewTimetable,

          icon:
          const Icon(
            Icons.visibility,
          ),

          label:
          const Text(
            "View",
          ),

          style:
          ElevatedButton.styleFrom(

          backgroundColor: const Color(0xFF1976D2),

            foregroundColor:
            Colors.white,

            minimumSize:
            const Size(
                double.infinity,
                55),
          ),
        ),
      ),

      const SizedBox(width: 15),

      //---------------------------------
      // Download
      //---------------------------------

      Expanded(

        child:
        ElevatedButton.icon(

          onPressed:
          downloadTimetable,

          icon:
          const Icon(
            Icons.download,
          ),

          label:
          const Text(
            "Download",
          ),

          style:
          ElevatedButton.styleFrom(

          backgroundColor: const Color(0xFF1565C0),

            foregroundColor:
            Colors.white,

            minimumSize:
            const Size(
                double.infinity,
                55),
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
),
);
}

  //------------------------------------
  // Glass Card
  //------------------------------------

  Widget glassCard({
    required Widget child,
    required bool isDark,
  }) {

    return ClipRRect(

      borderRadius:
      BorderRadius.circular(24),

      child: BackdropFilter(

        filter: ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
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

                color: Colors.black
                    .withOpacity(0.08),

                blurRadius: 10,

                offset:
                const Offset(0, 10),
              ),
            ],
          ),

          child: child,
        ),
      ),
    );
  }
}
class TimetablePdfViewerPage extends StatefulWidget {
  final String filePath;
  final String title;

  const TimetablePdfViewerPage({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<TimetablePdfViewerPage> createState() =>
      _TimetablePdfViewerPageState();
}

class _TimetablePdfViewerPageState
    extends State<TimetablePdfViewerPage> {
  int currentPage = 0;
  int totalPages = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor:
        const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Open / Save PDF",
            onPressed: () async {
              await OpenFilex.open(
                widget.filePath,
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Share PDF",
            onPressed: () async {
              await SharePlus.instance.share(
                ShareParams(
                  files: [
                    XFile(widget.filePath),
                  ],
                  text: "EduMate Class Timetable",
                ),
              );
            },
          ),
        ],
      ),

      body: PDFView(
        filePath: widget.filePath,

        enableSwipe: true,
        swipeHorizontal: false,

        autoSpacing: true,
        pageFling: true,

        onRender: (pages) {
          if (!mounted) return;

          setState(() {
            totalPages = pages ?? 0;
          });
        },

        onViewCreated: (PDFViewController controller) {
          // PDF controller is created here.
        },

        onPageChanged: (page, total) {
          if (!mounted) return;

          setState(() {
            currentPage = page ?? 0;
            totalPages = total ?? 0;
          });
        },

        onError: (error) {
          debugPrint(
            "PDF VIEW ERROR: $error",
          );
        },

        onPageError: (page, error) {
          debugPrint(
            "PDF PAGE ERROR: page=$page error=$error",
          );
        },
      ),
    );
  }
}