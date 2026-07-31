import 'dart:ui';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../main.dart';
import '../../role_selection_page.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final emailController = TextEditingController();

  final phoneController = TextEditingController();



  final bioController = TextEditingController();

  File? profileImage;

  @override
  void dispose() {
    emailController.dispose();
    phoneController.dispose();

    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF081120)
          : const Color(0xFFF4F8FC),

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("admins")
              .where(
            "email",
            isEqualTo: FirebaseAuth.instance.currentUser!.email,
          )
              .limit(1)
              .snapshots(),

          builder: (context, snapshot) {
            if (!snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final data = snapshot.data!.docs.first;

            final user =
            data.data() as Map<String, dynamic>;

            String name = user["name"] ?? "";

            final photoUrl =
            user.containsKey("photoUrl")
                ? user["photoUrl"] ?? ""
                : "";

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                children: [
                  /// TOP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Text(
                        "Profile",

                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,

                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),

                      Row(
                        children: [
                          glassIcon(
                            icon: isDark ? Icons.light_mode : Icons.dark_mode,

                            onTap: () {
                              EduMateApp.of(context)?.toggleTheme();
                            },
                          ),

                          const SizedBox(width: 12),

                          glassIcon(icon: Icons.notifications_none),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// PROFILE CARD
                  glassCard(
                    isDark: isDark,

                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue,

                          backgroundImage:
                          photoUrl.toString().isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,

                          child:
                          photoUrl.toString().isEmpty
                              ? Text(
                            (name.length >= 2
                                ? name.substring(0, 2)
                                : name)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              color: Colors.white,
                            ),
                          )
                              : null,
                        ),

                        const SizedBox(height: 18),

                        Text(
                          user["name"],

                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,

                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "${user["designation"] ?? "Administrator"}",

                          style: TextStyle(
                            fontSize: 16,

                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            badge("Top 10%", Colors.orange),

                            const SizedBox(width: 12),

                            badge("Streak 14d", Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),


                  const SizedBox(height: 25),

                  /// SETTINGS
                  glassCard(
                    isDark: isDark,

                    child: Column(
                      children: [
                        settingTile(
                          context,
                          isDark,
                          Icons.notifications_none,
                          "Notifications",
                        ),

                        divider(isDark),

                        settingTile(
                          context,
                          isDark,
                          Icons.dark_mode,
                          "Dark Mode",
                        ),

                        divider(isDark),

                        settingTile(
                          context,
                          isDark,
                          Icons.language,
                          "Language",
                        ),

                        divider(isDark),

                        settingTile(
                          context,
                          isDark,
                          Icons.lock_outline,
                          "Privacy & Security",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,

                    height: 60,

                    child: ElevatedButton.icon(
                      onPressed: () {
                        final user = data.data() as Map<String, dynamic>;

                        emailController.text = user.containsKey("email")
                            ? user["email"].toString()
                            : "";

                        phoneController.text = user.containsKey("phone")
                            ? user["phone"].toString()
                            : "";



                        bioController.text = user.containsKey("bio")
                            ? user["bio"].toString()
                            : "";

                        showEditProfile(
                          data,
                          photoUrl,
                        );
                      },

                      icon: const Icon(Icons.edit),

                      label: const Text("Edit Profile"),
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,

                    height: 60,

                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.12),
                      ),

                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();

                        Navigator.pushAndRemoveUntil(
                          context,

                          MaterialPageRoute(
                            builder: (_) => const RoleSelectionPage(),
                          ),

                              (route) => false,
                        );
                      },

                      icon: const Icon(Icons.logout, color: Colors.red),

                      label: const Text(
                        "Logout",

                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget profileField(
      TextEditingController controller,

      String hint,

      IconData icon,

      bool isDark,
      ) {
    return TextField(
      controller: controller,

      style: TextStyle(color: isDark ? Colors.white : Colors.black),

      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: Icon(icon),

        filled: true,

        fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),

          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void showEditProfile(
      DocumentSnapshot data,
      String photoUrl,
      ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,

      builder: (_) {
        return StatefulBuilder(
builder: (context, dialogSetState) {


        return Dialog(
          backgroundColor: Colors.transparent,

          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),

            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

              child: Container(
                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.white.withOpacity(0.45),

                  borderRadius: BorderRadius.circular(30),

                  border: Border.all(color: Colors.white24),
                ),

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      Container(
                        width: 95,

                        height: 95,

                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,

                          gradient: LinearGradient(
                            colors: [Color(0xFF008CFF), Color(0xFF00D4FF)],
                          ),
                        ),

                        child: profileImage != null
                            ? ClipOval(
                          child: Image.file(
                            profileImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                            : photoUrl.toString().isNotEmpty
                            ? ClipOval(
                          child: Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 45,
                        ),
                      ),

                      const SizedBox(height: 18),

                      ElevatedButton.icon(
                        onPressed: () async {
                          final result =
                          await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                          );
                          ;

                          if (result == null) return;

                          if (result.files.first.size > 5 * 1024 * 1024) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Maximum image size is 5 MB"),
                              ),
                            );
                            return;
                          }

                          dialogSetState(() {
                            profileImage = File(result.files.first.path!);
                          });
                        },

                        icon: const Icon(Icons.photo),

                        label: const Text("Choose Photo"),
                      ),

                      const SizedBox(height: 18),

                      TextField(
                        controller: emailController,
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: "Email",
                          prefixIcon: const Icon(Icons.email),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      profileField(
                        phoneController,

                        "Phone",

                        Icons.phone,

                        isDark,
                      ),

                      const SizedBox(height: 12),



                      TextField(
                        controller: bioController,

                        maxLines: 3,

                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),

                        decoration: InputDecoration(
                          hintText: "About yourself",

                          prefixIcon: const Icon(Icons.info),

                          filled: true,

                          fillColor: isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.white,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),

                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,

                        height: 55,

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008CFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: () async {
                            try {
                              String imageUrl = "";

                              if (profileImage != null) {
                                final supabase = Supabase.instance.client;

                                final fileName =
                                    "${FirebaseAuth.instance.currentUser!.uid}.jpg";

                                final bytes = await profileImage!.readAsBytes();

                                await supabase.storage
                                    .from("profile-images")
                                    .uploadBinary(
                                  fileName,
                                  bytes,
                                  fileOptions: const FileOptions(
                                    upsert: true,
                                  ),
                                )
                                    .timeout(
                                  const Duration(seconds: 60),
                                );

                                imageUrl = supabase.storage
                                    .from("profile-images")
                                    .getPublicUrl(fileName);
                              }

                              final Map<String, dynamic> updateData = {
                                "email": emailController.text,
                                "phone": phoneController.text,

                                "bio": bioController.text,
                              };

                              if (imageUrl.isNotEmpty) {
                                updateData["photoUrl"] = imageUrl;
                              }

                              final email =
                                  FirebaseAuth.instance.currentUser!.email;

                              final query =
                              await FirebaseFirestore.instance
                                  .collection("admins")
                                  .where("email", isEqualTo: email)
                                  .limit(1)
                                  .get();

                              if (query.docs.isEmpty) {
                                throw Exception("User document not found");
                              }
                              await query.docs.first.reference.update(updateData);

                              if (!mounted) return;

                              Navigator.pop(context);

                              setState(() {
                                profileImage = null;
                              });
                            } catch (e, stackTrace) {
                              debugPrint(e.toString());
                              debugPrint(stackTrace.toString());

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            "SAVE PROFILE",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
},
        );
      },
    );
  }

  // KEEP ALL OTHER METHODS BELOW SAME

  Widget settingTile(
      BuildContext context,
      bool isDark,
      IconData icon,
      String title,
      ) {
    return ListTile(
      onTap: () {
        /// DARK MODE
        if (title == "Dark Mode") {
          EduMateApp.of(context)?.toggleTheme();
        }
        /// LANGUAGE
        else if (title == "Language") {
          showModalBottomSheet(
            context: context,

            backgroundColor: isDark ? const Color(0xFF081120) : Colors.white,

            builder: (_) {
              return Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Text(
                      "Select Language",

                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,

                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 20),

                    languageTile(isDark, "English"),

                    languageTile(isDark, "Hindi"),

                    languageTile(isDark, "Telugu"),
                  ],
                ),
              );
            },
          );
        }
        /// NOTIFICATIONS
        else if (title == "Notifications") {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Notifications Opened")));
        }
        /// PRIVACY
        else if (title == "Privacy & Security") {
          showDialog(
            context: context,

            builder: (_) {
              return AlertDialog(
                title: const Text("Privacy & Security"),

                content: const Text("Security settings page here."),

                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },

                    child: const Text("Close"),
                  ),
                ],
              );
            },
          );
        }
      },

      leading: CircleAvatar(
        backgroundColor: Colors.blue.withOpacity(0.15),

        child: Icon(icon, color: Colors.blue),
      ),

      title: Text(
        title,

        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,

          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      trailing: Icon(
        Icons.arrow_forward_ios,

        color: isDark ? Colors.white70 : Colors.black54,

        size: 18,
      ),
    );
  }

  Widget languageTile(bool isDark, String language) {
    return ListTile(
      title: Text(
        language,

        style: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),

      onTap: () {},
    );
  }

  Widget divider(bool isDark) {
    return Divider(
      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
    );
  }

  Widget badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

      decoration: BoxDecoration(
        color: color.withOpacity(0.15),

        borderRadius: BorderRadius.circular(20),
      ),

      child: Text(
        text,

        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget statCard(bool isDark, String title, String value) {
    return glassCard(
      isDark: isDark,

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),

        child: Column(
          children: [
            Text(
              title,

              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),

            const SizedBox(height: 10),

            Text(
              value,

              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget glassCard({required Widget child, required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),

      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

        child: Container(
          width: double.infinity,

          padding: const EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,

            borderRadius: BorderRadius.circular(30),

            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12,
            ),
          ),

          child: child,
        ),
      ),
    );
  }

  Widget glassIcon({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 50,
        height: 50,

        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),

          shape: BoxShape.circle,
        ),

        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
