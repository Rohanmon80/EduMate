import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoStudentDetails extends StatefulWidget {
  const MemoStudentDetails({super.key});

  @override
  State<MemoStudentDetails> createState() => _MemoStudentDetailsState();
}

class _MemoStudentDetailsState extends State<MemoStudentDetails> {
  bool _uploading = false;

  // ------------------------------------------------------------
  // PHOTO UPLOAD — file goes to Supabase Storage, the resulting
  // public URL is written to the student's Firestore "users" doc
  // so the rest of the app (which already reads photoUrl from
  // Firestore) keeps working unchanged.
  // ------------------------------------------------------------
  Future<void> _pickAndUploadPhoto() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;

    final xFile = await picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null) return;

    setState(() => _uploading = true);

    try {
      final Uint8List bytes = await xFile.readAsBytes();
      final storage = Supabase.instance.client.storage.from('student-photos');

      // File name = uid, so re-uploading always overwrites the old photo.
      final path = '$uid.jpg';
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
      );

      final publicUrl = storage.getPublicUrl(path);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'photoUrl': publicUrl});
      // Nothing else to do — the FutureBuilder below re-reads the
      // doc on next build/refresh and will pick up the new URL.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Photo upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final student = snapshot.data!.data() as Map<String, dynamic>;
        final photoUrl = student["photoUrl"]?.toString();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _uploading ? null : _pickAndUploadPhoto,
              child: Container(
                width: 130,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                ),
                child: _uploading
                    ? const Center(child: CircularProgressIndicator())
                    : (photoUrl == null || photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 80)
                    : Image.network(photoUrl, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: Column(
                children: [
                  detailRow("Student Name", student["name"] ?? ""),
                  detailRow("Roll Number", student["rollNumber"] ?? ""),
                  detailRow("Department", student["department"] ?? ""),
                  detailRow("Semester", student["semester"].toString()),
                  detailRow("Year", student["year"] ?? ""),
                  detailRow("Section", student["section"] ?? ""),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Text(" : "),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}