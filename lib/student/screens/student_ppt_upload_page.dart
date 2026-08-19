import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// EduMate Student PPT Submission Page
///
/// Architecture:
/// - Firebase Auth  -> logged-in student identity
/// - Firestore      -> submission metadata
/// - Supabase       -> actual .ppt / .pptx file
///
/// Before using this page:
/// 1. Add file_picker and supabase_flutter to pubspec.yaml.
/// 2. Supabase must already be initialized in main.dart.
/// 3. Create a Supabase Storage bucket named "student-ppts".
/// 4. Keep the bucket public OR replace _uploadToSupabase() with your
///    authenticated/private upload flow.
/// 5. Make sure your teachers collection contains teacherUid/uid and an
///    identifiable teacher ID such as id/teacherId.
class StudentPptUploadPage extends StatefulWidget {
  const StudentPptUploadPage({super.key});

  @override
  State<StudentPptUploadPage> createState() => _StudentPptUploadPageState();
}

class _StudentPptUploadPageState extends State<StudentPptUploadPage> {
  // ---------------------------------------------------------------------------
  // SUPABASE CONFIGURATION
  // ---------------------------------------------------------------------------
  //
  // Replace these two values with your Supabase project values.
  //
  // Supabase URL:
  // https://YOUR_PROJECT_ID.supabase.co
  //
  // Supabase anon/public key:
  // Use the anon key from Supabase Project Settings -> API.
  //
  final TextEditingController _titleController = TextEditingController();

  List<QueryDocumentSnapshot<Map<String, dynamic>>> teachers = [];

  QueryDocumentSnapshot<Map<String, dynamic>>? selectedTeacher;

  PlatformFile? selectedFile;

  bool isLoadingTeachers = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD TEACHERS
  // ---------------------------------------------------------------------------

  Future<void> _loadTeachers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('teachers')
          .get();

      if (!mounted) return;

      final loadedTeachers = snapshot.docs.toList();

      loadedTeachers.sort((a, b) {
        final aName = _teacherName(a.data()).toLowerCase();
        final bName = _teacherName(b.data()).toLowerCase();
        return aName.compareTo(bName);
      });

      setState(() {
        teachers = loadedTeachers;
        isLoadingTeachers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingTeachers = false;
      });

      _showMessage(
        'Could not load teachers: $e',
        error: true,
      );
    }
  }

  String _teacherName(Map<String, dynamic> data) {
    return (data['name'] ??
        data['displayName'] ??
        data['teacherName'] ??
        'Teacher')
        .toString();
  }

  String _teacherId(
      QueryDocumentSnapshot<Map<String, dynamic>> teacher,
      ) {
    final data = teacher.data();

    return (data['teacherId'] ??
        data['id'] ??
        data['employeeId'] ??
        teacher.id)
        .toString();
  }

  String _teacherUid(
      QueryDocumentSnapshot<Map<String, dynamic>> teacher,
      ) {
    final data = teacher.data();

    return (data['teacherUid'] ??
        data['uid'] ??
        teacher.id)
        .toString();
  }

  String _teacherDepartment(
      QueryDocumentSnapshot<Map<String, dynamic>> teacher,
      ) {
    return (teacher.data()['department'] ?? '').toString();
  }

  // ---------------------------------------------------------------------------
  // SELECT PPT
  // ---------------------------------------------------------------------------

  Future<void> _pickPpt() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ppt', 'pptx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      if (file.size > 25 * 1024 * 1024) {
        _showMessage(
          'Please select a PPT smaller than 25 MB.',
          error: true,
        );
        return;
      }

      if (file.bytes == null || file.bytes!.isEmpty) {
        _showMessage(
          'Unable to read the selected PPT file.',
          error: true,
        );
        return;
      }

      setState(() {
        selectedFile = file;
      });
    } catch (e) {
      _showMessage(
        'Could not select the PPT: $e',
        error: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SUPABASE UPLOAD
  // ---------------------------------------------------------------------------

  Future<String> _uploadToSupabase({
    required PlatformFile file,
    required String studentUid,
  }) async {
    final bytes = file.bytes;

    if (bytes == null || bytes.isEmpty) {
      throw Exception('The selected PPT file could not be read.');
    }

    final supabase = Supabase.instance.client;

    final safeName = file.name.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final storagePath = '$studentUid/${timestamp}_$safeName';

    final extension = file.extension?.toLowerCase();

    final contentType = extension == 'ppt'
        ? 'application/vnd.ms-powerpoint'
        : 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

    await supabase.storage.from('student-ppts').uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: false,
      ),
    );

    // The bucket is currently public, so this URL can be stored in Firestore.
    return supabase.storage
        .from('student-ppts')
        .getPublicUrl(storagePath);
  }

  // ---------------------------------------------------------------------------
  // SUBMIT
  // ---------------------------------------------------------------------------

  Future<void> _submitPpt() async {
    if (isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please log in again before submitting your PPT.',
        error: true,
      );
      return;
    }

    final title = _titleController.text.trim();

    if (title.isEmpty) {
      _showMessage(
        'Enter a PPT title.',
        error: true,
      );
      return;
    }

    if (selectedTeacher == null) {
      _showMessage(
        'Select the teacher who should receive this PPT.',
        error: true,
      );
      return;
    }

    if (selectedFile == null || selectedFile!.bytes == null) {
      _showMessage(
        'Select a PPT file first.',
        error: true,
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Get the student's current Firestore profile.
      final studentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final studentData = studentDoc.data() ?? {};

      final studentName =
      (studentData['name'] ?? 'Student').toString();

      final rollNumber =
      (studentData['rollNumber'] ?? '').toString();

      final department =
      (studentData['department'] ?? '').toString();

      final year =
      (studentData['year'] ??
          studentData['academicYear'] ??
          '')
          .toString();

      final semester =
      (studentData['semester'] ?? '').toString();

      final section =
      (studentData['section'] ?? '').toString();

      final teacher = selectedTeacher!;

      // 1. Upload actual PPT to Supabase.
      final fileUrl = await _uploadToSupabase(
        file: selectedFile!,
        studentUid: user.uid,
      );

      // 2. Save metadata in Firestore.
      await FirebaseFirestore.instance
          .collection('ppt_submissions')
          .add({
        'studentUid': user.uid,
        'studentName': studentName,
        'rollNumber': rollNumber,
        'department': department,
        'year': year,
        'semester': semester,
        'section': section,

        'pptTitle': title,
        'fileName': selectedFile!.name,
        'fileUrl': fileUrl,
        'fileSize': selectedFile!.size,

        'teacherId': _teacherId(teacher),
        'teacherUid': _teacherUid(teacher),
        'teacherName': _teacherName(teacher.data()),
        'teacherDepartment': _teacherDepartment(teacher),

        'submittedAt': FieldValue.serverTimestamp(),
        'status': 'submitted',
      });

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
        selectedFile = null;
        selectedTeacher = null;
      });

      _titleController.clear();

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('PPT Submitted ✓'),
          content: const Text(
            'Your PPT has been submitted successfully. '
                'The selected teacher can now view your submission.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      _showMessage(
        'PPT submission failed: $e',
        error: true,
      );
    }
  }

  void _showMessage(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: const Text('Submit PPT'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerCard(isDark),
              const SizedBox(height: 18),

              _sectionTitle(
                'PPT Details',
                Icons.slideshow,
                isDark,
              ),
              const SizedBox(height: 10),

              _glassCard(
                isDark,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'PPT Title',
                        hintText:
                        'Example: AI and Machine Learning',
                        prefixIcon:
                        const Icon(Icons.title),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    _sectionTitle(
                      'Select Teacher',
                      Icons.person_search,
                      isDark,
                    ),
                    const SizedBox(height: 10),

                    if (isLoadingTeachers)
                      const Padding(
                        padding:
                        EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child:
                          CircularProgressIndicator(),
                        ),
                      )
                    else if (teachers.isEmpty)
                      Container(
                        padding:
                        const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:
                          Colors.orange.withOpacity(.10),
                          borderRadius:
                          BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'No teachers are available right now.',
                        ),
                      )
                    else
                      DropdownButtonFormField<
                          QueryDocumentSnapshot<Map<String, dynamic>>>(
                        value: selectedTeacher,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText:
                          'Teacher who should receive the PPT',
                          prefixIcon:
                          const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(15),
                          ),
                        ),
                        items: teachers.map((teacher) {
                          final name =
                          _teacherName(
                              teacher.data());
                          final id =
                          _teacherId(teacher);
                          final department =
                          _teacherDepartment(
                              teacher);

                          return DropdownMenuItem(
                            value: teacher,
                            child: Text(
                              department.isEmpty
                                  ? '$id — $name'
                                  : '$id — $name ($department)',
                              overflow:
                              TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: isSubmitting
                            ? null
                            : (teacher) {
                          setState(() {
                            selectedTeacher =
                                teacher;
                          });
                        },
                      ),

                    if (selectedTeacher != null) ...[
                      const SizedBox(height: 10),
                      _selectedTeacherCard(
                        selectedTeacher!,
                        isDark,
                      ),
                    ],

                    const SizedBox(height: 22),

                    _sectionTitle(
                      'PowerPoint File',
                      Icons.attach_file,
                      isDark,
                    ),
                    const SizedBox(height: 10),

                    _filePickerCard(isDark),

                    const SizedBox(height: 22),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed:
                        isSubmitting
                            ? null
                            : _submitPpt,
                        icon: isSubmitting
                            ? const SizedBox(
                          width: 21,
                          height: 21,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.cloud_upload,
                        ),
                        label: Text(
                          isSubmitting
                              ? 'Submitting...'
                              : 'Submit PPT',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF1565C0),
                          foregroundColor:
                          Colors.white,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _infoCard(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0),
            const Color(0xFF1976D2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.present_to_all,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Mid PPT Submission',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Submit your presentation to the selected teacher.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
      String title,
      IconData icon,
      bool isDark,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF1565C0),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color:
            isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _selectedTeacherCard(
      QueryDocumentSnapshot<Map<String, dynamic>>
      teacher,
      bool isDark,
      ) {
    final data = teacher.data();

    final name = _teacherName(teacher.data());
    final id = _teacherId(teacher);
    final department = _teacherDepartment(teacher);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.green.withOpacity(.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Selected: $id — $name'
                  '${department.isEmpty ? '' : ' • $department'}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filePickerCard(bool isDark) {
    if (selectedFile == null) {
      return InkWell(
        onTap: isSubmitting ? null : _pickPpt,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 25,
          ),
          decoration: BoxDecoration(
            color:
            isDark
                ? Colors.white.withOpacity(.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color:
              isDark
                  ? Colors.white24
                  : Colors.grey.shade300,
            ),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                size: 46,
                color: Color(0xFF1565C0),
              ),
              SizedBox(height: 10),
              Text(
                'Select PowerPoint',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '.ppt or .pptx • Maximum 25 MB',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blue.withOpacity(.20),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.red,
            child: Icon(
              Icons.slideshow,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  selectedFile!.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(selectedFile!.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isSubmitting
                ? null
                : () {
              setState(() {
                selectedFile = null;
              });
            },
            icon: const Icon(
              Icons.close,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
        isDark
            ? Colors.white.withOpacity(.05)
            : Colors.blue.withOpacity(.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Color(0xFF1565C0),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your PPT will be visible only to the teacher '
                  'you select. Please verify the teacher before '
                  'submitting.',
              style: TextStyle(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard(
      bool isDark, {
        required Widget child,
      }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:
        isDark
            ? Colors.white.withOpacity(.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color:
          isDark
              ? Colors.white12
              : Colors.grey.shade200,
        ),
      ),
      child: child,
    );
  }
}
