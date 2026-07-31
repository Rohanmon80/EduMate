import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';


import '../../main.dart';

class CertificateVaultPage extends StatefulWidget {
  const CertificateVaultPage({
    super.key,
  });

  @override
  State<CertificateVaultPage> createState() =>
      _CertificateVaultPageState();
}

class _CertificateVaultPageState
    extends State<CertificateVaultPage> {

  File? certificateFile;

  final TextEditingController titleController =
  TextEditingController();

  final TextEditingController organizationController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  final TextEditingController experienceController =
  TextEditingController();



  Future<void> addCertificate() async {

    if(

    certificateFile == null

        ||

        titleController.text
            .isEmpty

    ){

      return;
    }

    String fileName =

    DateTime.now()
        .millisecondsSinceEpoch
        .toString();

    final ref =

    FirebaseStorage
        .instance

        .ref()

        .child(
      "certificates/$fileName",
    );

    await ref.putFile(
      certificateFile!,
    );

    String url =

    await ref.getDownloadURL();

    await FirebaseFirestore
        .instance

        .collection(
      "certificates",
    )

        .add({

      "title":
      titleController.text,

      "organization":
      organizationController.text,

      "description":
      descriptionController.text,

      "experience":
      experienceController.text,

      "fileUrl":
      url,

      "studentId":

      FirebaseAuth
          .instance
          .currentUser!
          .uid,

      "likes":0,

      "date":
      Timestamp.now(),
    });

    Navigator.pop(
      context,
    );

    titleController.clear();

    organizationController.clear();

    descriptionController.clear();

    experienceController.clear();

    certificateFile = null;
  }

  void showAddDialog(bool isDark) {



    showDialog(

      context: context,

      builder: (_) {

        return AlertDialog(

          backgroundColor:
          isDark
              ? const Color(0xFF102038)
              : Colors.white,

          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(24),
          ),

          title: Text(
            "Add Certificate",

            style: TextStyle(
              color:
              isDark
                  ? Colors.white
                  : Colors.black,
            ),
          ),

          content: SingleChildScrollView(

            child: Column(

              children: [

                ElevatedButton.icon(

                  onPressed:() async {

                    final result =

                    await FilePicker
                        .platform
                        .pickFiles();

                    if(
                    result != null
                    ){

                      setState(() {

                        certificateFile =

                            File(

                              result.files
                                  .first.path!,
                            );
                      });
                    }
                  },

                  icon:
                  const Icon(
                    Icons.upload_file,
                  ),

                  label:
                  const Text(
                    "Upload Certificate",
                  ),
                ),

                const SizedBox(
                  height:14,
                ),



                buildField(
                  controller: titleController,
                  hint: "Certificate Title",
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                buildField(
                  controller:
                  organizationController,
                  hint: "Organization",
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                buildField(
                  controller:
                  descriptionController,
                  hint: "Description",
                  isDark: isDark,
                ),

                const SizedBox(height: 14),

                buildField(
                  controller:
                  experienceController,
                  hint: "Experience",
                  isDark: isDark,
                ),
              ],
            ),
          ),

          actions: [

            ElevatedButton(

              onPressed: addCertificate,

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF008CFF),
              ),

              child: const Text(
                "Add",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    final bool isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    return Scaffold(

      appBar: AppBar(

        backgroundColor: Colors.transparent,

        elevation: 0,

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed: () {

            Navigator.pop(context);
          },
        ),
      ),

      backgroundColor:
      isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      floatingActionButton:
      FloatingActionButton(

        backgroundColor:
        const Color(0xFF008CFF),

        onPressed: () {

          showAddDialog(isDark);
        },

        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      body: SafeArea(

        child: SingleChildScrollView(

          padding:
          const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              /// TOP BAR
              Row(
                mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,

                children: [

                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        "Certificate Vault",

                        style: TextStyle(
                          fontSize: 34,
                          fontWeight:
                          FontWeight.bold,

                          color:
                          isDark
                              ? Colors.white
                              : const Color(
                            0xFF0B1736,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "Store certificates & experience",

                        style: TextStyle(
                          fontSize: 16,

                          color:
                          isDark
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  glassIcon(
                    icon:
                    isDark
                        ? Icons.light_mode
                        : Icons.dark_mode,

                    onTap: () {

                      EduMateApp.of(
                        context,
                      )?.toggleTheme();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 35),

          StreamBuilder<QuerySnapshot>(

            stream:

            FirebaseFirestore
                .instance

                .collection(
              "certificates",
            )

                .snapshots(),

            builder:
                (
                context,
                snapshot,
                ){

              if(
              !snapshot.hasData
              ){

                return const Center(
                  child:
                  CircularProgressIndicator(),
                );
              }

              final certificates =

                  snapshot.data!.docs;

              return Column(

                children:

                certificates.map(

                      (cert){

                        final certificate =

                        cert.data()

                        as Map<
                            String,
                            dynamic>;

                        certificate["id"] =
                            cert.id;

                    return certificateCard(

                      isDark:isDark,

                      certificate:
                      certificate,
                    );
                  },
                )

                    .toList(),
              );
            },
          ),

            ],
          ),
        ),
      ),
    );
  }

  Widget certificateCard({
    required bool isDark,
    required Map<String, dynamic>
    certificate,
  }) {

    return Padding(
      padding:
      const EdgeInsets.only(bottom: 22),

      child: glassCard(

        isDark: isDark,

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                Container(
                  width: 72,
                  height: 72,

                  decoration: BoxDecoration(
                    color:
                    Colors.blue
                        .withOpacity(0.15),

                    borderRadius:
                    BorderRadius.circular(22),
                  ),

                  child: Icon(
                    Icons.workspace_premium,
                    color:
                    Colors.blue,
                    size: 42,
                  ),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(
                        certificate["title"],

                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                          FontWeight.bold,

                          color:
                          isDark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        certificate[
                        "organization"],

                        style: TextStyle(
                          color:
                          isDark
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              "Description",

              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                isDark
                    ? Colors.white
                    : Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              certificate["description"],

              style: TextStyle(
                color:
                isDark
                    ? Colors.white70
                    : Colors.grey,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              "Experience",

              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color:
                isDark
                    ? Colors.white
                    : Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              certificate["experience"],

              style: TextStyle(
                color:
                isDark
                    ? Colors.white70
                    : Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            Container(

              padding:
              const EdgeInsets.symmetric(
                horizontal:14,
                vertical:8,
              ),

              decoration: BoxDecoration(

                color:
                Colors.blue
                    .withOpacity(0.15),

                borderRadius:
                BorderRadius.circular(16),
              ),

              child: Text(

                (
                    certificate["date"]

                    as Timestamp
                )

                    .toDate()

                    .toString()

                    .substring(
                  0,
                  10,
                ),

                style:
                const TextStyle(

                  color:
                  Colors.blue,

                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
  }) {

    return TextField(

      controller: controller,

      style: TextStyle(
        color:
        isDark
            ? Colors.white
            : Colors.black,
      ),

      decoration: InputDecoration(

        hintText: hint,

        hintStyle: TextStyle(
          color:
          isDark
              ? Colors.white70
              : Colors.grey,
        ),

        filled: true,

        fillColor:
        isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.grey.withOpacity(0.1),

        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(16),

          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget glassCard({
    required bool isDark,
    required Widget child,
  }) {

    return ClipRRect(

      borderRadius:
      BorderRadius.circular(30),

      child: BackdropFilter(

        filter:
        ImageFilter.blur(
          sigmaX: 20,
          sigmaY: 20,
        ),

        child: Container(

          padding:
          const EdgeInsets.all(22),

          decoration: BoxDecoration(

            color:
            isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.35),

            borderRadius:
            BorderRadius.circular(30),

            border: Border.all(
              color:
              Colors.white.withOpacity(0.2),
            ),
          ),

          child: child,
        ),
      ),
    );
  }

  Widget glassIcon({
    required IconData icon,
    VoidCallback? onTap,
  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(
        width: 52,
        height: 52,

        decoration: BoxDecoration(

          color:
          Colors.white.withOpacity(0.12),

          borderRadius:
          BorderRadius.circular(18),

          border: Border.all(
            color: Colors.white24,
          ),
        ),

        child: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }
}